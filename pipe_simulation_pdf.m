function pns = pipe_simulation_pdf()
global global_info
cfg = global_info.lifecycleConfig;
pns.PN_name = 'PipeLifecycle';
pns.set_of_Ps = {'pYardSpace1', 'pYardSpace2', 'pWasher', 'pRepairStation', ...
    'pRepairWorker1', 'pRepairWorker2', 'pRepairWorker3'};
pns.set_of_Ts = {};
pns.set_of_As = {};
pns.set_of_Ports = {};
for worker = 1:cfg.inspectorCount
    addPlace(sprintf('pInspector%d', worker));
end
for truck = 1:cfg.truckCount
    addPlace(sprintf('pTruck%d', truck));
end
for typeIndex = 1:numel(cfg.pipeTypes)
    pipeType = cfg.pipeTypes{typeIndex};
    for stage = {'Arrived', 'Wash', 'Inspect', 'Passed', 'Scrap', 'RepairDone', 'Reinspect'}
        addPlace(['p' stage{1} '_' pipeType]);
    end
    for yard = 1:2
        addPlace(sprintf('pRaw_%s_%d', pipeType, yard));
        addPlace(sprintf('pReady_%s_%d', pipeType, yard));
        for truck = 1:cfg.truckCount
            resource = sprintf('pTruck%d', truck);
            space = sprintf('pYardSpace%d', yard);
            addTask(sprintf('tStoreRaw_%s_%d_%d', pipeType, yard, truck), ...
                {['pArrived_' pipeType], space, resource}, ...
                {sprintf('pRaw_%s_%d', pipeType, yard), resource});
            addTask(sprintf('tFetchRaw_%s_%d_%d', pipeType, yard, truck), ...
                {sprintf('pRaw_%s_%d', pipeType, yard), resource}, ...
                {['pWash_' pipeType], space, resource});
            addTask(sprintf('tStoreReady_%s_%d_%d', pipeType, yard, truck), ...
                {['pPassed_' pipeType], space, resource}, ...
                {sprintf('pReady_%s_%d', pipeType, yard), resource});
        end
    end
    addTask(['tWash_' pipeType], {['pWash_' pipeType], 'pWasher'}, ...
        {['pInspect_' pipeType], 'pWasher'});
    for worker = 1:cfg.inspectorCount
        inspector = sprintf('pInspector%d', worker);
        for inspection = {'Inspect', 'Reinspect'}
            stage = inspection{1};
            decision = sprintf('p%sDecision_%s_%d', stage, pipeType, worker);
            addPlace(decision);
            addTask(sprintf('t%s_%s_%d', stage, pipeType, worker), ...
                {['p' stage '_' pipeType], inspector}, {decision});
            if strcmp(stage, 'Inspect')
                outputs = {['pPassed_' pipeType], ['pRepairQueue_' pipeType '_1'], ...
                    ['pRepairQueue_' pipeType '_2'], ['pRepairQueue_' pipeType '_3'], ['pScrap_' pipeType]};
                outcomes = 1:5;
            else
                outputs = {['pPassed_' pipeType], ['pScrap_' pipeType]};
                outcomes = [1, 5];
            end
            for outcome = 1:numel(outcomes)
                addTask(sprintf('tRoute%s_%s_%d_%d', stage, pipeType, worker, outcomes(outcome)), ...
                    {decision}, {outputs{outcome}, inspector});
            end
        end
    end
    for difficulty = 1:3
        queue = sprintf('pRepairQueue_%s_%d', pipeType, difficulty);
        bench = sprintf('pRepairBench_%s_%d', pipeType, difficulty);
        addPlace(queue);
        addPlace(bench);
        for truck = 1:cfg.truckCount
            resource = sprintf('pTruck%d', truck);
            addTask(sprintf('tToRepair_%s_%d_%d', pipeType, difficulty, truck), ...
                {queue, resource}, {bench, resource});
        end
        for level = difficulty:3
            resource = sprintf('pRepairWorker%d', level);
            addTask(sprintf('tRepair_%s_%d_%d', pipeType, difficulty, level), ...
                {bench, resource, 'pRepairStation'}, ...
                {['pRepairDone_' pipeType], resource, 'pRepairStation'});
        end
    end
    for truck = 1:cfg.truckCount
        resource = sprintf('pTruck%d', truck);
        addTask(sprintf('tFromRepair_%s_%d', pipeType, truck), ...
            {['pRepairDone_' pipeType], resource}, {['pReinspect_' pipeType], resource});
    end
end
for arrival = 1:height(cfg.arrivals)
    source = sprintf('pArrival%d', arrival);
    transition = sprintf('tArrival%d', arrival);
    addPlace(source);
    addTask(transition, {source}, {});
    pns.set_of_As = [pns.set_of_As, {transition, ...
        ['pArrived_' cfg.arrivals.Type{arrival}], cfg.arrivals.Quantity(arrival)}];
end
for order = 1:height(cfg.orders)
    source = sprintf('pOrder%d', order);
    demand = sprintf('pDemand%d', order);
    delivered = sprintf('pDelivered%d', order);
    transition = sprintf('tOrder%d', order);
    addPlace(source);
    addPlace(demand);
    addPlace(delivered);
    addTask(transition, {source}, {});
    pns.set_of_As = [pns.set_of_As, {transition, demand, cfg.orders.Quantity(order)}];
    for yard = 1:2
        for truck = 1:cfg.truckCount
            resource = sprintf('pTruck%d', truck);
            addTask(sprintf('tDispatch_%d_%d_%d', order, yard, truck), ...
                {demand, sprintf('pReady_%s_%d', cfg.orders.Type{order}, yard), resource}, ...
                {delivered, sprintf('pYardSpace%d', yard), resource});
        end
    end
end

    function addPlace(name)
        pns.set_of_Ps{end+1} = name;
    end

    function addTask(name, inputs, outputs)
        pns.set_of_Ts{end+1} = name;
        for inputIndex = 1:numel(inputs)
            pns.set_of_As = [pns.set_of_As, {inputs{inputIndex}, name, 1}];
        end
        for outputIndex = 1:numel(outputs)
            pns.set_of_As = [pns.set_of_As, {name, outputs{outputIndex}, 1}];
        end
    end
end