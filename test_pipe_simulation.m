function test_pipe_simulation()
global global_info
[~, cfg] = pipe_simulation_dynamics();
cfg.arrivals = table([0; 0], {'Drill'; 'Tubing'}, [3; 2], ...
    'VariableNames', {'Time', 'Type', 'Quantity'});
cfg.orders = table({'A'; 'B'}, [1; 1], {'Drill'; 'Tubing'}, [2; 3], ...
    'VariableNames', {'ID', 'Time', 'Type', 'Quantity'});
cfg.yardCapacity = [2, 10];
cfg.inspectionProbabilities = [1, 0, 0, 0, 0];
cfg.reinspectionScrapProbability = 0;
cfg.stopMinutes = 800;
[~, sim, orders, inventory, resources] = evalc('run_pipe_simulation(cfg, false)');
assert(isequal(orders.Delivered, [2; 2]), 'Wrong type or quantity delivered.');
assert(isequal(orders.Outstanding, [0; 1]), 'Shortage was not preserved.');
assert(sum(inventory.ReadyYard1 + inventory.ReadyYard2) == 1);
assert(all(resources.PeakBusy <= resources.AvailableCount));
assert(sum(sim.VX) == 0);
disp('PASS: type matching, partial orders, yard overflow and resource limits');

cfg.inspectionProbabilities = [0, 0, 0, 0, 1];
[~, sim, orders, inventory] = evalc('run_pipe_simulation(cfg, false)');
assert(all(orders.Delivered == 0) && sum(inventory.Scrap) == 5);
assert(sum(sim.VX) == 0);
disp('PASS: scrap never fulfills customer orders');

cfg.arrivals.Quantity = [1; 1];
cfg.orders.Quantity = [1; 1];
cfg.repairWorkers = [0, 0, 1];
for difficulty = 1:3
    cfg.inspectionProbabilities = zeros(1, 5);
    cfg.inspectionProbabilities(difficulty + 1) = 1;
    [~, sim, orders, inventory] = evalc('run_pipe_simulation(cfg, false)');
    assert(all(orders.Delivered == 1) && sum(inventory.Scrap) == 0);
    assert(sum(global_info.lifecycleReinspectionCounts(:)) == 2);
    assert(sum(sim.VX) == 0);
    fprintf('PASS: difficulty %d repair, qualified fallback and reinspection\n', difficulty);
end

cfg.reinspectionScrapProbability = 1;
[~, ~, orders, inventory] = evalc('run_pipe_simulation(cfg, false)');
assert(all(orders.Delivered == 0) && sum(inventory.Scrap) == 2);
disp('PASS: failed reinspection moves pipes to scrap');

global_info = struct();
cfg.arrivals = cfg.arrivals([],:);
cfg.orders = cfg.orders([],:);
cfg.inspectionProbabilities = [0.5, 0.2, 0.1, 0.1, 0.1];
cfg.reinspectionScrapProbability = 0;
[dyn, cfg] = pipe_simulation_dynamics(cfg);
global_info.STOP_AT = 15;
global_info.MAX_LOOP = 1000;
dyn.m0 = [dyn.m0, {'pInspect_Drill', 6}];
rng(cfg.seed, 'twister');
sim = gpensim(initialdynamics(pnstruct('pipe_simulation_pdf'), dyn));
transitionNames = {sim.global_transitions.name};
inspectors = ~cellfun(@isempty, regexp(transitionNames, '^tInspect_', 'once'));
activity = sim.Firing_Trans_SET(:, 2:end);
assert(max(sum(activity(:, inspectors), 2)) == 6, 'Six inspectors did not run concurrently.');
assert(sum(global_info.lifecycleInspectionCounts(:)) == 6);
placeNames = {sim.global_places.name};
decisions = startsWith(placeNames, 'pInspectDecision_');
assert(sum(sim.X(decisions) + sim.VX(decisions)) == 0, 'Inspection outcomes were not routed.');
disp('PASS: six concurrent inspectors preserve independent random outcomes');
disp('All lifecycle tests passed.');
end