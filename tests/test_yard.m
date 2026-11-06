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

fired = @(ts) sum(cellfun(@timesfired, ts));
pipes = global_info.pipes;
b = global_info.backlog;              % the queue at the start
long = strcmp({b.len}, 'long');
coop = [b.coop];

% Every joint is unloaded at the right yard.
assert(numel(pipes) > 0, 'no joints arrived');
assert(any([pipes.coop]) && any(not([pipes.coop])), 'this seed should unload at both yards');
assert(global_info.next_pipe - 1 == numel(pipes), 'not every joint was handed over');
for k = {'Long', 'Short', 'Bypass', 'CHall', 'CBypass'}
    assert(timesfired(['tA', k{1}]) == timesfired(['tYIn', k{1}]) + ntokens(['pAY', k{1}]), ...
           [k{1}, ' joints lost between arrival and yard']);
end
coop0 = round(P.stock * P.coop_ready);
assert(ntokens('pYReady') == P.stock - coop0 + timesfired('tYInBypass'), ...
       'bypass joints missing from Main stock');
assert(ntokens('pCReady') == coop0 + timesfired('tYInCBypass'), ...
       'bypass joints missing from Coop stock');

% Coop bundles are fetched to Main by lorry.
fetched = fired({'tYFromCoopLong', 'tYFromCoopShort'});
assert(ntokens('pCHall') + timesfired('tYFetch') == timesfired('tYInCHall') + sum(coop), ...
       'joints lost at Coop');
assert(timesfired('tYFetch') > 0, 'nothing was fetched from Coop');
assert(timesfired('tYFetch') == fetched + ntokens('pYToMain'), 'joints lost on the lorry from Coop');
assert(ntokens('pYToMain') == size(global_info.lorry, 1), 'the lorry list is out of step');

% No hall joint is lost in the yard, and no forklift doubled.
in_long  = timesfired('tYInLong')  + timesfired('tYFromCoopLong')  + sum(long & not(coop));
in_short = timesfired('tYInShort') + timesfired('tYFromCoopShort') + sum(not(long) & not(coop));
assert(ntokens('pYLong') + timesfired('tYLong') == in_long, 'long joints lost');
assert(ntokens('pYShort') + timesfired('tYShort') == in_short, 'short joints lost');
assert(ntokens('pYFork') + ntokens('pCFork') <= P.forklifts && global_info.forks_coop <= 1, ...
       'forklifts doubled');

% One joint to the wash per credit, in list order.
sent = fired({'tYLong', 'tYShort'});
assert(sent == P.hall_buffer && ntokens('pYW') == sent && ntokens('pYRoom') == 0, ...
       'the yard did not send exactly one joint per credit');
assert(global_info.next_hall - 1 == sent, 'yard out of step with its list');
h = global_info.hall(1:sent);
assert(all(not([h.coop]) | global_info.cstate([h.id]) == 3), ...
       'a Coop joint went to the wash without being fetched');
orders = arrayfun(@(tok) order_of(tok.color), get_place('pYW').token_bank);
assert(isequal(orders, [h.order]), 'joints left the yard out of order');
for len = {'long', 'short'}
    a = listed(strcmp({listed.len}, len{1}));
    c = global_info.hall(strcmp({global_info.hall.len}, len{1}));
    assert(isequal([a.order], [c.order]), [len{1}, ' orders out of arrival order']);
end

% The yards are colourless.
for p = {'pYLong', 'pYShort', 'pYReady', 'pCHall', 'pCReady', 'pYToMain'}
    bank = get_place(p{1}).token_bank;
    assert(isempty(bank) || all(cellfun(@isempty, {bank.color})), [p{1}, ' has coloured tokens']);
end

disp(['test_yard: ok (', int2str(numel(pipes)), ' joints arrived, ', int2str(sum([pipes.coop])), ...
      ' at Coop, ', int2str(fetched), ' fetched from Coop, ', int2str(sent), ' sent to the wash, ', ...
      int2str(timesfired('tYForkToCoop')), ' forklift trips to Coop)']);
