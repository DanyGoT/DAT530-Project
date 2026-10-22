function [dyn, cfg] = pipe_simulation_dynamics(cfg)
global global_info

if nargin == 0
    cfg.pipeTypes = {'Drill', 'Tubing'};
    cfg.inspectorCount = 6;
    cfg.truckCount = 3;
    cfg.yardCapacity = [6, 20];
    cfg.yardTravelMinutes = [10, 25];
    cfg.loadMinutes = 2;
    cfg.unloadMinutes = 2;
    cfg.washMinutes = 2;
    cfg.inspectMinutes = 3;
    cfg.repairMinutes = [15, 60, 180];
    cfg.repairWorkers = [1, 1, 1];
    cfg.repairStations = 1;
    cfg.repairTravelMinutes = 5;
    cfg.inspectionProbabilities = [0.65, 0.20, 0.08, 0.04, 0.03];
    cfg.reinspectionScrapProbability = 0.05;
    cfg.stepMinutes = 1;
    cfg.stopMinutes = 1500;
    cfg.seed = 0;
    cfg.arrivals = table([0; 30], {'Drill'; 'Tubing'}, [8; 6], ...
        'VariableNames', {'Time', 'Type', 'Quantity'});
    cfg.orders = table({'C001'; 'C002'; 'C003'}, [180; 300; 400], ...
        {'Drill'; 'Tubing'; 'Drill'}, [4; 4; 3], ...
        'VariableNames', {'ID', 'Time', 'Type', 'Quantity'});
end

assert(~isempty(cfg.pipeTypes) && numel(unique(cfg.pipeTypes)) == numel(cfg.pipeTypes));
assert(all(~cellfun(@isempty, regexp(cfg.pipeTypes, '^[A-Za-z][A-Za-z0-9]*$', 'once'))), ...
    'Pipe types must start with a letter and contain only letters and digits.');
counts = [cfg.inspectorCount, cfg.truckCount, cfg.yardCapacity, ...
          cfg.repairWorkers, cfg.repairStations];
assert(all(isfinite(counts) & counts >= 0 & counts == floor(counts)));
assert(cfg.inspectorCount > 0 && cfg.truckCount > 0 && sum(cfg.yardCapacity) > 0);
assert(numel(cfg.yardCapacity) == 2 && numel(cfg.yardTravelMinutes) == 2);
assert(numel(cfg.repairWorkers) == 3 && numel(cfg.repairMinutes) == 3);
assert(all([cfg.yardTravelMinutes, cfg.loadMinutes, cfg.unloadMinutes, ...
    cfg.washMinutes, cfg.inspectMinutes, cfg.repairMinutes, cfg.repairTravelMinutes] > 0));
assert(cfg.stepMinutes > 0 && cfg.stopMinutes > 0);
assert(numel(cfg.inspectionProbabilities) == 5 && ...
    all(cfg.inspectionProbabilities >= 0) && ...
    abs(sum(cfg.inspectionProbabilities) - 1) < 1e-12);
assert(cfg.reinspectionScrapProbability >= 0 && cfg.reinspectionScrapProbability <= 1);
for schedule = {cfg.arrivals, cfg.orders}
    rows = schedule{1};
    assert(all(ismember(rows.Type, cfg.pipeTypes)), 'Unknown pipe type in schedule.');
    assert(all(rows.Time >= 0 & isfinite(rows.Time)));
    assert(all(rows.Quantity > 0 & rows.Quantity == floor(rows.Quantity)));
end
assert(numel(unique(cfg.orders.ID)) == height(cfg.orders), 'Order IDs must be unique.');

global_info.lifecycleConfig = cfg;
global_info.lifecycleOutcome = zeros(1, cfg.inspectorCount);
global_info.lifecycleInspectionCounts = zeros(numel(cfg.pipeTypes), 5);
global_info.lifecycleReinspectionCounts = zeros(numel(cfg.pipeTypes), 2);
dyn.m0 = {'pYardSpace1', cfg.yardCapacity(1), 'pYardSpace2', cfg.yardCapacity(2), ...
          'pWasher', 1, 'pRepairStation', cfg.repairStations};
dyn.ft = {'allothers', cfg.stepMinutes};
for worker = 1:cfg.inspectorCount
    dyn.m0 = [dyn.m0, {sprintf('pInspector%d', worker), 1}];
end
for truck = 1:cfg.truckCount
    dyn.m0 = [dyn.m0, {sprintf('pTruck%d', truck), 1}];
end
for level = 1:3
    dyn.m0 = [dyn.m0, {sprintf('pRepairWorker%d', level), cfg.repairWorkers(level)}];
end
for arrival = 1:height(cfg.arrivals)
    dyn.m0 = [dyn.m0, {sprintf('pArrival%d', arrival), 1}];
    dyn.ft = [dyn.ft, {sprintf('tArrival%d', arrival), ...
        max(cfg.stepMinutes, cfg.arrivals.Time(arrival))}];
end
for order = 1:height(cfg.orders)
    dyn.m0 = [dyn.m0, {sprintf('pOrder%d', order), 1}];
    dyn.ft = [dyn.ft, {sprintf('tOrder%d', order), ...
        max(cfg.stepMinutes, cfg.orders.Time(order))}];
end
for typeIndex = 1:numel(cfg.pipeTypes)
    pipeType = cfg.pipeTypes{typeIndex};
    dyn.ft = [dyn.ft, {['tWash_' pipeType], cfg.washMinutes}];
    for worker = 1:cfg.inspectorCount
        dyn.ft = [dyn.ft, {sprintf('tInspect_%s_%d', pipeType, worker), cfg.inspectMinutes, ...
            sprintf('tReinspect_%s_%d', pipeType, worker), cfg.inspectMinutes}];
    end
    for yard = 1:2
        tripMinutes = 2*cfg.yardTravelMinutes(yard) + cfg.loadMinutes + cfg.unloadMinutes;
        for truck = 1:cfg.truckCount
            for action = {'StoreRaw', 'FetchRaw', 'StoreReady'}
                dyn.ft = [dyn.ft, {sprintf('t%s_%s_%d_%d', action{1}, pipeType, yard, truck), tripMinutes}];
            end
        end
    end
    for difficulty = 1:3
        for level = difficulty:3
            dyn.ft = [dyn.ft, {sprintf('tRepair_%s_%d_%d', pipeType, difficulty, level), ...
                cfg.repairMinutes(difficulty)}];
        end
        for truck = 1:cfg.truckCount
            dyn.ft = [dyn.ft, {sprintf('tToRepair_%s_%d_%d', pipeType, difficulty, truck), ...
                cfg.repairTravelMinutes + cfg.loadMinutes + cfg.unloadMinutes}];
        end
    end
    for truck = 1:cfg.truckCount
        dyn.ft = [dyn.ft, {sprintf('tFromRepair_%s_%d', pipeType, truck), ...
            cfg.repairTravelMinutes + cfg.loadMinutes + cfg.unloadMinutes}];
    end
end
for order = 1:height(cfg.orders)
    for yard = 1:2
        for truck = 1:cfg.truckCount
            dyn.ft = [dyn.ft, {sprintf('tDispatch_%d_%d_%d', order, yard, truck), ...
                2*cfg.yardTravelMinutes(yard) + cfg.loadMinutes + cfg.unloadMinutes}];
        end
    end
end
end