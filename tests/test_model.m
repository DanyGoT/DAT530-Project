% The whole model for 3 days, with repairs of half a day and a day so that
% repaired joints come back. Checks that no joint is lost between stock,
% shipping and the workshops.

clear all; clc;
global global_info

P = params();
P.days = 3;
P.repair_days = [0.5 1];
model_init(P);
pns = pnstruct({'arrival_pdf', 'yard_pdf', 'wash_pdf', 'inspection_pdf', ...
                'repair_pdf', 'departure_pdf', ...
                'imc_arrival_yard', 'imc_yard_wash', 'imc_wash_inspection', ...
                'imc_inspection_yard', 'imc_inspection_repair', 'imc_yard_departure'});
pni = initialdynamics(pns, model_dyn(P, pns));
Sim_Results = gpensim(pni);

pipes = global_info.pipes;
bypass = sum(strcmp({pipes.route}, 'bypass'));
assert(ntokens('pYReady') == P.stock + bypass + timesfired('tIOk') - timesfired('tDShip'), ...
       'stock does not add up');
assert(ntokens('pDDemand') + timesfired('tDShip') == global_info.next_demand - 1, ...
       'demand does not add up');
assert(timesfired('tRMach') > 0, 'no joint came back from machining');
assert(ntokens('pRMach') + timesfired('tRMach') == timesfired('tIMach'), 'machining lost joints');
assert(ntokens('pRHb')   + timesfired('tRHb')   == timesfired('tIHb'),   'hardbanding lost joints');
disp(['test_model: ok (', int2str(timesfired('tRMach') + timesfired('tRHb')), ' repaired, ', ...
      int2str(timesfired('tDShip')), ' shipped)']);
