function [sim, orders, inventory, resources] = run_pipe_simulation(cfg, showPlots)
global global_info
global_info = struct();
if nargin < 1
    [dyn, cfg] = pipe_simulation_dynamics();
else
    [dyn, cfg] = pipe_simulation_dynamics(cfg);
end
if nargin < 2
    showPlots = true;
end
global_info.STOP_AT = cfg.stopMinutes;
global_info.MAX_LOOP = ceil(8*cfg.stopMinutes/cfg.stepMinutes) + 1000;
rng(cfg.seed, 'twister');
pns = pnstruct('pipe_simulation_pdf');
sim = gpensim(initialdynamics(pns, dyn));
placeNames = {sim.global_places.name};
marking = @(name) sum(sim.X(strcmp(placeNames, name)));
reserved = @(name) sum(sim.VX(strcmp(placeNames, name)));

orders = cfg.orders;
orders.Delivered = zeros(height(orders), 1);
orders.Outstanding = orders.Quantity;
orders.Status = repmat({'Waiting'}, height(orders), 1);
for order = 1:height(orders)
    orders.Delivered(order) = marking(sprintf('pDelivered%d', order));
    orders.Outstanding(order) = orders.Quantity(order) - orders.Delivered(order);
    if orders.Outstanding(order) == 0
        orders.Status{order} = 'Complete';
    elseif orders.Delivered(order) > 0
        orders.Status{order} = 'Partial';
    elseif marking(sprintf('pOrder%d', order)) + reserved(sprintf('pOrder%d', order)) > 0
        orders.Status{order} = 'Scheduled';
    end
    assert(orders.Delivered(order) <= orders.Quantity(order), 'Order over-delivered.');
end

typeCount = numel(cfg.pipeTypes);
inventory = table(cfg.pipeTypes(:), zeros(typeCount, 1), zeros(typeCount, 1), ...
    zeros(typeCount, 1), zeros(typeCount, 1), zeros(typeCount, 1), zeros(typeCount, 1), ...
    'VariableNames', {'Type', 'RawYard1', 'RawYard2', 'ReadyYard1', 'ReadyYard2', 'Scrap', 'Delivered'});
for typeIndex = 1:typeCount
    pipeType = cfg.pipeTypes{typeIndex};
    inventory.RawYard1(typeIndex) = marking(['pRaw_' pipeType '_1']);
    inventory.RawYard2(typeIndex) = marking(['pRaw_' pipeType '_2']);
    inventory.ReadyYard1(typeIndex) = marking(['pReady_' pipeType '_1']);
    inventory.ReadyYard2(typeIndex) = marking(['pReady_' pipeType '_2']);
    inventory.Scrap(typeIndex) = marking(['pScrap_' pipeType]);
    inventory.Delivered(typeIndex) = sum(orders.Delivered(strcmp(orders.Type, pipeType)));
    typedPlaces = ~cellfun(@isempty, regexp(placeNames, ['_' pipeType '(_|$)'], 'once'));
    pendingArrivals = 0;
    for arrival = find(strcmp(cfg.arrivals.Type, pipeType))'
        source = sprintf('pArrival%d', arrival);
        pendingArrivals = pendingArrivals + ...
            cfg.arrivals.Quantity(arrival)*(marking(source) + reserved(source));
    end
    expected = sum(cfg.arrivals.Quantity(strcmp(cfg.arrivals.Type, pipeType)));
    assert(sum(sim.X(typedPlaces) + sim.VX(typedPlaces)) + ...
        inventory.Delivered(typeIndex) + pendingArrivals == expected, ...
        ['Pipe conservation failed for ' pipeType]);
end

transitionNames = {sim.global_transitions.name};
inspecting = ~cellfun(@isempty, regexp(transitionNames, ...
    '^t(Inspect|Reinspect|RouteInspect|RouteReinspect)_', 'once'));
transporting = ~cellfun(@isempty, regexp(transitionNames, ...
    '^t(StoreRaw|FetchRaw|StoreReady|ToRepair|FromRepair|Dispatch)_', 'once'));
activity = sim.Firing_Trans_SET(:, 2:end);
peakInspectors = max(sum(activity(:, inspecting), 2));
peakTrucks = max(sum(activity(:, transporting), 2));
resources = table({'Inspectors'; 'Trucks'}, [cfg.inspectorCount; cfg.truckCount], ...
    [peakInspectors; peakTrucks], 'VariableNames', {'Resource', 'AvailableCount', 'PeakBusy'});
assert(peakInspectors <= cfg.inspectorCount && peakTrucks <= cfg.truckCount);
for worker = 1:cfg.inspectorCount
    resource = sprintf('pInspector%d', worker);
    assert(marking(resource) + reserved(resource) == 1, 'Inspector resource lost.');
end
for truck = 1:cfg.truckCount
    resource = sprintf('pTruck%d', truck);
    assert(marking(resource) + reserved(resource) == 1, 'Truck resource lost.');
end
for yard = 1:2
    space = sprintf('pYardSpace%d', yard);
    occupied = ~cellfun(@isempty, regexp(placeNames, ...
        sprintf('^p(Raw|Ready)_[A-Za-z0-9]+_%d$', yard), 'once'));
    assert(marking(space) + reserved(space) + sum(sim.X(occupied) + sim.VX(occupied)) == ...
        cfg.yardCapacity(yard), 'Yard capacity conservation failed.');
end

disp('Customer orders');
disp(orders);
disp('Inventory at simulation end (in-transit pipes are not included)');
disp(inventory);
disp('Resource concurrency');
disp(resources);
disp('Inspection outcomes by type: pass, minor, moderate, major, scrap');
disp(global_info.lifecycleInspectionCounts);
if showPlots
    rawPlaces = {};
    readyPlaces = {};
    deliveredPlaces = {};
    for typeIndex = 1:typeCount
        pipeType = cfg.pipeTypes{typeIndex};
        rawPlaces = [rawPlaces, {['pRaw_' pipeType '_1'], ['pRaw_' pipeType '_2']}];
        readyPlaces = [readyPlaces, {['pReady_' pipeType '_1'], ...
            ['pReady_' pipeType '_2'], ['pScrap_' pipeType]}];
    end
    for order = 1:height(orders)
        deliveredPlaces{end+1} = sprintf('pDelivered%d', order);
    end
    figure('Name', 'Dirty pipe storage');
    plotp(sim, rawPlaces);
    figure('Name', 'Inspected stock and scrap');
    plotp(sim, readyPlaces);
    if ~isempty(deliveredPlaces)
        figure('Name', 'Customer collections');
        plotp(sim, deliveredPlaces);
    end
end
end