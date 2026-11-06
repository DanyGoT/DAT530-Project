% Yard and Washing, Monday only, with credits for 60 joints. The wash washes
% them in arrival order, each with a worker from P.wash_crew.

clear all; clc;
global global_info

P = params();
P.seed = 4;
P.days = 1;
P.hall_buffer = 60;
model_init(P);
pns = pnstruct({'yard_pdf', 'wash_pdf', 'imc_yard_wash', 'stub_wash'});
assert_no_sources(pns);
pni = initialdynamics(pns, model_dyn(P, pns));
Sim_Results = gpensim(pni);

n = P.hall_buffer;
lanes = arrayfun(@(k) sprintf('tWash_%d', k), 1:P.wash_lanes, 'UniformOutput', false);
washed = sum(cellfun(@timesfired, lanes));

% Every joint sent is washed, in order, and keeps its length.
assert(ntokens('pWI') == n, 'not every joint sent was washed');
assert(washed == n, 'washed joints do not add up');
bank = get_place('pWI').token_bank;
orders = arrayfun(@(tok) order_of(tok.color), bank);
lens = arrayfun(@(tok) find(ismember({'long', 'short'}, tok.color)), bank);
assert(isequal(orders, [global_info.hall(1:n).order]), 'joints washed out of order');
assert(isequal(lens, 1 + strcmp({global_info.hall(1:n).len}, 'short')), 'joints lost their length');

% Someone manned the wash: the crew worked at least the wash's minutes.
[~, RU] = prnschedule(Sim_Results);
manned = sum(RU(:, 2));            % the wash, and the yard's forklift work
assert(manned >= washed * P.wash_min, 'nobody manned the wash');

disp(['test_wash: ok (', int2str(washed), ' washed, manned ', ...
      num2str(washed * P.wash_min / 60, 2), ' h)']);
