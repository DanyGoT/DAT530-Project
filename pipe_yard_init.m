function pipe_yard_init(cfg)
% Validate the configuration and reset global_info for a new run.
global global_info

isCount = @(x, minimum) isnumeric(x) && all(x(:) >= minimum) && all(x(:) == floor(x(:)));
steps = cfg.inspection.steps;
logistics = cfg.logistics;

assert(height(cfg.incoming) >= 1, 'At least one incoming truck is needed.');
assert(all(cfg.incoming.Time >= 0) && isCount(cfg.incoming.Pipes, 1), ...
    'Incoming trucks need Time >= 0 and Pipes >= 1.');
assert(isCount(cfg.yardCapacity, 1), 'yardCapacity must be a whole number >= 1.');
assert(isCount([logistics.forklifts, logistics.certifiedDrivers, logistics.crewSize, ...
    logistics.shipmentSize], 1) && isCount(logistics.otherWorkers, 0), ...
    'Logistics counts must be whole numbers (at least 1 forklift and 1 certified driver).');
assert(logistics.certifiedDrivers + logistics.otherWorkers >= logistics.crewSize, ...
    'Not enough logistics workers for a crew of %d.', logistics.crewSize);
assert(logistics.unloadMinutes > 0 && logistics.loadMinutes > 0 && ...
    logistics.customerTravelMinutes > 0, 'Logistics times must be > 0.');
staff = [cfg.workers.trainee, cfg.workers.junior, cfg.workers.senior];
assert(isCount(staff, 0) && sum(staff) >= 1, 'Worker counts must be whole numbers >= 0.');
assert(cfg.washing.minutes > 0 && isCount([cfg.washing.bays, cfg.washing.workers], 1));
assert(height(steps) >= 1 && isCount(cfg.inspection.stations, 1), ...
    'Inspection needs at least one step and one station.');
assert(all(steps.Minutes > 0) && isCount(steps.Workers, 1), ...
    'Inspection steps need Minutes > 0 and Workers >= 1.');
percents = [cfg.scrapPercent, cfg.repair.easy.percent, cfg.repair.hard.percent];
assert(all(percents >= 0) && sum(percents) <= 100, ...
    'Scrap + easy repair + hard repair percent must be between 0 and 100.');
assert(cfg.repair.easy.minutes > 0 && cfg.repair.hard.minutes > 0 && ...
    isCount([cfg.repair.stations, cfg.repair.easy.workers, cfg.repair.hard.workers], 1));
assert(cfg.tickMinutes > 0 && cfg.stopMinutes > 0);
times = [logistics.unloadMinutes, logistics.loadMinutes, logistics.customerTravelMinutes, ...
    cfg.washing.minutes, steps.Minutes', cfg.repair.easy.minutes, cfg.repair.hard.minutes, ...
    cfg.it.registerMinutes];
assert(all(times >= cfg.tickMinutes), 'All times must be >= tickMinutes (%g).', cfg.tickMinutes);

global_info = struct();
global_info.cfg = cfg;
global_info.STOP_AT = cfg.stopMinutes;
global_info.DELTA_TIME = cfg.tickMinutes;
global_info.MAX_LOOP = 1e6;
global_info.totalPipes = sum(cfg.incoming.Pipes);
global_info.pendingDecision = repmat({''}, 1, height(steps));
global_info.scrapAtStep = zeros(1, height(steps));
global_info.workerBusyMinutes = zeros(1, 3);
global_info.shipments = zeros(0, 2);
global_info.departingPipes = 0;
global_info.itRegisters = {'pIIncoming', 'pIReadyForWash', 'pIReadyForInspection', ...
    'pIReadyForEasyRepair', 'pIReadyForHardRepair', 'pIRepairDone', ...
    'pIReadyToShip', 'pIScrapped'};
global_info.itLog = cell(0, 2 + numel(global_info.itRegisters));

addCrewTask('tOWash', cfg.washing.workers, cfg.washing.difficulty, cfg.washing.minutes);
for step = 1:height(steps)
    addCrewTask(sprintf('tOStep%d', step), steps.Workers(step), ...
        steps.Difficulty{step}, steps.Minutes(step));
end
addCrewTask('tORepairEasy', cfg.repair.easy.workers, cfg.repair.easy.difficulty, cfg.repair.easy.minutes);
addCrewTask('tORepairHard', cfg.repair.hard.workers, cfg.repair.hard.difficulty, cfg.repair.hard.minutes);

    function addCrewTask(task, workers, difficulty, minutes)
        global_info.crewTasks.(task) = struct('workers', workers, ...
            'minLevel', pipe_yard_level(difficulty), 'minutes', minutes);
        global_info.taskCounts.(task) = 0;
    end
end
