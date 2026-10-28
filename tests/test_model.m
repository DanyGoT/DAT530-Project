% The whole model for 3 days, with repairs of half a day and a day so that
% repaired joints come back, half of them through the hall. Checks that no
% joint is lost between stock, shipping and the workshops.

clear all; clc;
global global_info

P = params();
P.seed = 4;                     % a seed with arrivals from Monday
P.days = 3;
P.repair_median = [0.5 1];
P.p_reinspect = [0.5 0.5];
model_init(P);
pns = pnstruct({'arrival_pdf', 'yard_pdf', 'wash_pdf', 'inspection_pdf', ...
                'repair_pdf', 'departure_pdf', ...
                'imc_arrival_yard', 'imc_yard_wash', 'imc_wash_inspection', ...
                'imc_inspection_yard', 'imc_inspection_repair', 'imc_repair_yard', ...
                'imc_yard_departure'});
pni = initialdynamics(pns, model_dyn(P, pns));
Sim_Results = gpensim(pni);

pipes = global_info.pipes;
bypass = sum(strcmp({pipes.route}, 'bypass'));
ready = timesfired('tRMachReady') + timesfired('tRHbReady');
assert(ntokens('pYReady') == P.stock + bypass + timesfired('tIOk') + ready - timesfired('tDShip'), ...
       'stock does not add up');
assert(ntokens('pDDemand') + timesfired('tDShip') == global_info.next_demand - 1, ...
       'demand does not add up');
assert(timesfired('tRMachHall') > 0 && timesfired('tRMachReady') > 0, ...
       'machined joints did not come back both ways');
assert(ntokens('pRMach') + timesfired('tRMachHall') + timesfired('tRMachReady') == timesfired('tIMach'), ...
       'machining lost joints');
assert(ntokens('pRHb') + timesfired('tRHbHall') + timesfired('tRHbReady') == timesfired('tIHb'), ...
       'hardbanding lost joints');
assert(size(global_info.workshop{1}, 1) == ntokens('pRMach') && ...
       size(global_info.workshop{2}, 1) == ntokens('pRHb'), 'workshop rows out of step with joints');
hall = timesfired('tRMachHall') + timesfired('tRHbHall');
disp(['test_model: ok (', int2str(hall + ready), ' repaired, ', int2str(hall), ' inspected again, ', ...
      int2str(timesfired('tDShip')), ' shipped)']);
