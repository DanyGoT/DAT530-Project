% Arrival and Yard on their own, 2 days. Every joint is unloaded at the right
% yard; Coop bundles are fetched to Main by lorry; the yard sends hall joints
% to the wash in list order, the queue at the start first, and no more than
% it has credits for. Short runs may move short orders forward, but each
% length keeps its own order. Forklifts are never lost or doubled.

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
b = global_info.backlog;
long = strcmp({b.len}, 'long');
coop = [b.coop];
assert(numel(pipes) > 0, 'no joints arrived');
assert(any([pipes.coop]) && any(not([pipes.coop])), 'this seed should unload at both yards');
assert(global_info.next_pipe - 1 == numel(pipes), 'not every joint was handed over');
for kind = {'Long', 'Short', 'Bypass', 'CHall', 'CBypass'}
    k = kind{1};
    assert(timesfired(['tA', k]) == timesfired(['tYIn', k]) + ntokens(['pAY', k]), ...
           [k, ' joints lost between arrival and yard']);
end
stock_coop = round(P.stock * P.coop_ready);
assert(ntokens('pYReady') == P.stock - stock_coop + timesfired('tYInBypass'), 'bypass joints missing from Main stock');
assert(ntokens('pCReady') == stock_coop + timesfired('tYInCBypass'), 'bypass joints missing from Coop stock');
assert(ntokens('pCHall') + timesfired('tYFetch') == timesfired('tYInCHall') + sum(coop), 'joints lost at Coop');
fetched = timesfired('tYFromCoopLong') + timesfired('tYFromCoopShort');
assert(timesfired('tYFetch') > 0, 'nothing was fetched from Coop');
assert(timesfired('tYFetch') == fetched + ntokens('pYToMain') && ntokens('pYToMain') == size(global_info.lorry, 1), ...
       'joints lost on the lorry from Coop');
assert(ntokens('pYLong') + timesfired('tYLong') == ...
       timesfired('tYInLong') + timesfired('tYFromCoopLong') + sum(long & not(coop)), 'long joints lost');
assert(ntokens('pYShort') + timesfired('tYShort') == ...
       timesfired('tYInShort') + timesfired('tYFromCoopShort') + sum(not(long) & not(coop)), 'short joints lost');
assert(ntokens('pYFork') + ntokens('pCFork') <= P.forklifts && global_info.forks_coop <= 1, 'forklifts doubled');

sent = timesfired('tYLong') + timesfired('tYShort');
assert(sent == P.hall_buffer && ntokens('pYW') == sent && ntokens('pYRoom') == 0, ...
       'the yard did not send exactly one joint per credit');
assert(global_info.next_hall - 1 == sent, 'yard out of step with its list');
h = global_info.hall(1:sent);
assert(all(not([h.coop]) | global_info.cstate([h.id]) == 3), 'a Coop joint went to the wash without being fetched');
bank = get_place('pYW').token_bank;
orders = arrayfun(@(tok) order_of(tok.color), bank);
assert(isequal(orders, [h.order]), 'joints left the yard out of order');
for len = {'long', 'short'}
    a = listed(strcmp({listed.len}, len{1}));
    c = global_info.hall(strcmp({global_info.hall.len}, len{1}));
    assert(isequal([a.order], [c.order]), [len{1}, ' orders out of arrival order']);
end
for p = {'pYLong', 'pYShort', 'pYReady', 'pCHall', 'pCReady', 'pYToMain'}
    bank = get_place(p{1}).token_bank;
    assert(isempty(bank) || all(cellfun(@isempty, {bank.color})), [p{1}, ' has coloured tokens']);
end
disp(['test_yard: ok (', int2str(numel(pipes)), ' joints arrived, ', int2str(sum([pipes.coop])), ...
      ' at Coop, ', int2str(fetched), ' fetched from Coop, ', int2str(sent), ' sent to the wash, ', ...
      int2str(timesfired('tYForkToCoop')), ' forklift trips to Coop)']);
