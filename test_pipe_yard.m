function test_pipe_yard()
% Tests for the modular pipe yard simulation (Logistics / Operations / IT).
global global_info

% Crew selection: cheapest qualified workers first
assert(isequal(pipe_yard_pick_crew(1, 1, [1 1 1]), [1 0 0]));
assert(isequal(pipe_yard_pick_crew(2, 1, [1 0 3]), [1 0 1]));
assert(isequal(pipe_yard_pick_crew(1, 2, [5 0 1]), [0 0 1]));
assert(isempty(pipe_yard_pick_crew(1, 3, [5 5 0])));
assert(isequal(pipe_yard_crews(1, 3, [2 2 2]), [0 0 1]));
disp('PASS: crew selection respects trainee/junior/senior levels');

cfg = smallConfig();
[sim, report] = runQuiet(cfg);
checkConservation(sim, report, cfg);
assert(isequal(report.shipments.Pipes', [4, 2]), 'Expected a full and a partial shipment.');
activity = sim.Firing_Trans_SET(:, 2:end);
names = {sim.global_transitions.name};
inspecting = startsWith(names, 'tOStep');
assert(max(sum(activity(:, inspecting), 2)) > 1, 'Inspection never ran in parallel.');
assert(max(sum(activity(:, inspecting), 2)) <= cfg.inspection.stations);
unloading = startsWith(names, {'tLUnload', 'tLLoad'});
assert(max(sum(activity(:, unloading), 2)) == 1, 'Only one forklift exists.');
disp('PASS: all pipes delivered, resources released, partial last shipment');

cfg.scrapPercent = 100;
[sim, report] = runQuiet(cfg);
checkConservation(sim, report, cfg);
assert(report.summary.Value(5) == 6 && isempty(report.shipments.Pipes));
assert(global_info.taskCounts.tOStep1 == 6 && global_info.taskCounts.tOStep6 < 6, ...
    'Scrapped pipes should leave inspection before the last step.');
assert(global_info.taskCounts.tOStep6 == report.inspection.ScrappedHere(6));
disp('PASS: 100% scrap leaves inspection early and ships nothing');

for repair = {'easy', 'hard'}
    cfg = smallConfig();
    cfg.repair.(repair{1}).percent = 100;
    [sim, report] = runQuiet(cfg);
    checkConservation(sim, report, cfg);
    taskName = ['tORepair' upper(repair{1}(1)) repair{1}(2:end)];
    assert(global_info.taskCounts.(taskName) == 6, ['Not all pipes got ' repair{1} ' repair.']);
    fprintf('PASS: 100%% %s repair, then shipped\n', repair{1});
end

% Hard tasks must be done by seniors only; no scrap or repair
cfg = smallConfig();
cfg.inspection.steps.Difficulty(:) = {'hard'};
cfg.washing.difficulty = 'hard';
[sim, report] = runQuiet(cfg);
checkConservation(sim, report, cfg);
assert(all(report.workers.BusyMinutes(1:2) == 0), 'Non-seniors did hard work.');
disp('PASS: hard tasks are only done by seniors');

% Certified workers act as helpers when there are no other workers
cfg = smallConfig();
cfg.logistics.certifiedDrivers = 3;
cfg.logistics.otherWorkers = 0;
[sim, report] = runQuiet(cfg);
checkConservation(sim, report, cfg);
disp('PASS: crew of 3 certified drivers');

% Expected scrap/repair fractions over many pipes (statistical)
cfg = smallConfig();
cfg.incoming = table(0, 200, 'VariableNames', {'Time', 'Pipes'});
cfg.yardCapacity = 200;
cfg.washing.minutes = 0.5;
cfg.washing.bays = 6;
cfg.inspection.stations = 6;
cfg.inspection.steps.Minutes(:) = 0.5;
cfg.repair.easy.minutes = 0.5;
cfg.repair.hard.minutes = 0.5;
cfg.logistics.unloadMinutes = 0.5;
cfg.logistics.loadMinutes = 0.5;
cfg.logistics.shipmentSize = 200;
cfg.scrapPercent = 20;
cfg.repair.easy.percent = 30;
cfg.repair.hard.percent = 10;
[sim, report] = runQuiet(cfg);
checkConservation(sim, report, cfg);
fractions = report.summary.Value([5, 3, 4])' / 200;
assert(all(abs(fractions - [0.2, 0.3, 0.1]) < 0.08), 'Percentages are off: %s', mat2str(fractions));
disp('PASS: scrap / easy / hard percentages match the configuration');

% Invalid configurations are rejected
cfg = smallConfig();
cfg.logistics.certifiedDrivers = 0;
assertFails(cfg, 'no certified driver');
cfg = smallConfig();
cfg.scrapPercent = 60;
cfg.repair.easy.percent = 50;
assertFails(cfg, 'percentages above 100');
cfg = smallConfig();
cfg.workers.senior = 0;
assertFails(cfg, 'hard step without seniors');
disp('PASS: invalid configurations are rejected');
disp('All pipe yard tests passed.');
end

function cfg = smallConfig()
cfg = pipe_yard_config();
cfg.incoming = table([0; 10], [4; 2], 'VariableNames', {'Time', 'Pipes'});
cfg.yardCapacity = 3;
cfg.logistics.shipmentSize = 4;
cfg.logistics.customerTravelMinutes = 5;
cfg.washing.minutes = 2;
cfg.inspection.steps.Minutes(:) = 2;
cfg.repair.easy.minutes = 3;
cfg.repair.hard.minutes = 6;
cfg.scrapPercent = 0;
cfg.repair.easy.percent = 0;
cfg.repair.hard.percent = 0;
cfg.stopMinutes = 2000;
end

function [sim, report] = runQuiet(cfg)
[~, sim, report] = evalc('run_pipe_yard(cfg, false)');
end

function checkConservation(sim, report, cfg)
global global_info
assert(report.completed, 'Simulation did not finish all pipes.');
names = {sim.global_places.name};
marking = @(name) sim.X(strcmp(names, name));
total = sum(cfg.incoming.Pipes);
assert(marking('pLDelivered') + marking('pIScrapped') == total, 'Pipes were lost.');
assert(sum(report.shipments.Pipes) == marking('pLDelivered'));
assert(sum(report.inspection.ScrappedHere) == marking('pIScrapped'));
resources = {'pLForklift', cfg.logistics.forklifts; 'pLCertified', cfg.logistics.certifiedDrivers; ...
    'pLHelpers', cfg.logistics.otherWorkers; 'pLYardSpace', cfg.yardCapacity; ...
    'pOTrainee', cfg.workers.trainee; 'pOJunior', cfg.workers.junior; ...
    'pOSenior', cfg.workers.senior; 'pOWashBay', cfg.washing.bays; ...
    'pOInspStation', cfg.inspection.stations; 'pORepairStation', cfg.repair.stations};
for i = 1:size(resources, 1)
    assert(marking(resources{i, 1}) == resources{i, 2}, 'Not released: %s', resources{i, 1});
end
assert(sum(sim.VX) <= 1, 'Pipes still inside transitions.');  % truck may be returning
assert(all(cellfun(@isempty, global_info.pendingDecision)), 'Unused routing decision.');
end

function assertFails(cfg, label)
failed = false;
try
    runQuiet(cfg);
catch
    failed = true;
end
assert(failed, 'Expected failure: %s', label);
end
