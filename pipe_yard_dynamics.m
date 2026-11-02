function dyn = pipe_yard_dynamics(cfg, pns)
% Initial marking (resources, arrivals) and firing times for every transition.
logistics = cfg.logistics;

dyn.m0 = {'pLForklift', logistics.forklifts, ...
          'pLCertified', logistics.certifiedDrivers, ...
          'pLHelpers', logistics.otherWorkers, ...
          'pLYardSpace', cfg.yardCapacity, ...
          'pLTruckDocked', 1, 'pLTruckSpace', logistics.shipmentSize, ...
          'pOTrainee', cfg.workers.trainee, 'pOJunior', cfg.workers.junior, ...
          'pOSenior', cfg.workers.senior, 'pOWashBay', cfg.washing.bays, ...
          'pOInspStation', cfg.inspection.stations, 'pORepairStation', cfg.repair.stations};
for truck = 1:height(cfg.incoming)
    dyn.m0 = [dyn.m0, {sprintf('pIArrivalNotice%d', truck), 1}];
end

dyn.ft = {};
names = {pns.global_transitions.name};
for i = 1:numel(names)
    dyn.ft = [dyn.ft, {names{i}, firingTime(names{i})}];
end

    function minutes = firingTime(name)
        task = regexp(name, '^(t[A-Za-z]+\d*)', 'tokens', 'once');
        task = task{1};
        step = regexp(task, '^tOStep(\d+)$', 'tokens', 'once');
        arrival = regexp(task, '^tIArrival(\d+)$', 'tokens', 'once');
        if ~isempty(step)
            minutes = cfg.inspection.steps.Minutes(str2double(step{1}));
        elseif ~isempty(arrival)
            minutes = max(cfg.tickMinutes, cfg.incoming.Time(str2double(arrival{1})));
        else
            switch task
                case 'tLUnload',     minutes = logistics.unloadMinutes;
                case 'tLLoad',       minutes = logistics.loadMinutes;
                case {'tLDepart', 'tLReturn'}, minutes = logistics.customerTravelMinutes;
                case 'tOWash',       minutes = cfg.washing.minutes;
                case 'tORepairEasy', minutes = cfg.repair.easy.minutes;
                case 'tORepairHard', minutes = cfg.repair.hard.minutes;
                otherwise
                    if startsWith(task, 'tI')
                        minutes = cfg.it.registerMinutes;
                    else
                        minutes = cfg.tickMinutes;  % routing, start inspection, deliver
                    end
            end
        end
    end
end
