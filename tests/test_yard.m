% Arrival and Yard on their own, 2 days. Every joint is unloaded into the
% right place; the yard sends hall joints to the wash in arrival order, the
% queue at the start first, and no more than it has credits for. Short runs
% may move short orders forward, but each length keeps its own order.

clear all; clc;
global global_info

P = params();
P.seed = 4;                     % a seed with arrivals from Monday
P.days = 2;
model_init(P);
listed = global_info.hall;
pns = pnstruct({'arrival_pdf', 'yard_pdf', 'imc_arrival_yard', 'stub_yard'});
assert_no_sources(pns);
pni = initialdynamics(pns, model_dyn(P, pns));
Sim_Results = gpensim(pni);

pipes = global_info.pipes;
queued = strcmp({global_info.backlog.len}, 'long');
assert(numel(pipes) > 0, 'no joints arrived');
assert(global_info.next_pipe - 1 == numel(pipes), 'not every joint was unloaded');
for kind = {'Long', 'Short', 'Bypass'}
    k = kind{1};
    assert(timesfired(['tA', k]) == timesfired(['tYIn', k]) + ntokens(['pAY', k]), ...
           [k, ' joints lost between arrival and yard']);
end
assert(ntokens('pYReady') == P.stock + timesfired('tYInBypass'), 'bypass joints missing from stock');
assert(ntokens('pYLong')  + timesfired('tYLong')  == timesfired('tYInLong')  + sum(queued),      'long joints lost');
assert(ntokens('pYShort') + timesfired('tYShort') == timesfired('tYInShort') + sum(not(queued)), 'short joints lost');

sent = timesfired('tYLong') + timesfired('tYShort');
assert(sent == P.hall_buffer && ntokens('pYW') == sent && ntokens('pYRoom') == 0, ...
       'the yard did not send exactly one joint per credit');
assert(global_info.next_hall - 1 == sent, 'yard out of step with its list');
bank = get_place('pYW').token_bank;
orders = arrayfun(@(tok) order_of(tok.color), bank);
assert(isequal(orders, [global_info.hall(1:sent).order]), 'joints left the yard out of order');
for len = {'long', 'short'}
    a = listed(strcmp({listed.len}, len{1}));
    b = global_info.hall(strcmp({global_info.hall.len}, len{1}));
    assert(isequal([a.order], [b.order]), [len{1}, ' orders out of arrival order']);
end
for p = {'pYLong', 'pYShort', 'pYReady'}
    b = get_place(p{1}).token_bank;
    assert(isempty(b) || all(cellfun(@isempty, {b.color})), [p{1}, ' has coloured tokens']);
end
disp(['test_yard: ok (', int2str(numel(pipes)), ' joints arrived, ', int2str(sent), ' sent to the wash)']);
