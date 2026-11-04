% The whole model for 3 days, with repairs of half a day and a day so that
% joints sent to the workshops come back, half of them through the hall.
% Checks that no joint is lost between the modules, in either yard's stock,
% on the lorries, in shipping or the workshops.

clear all; clc;
global global_info

P = params();
P.seed = 4;                     % a seed with arrivals from Monday
P.days = 3;
P.repair_median = [0.5 1];
P.p_reinspect = [0.5 0.5];
P.coop_ready = 0.5;             % half the orders to Coop, so its racks and lorries are used
model_init(P);
start = cellfun(@(q) size(q, 1), global_info.workshop);
pns = pnstruct(model_pdfs(P));
assert_no_sources(pns);
pni = initialdynamics(pns, model_dyn(P, pns));
Sim_Results = gpensim(pni);

% Every connector passes on what it gets: sent = received + still in its place.
links = {{'tALong'}, 'pAYLong', {'tYInLong'};  {'tABypass'}, 'pAYBypass', {'tYInBypass'}; ...
         {'tACHall'}, 'pAYCHall', {'tYInCHall'}; {'tACBypass'}, 'pAYCBypass', {'tYInCBypass'}; ...
         {'tIOk'}, 'pIYOk', {'tYInOk', 'tYInOkCoop'}; {'tIScrap'}, 'pIYScrap', {'tYInScrap'}; ...
         {'tIMach'}, 'pIRMach', {'tRInMach'};  {'tIHb'}, 'pIRHb', {'tRInHb'}; ...
         {'tDTicket'}, 'pDYOrder', {'tYOrder', 'tYOrderCoop'}; {'tYShip', 'tYShipCoop'}, 'pYDOut', {'tDShip'}; ...
         {'tIRoom'}, 'pIYRoom', {'tYRoom'}};
fired = @(ts) sum(cellfun(@timesfired, ts));
for k = 1:size(links, 1)
    assert(fired(links{k, 1}) == ntokens(links{k, 2}) + fired(links{k, 3}), ...
           ['joints lost in ', links{k, 2}]);
end
assert(timesfired('tRMachHall') + timesfired('tRHbHall') == ntokens('pRI') + timesfired('tIInRepair'), ...
       'joints lost in pRI');
assert(timesfired('tRMachReady') + timesfired('tRHbReady') == ntokens('pRYReady') + timesfired('tYInRepaired'), ...
       'joints lost in pRYReady');

stock_coop = round(P.stock * P.coop_ready);
assert(ntokens('pYReady') == P.stock - stock_coop + timesfired('tYInBypass') + timesfired('tYInOk') ...
       + timesfired('tYInRepaired') - timesfired('tYShip'), 'Main stock does not add up');
assert(ntokens('pCReady') == stock_coop + timesfired('tYInCBypass') + timesfired('tYStoreCoop') ...
       - timesfired('tYShipCoop'), 'Coop stock does not add up');
assert(timesfired('tYInOkCoop') == timesfired('tYStoreCoop') + ntokens('pYToCoop'), 'joints lost on the lorry to Coop');
assert(timesfired('tYStoreCoop') > 0 && timesfired('tYShipCoop') > 0, 'Coop never stored or shipped');
assert(timesfired('tDTicket') == global_info.next_demand - 1, 'demand does not add up');
assert(timesfired('tRMachHall') > 0 && timesfired('tRMachReady') > 0, ...
       'machined joints did not come back both ways');
assert(ntokens('pRMach') + timesfired('tRMachHall') + timesfired('tRMachReady') == start(1) + timesfired('tRInMach'), ...
       'machining lost joints');
assert(ntokens('pRHb') + timesfired('tRHbHall') + timesfired('tRHbReady') == start(2) + timesfired('tRInHb'), ...
       'hardbanding lost joints');
assert(size(global_info.workshop{1}, 1) == ntokens('pRMach') && ...
       size(global_info.workshop{2}, 1) == ntokens('pRHb'), 'workshop rows out of step with joints');
hall = timesfired('tRMachHall') + timesfired('tRHbHall');
ready = timesfired('tRMachReady') + timesfired('tRHbReady');
disp(['test_model: ok (', int2str(hall + ready), ' repaired, ', int2str(timesfired('tIInRepair')), ...
      ' inspected again, ', int2str(timesfired('tDShip')), ' shipped, ', int2str(timesfired('tYShipCoop')), ...
      ' of them from Coop)']);
