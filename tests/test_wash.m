% Yard and Washing, Monday only, with credits for 60 joints. The wash washes
% them in arrival order, someone from the crew mans it from mobilize to
% demobilize, and it is demobilized again by midnight.

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

assert(ntokens('pWI') == P.hall_buffer, 'not every joint sent was washed');
bank = get_place('pWI').token_bank;
orders = arrayfun(@(tok) order_of(tok.color), bank);
lens = arrayfun(@(tok) find(ismember({'long', 'short'}, tok.color)), bank);
assert(isequal(orders, [global_info.hall(1:P.hall_buffer).order]), 'joints washed out of order');
assert(isequal(lens, 1 + strcmp({global_info.hall(1:P.hall_buffer).len}, 'short')), 'joints lost their length');
assert(ntokens('pWOff') == 1 && timesfired('tWMobilize') == timesfired('tWDemobilize'), ...
       'the unit is still mobilized at midnight');
assert(timesfired('tWMobilize') > 0, 'the unit was never mobilized');

[~, RU] = prnschedule(Sim_Results);
manned = sum(RU(:, 2));            % only the wash uses workers here
assert(manned >= timesfired('tWMobilize')*(P.mobilize + P.demobilize), 'nobody manned the wash');
disp(['test_wash: ok (', int2str(P.hall_buffer), ' washed, mobilized ', int2str(timesfired('tWMobilize')), ...
      ' times, manned ', num2str(manned/60, 2), ' h)']);
