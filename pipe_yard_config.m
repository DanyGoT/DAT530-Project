function cfg = pipe_yard_config()
% PIPE_YARD_CONFIG  All input fields for the pipe yard simulation.
% Edit the values below, then run:  run_pipe_yard
% Time unit: minutes.
%
% Skill levels:  easy -> trainee, junior or senior
%                moderate -> junior or senior
%                hard -> senior only

%% ---------------- Incoming pipes (IT registers them) ----------------
% One row per incoming truck: arrival time and number of pipes on it.
cfg.incoming = table([0; 300], [12; 8], 'VariableNames', {'Time', 'Pipes'});
% How many pipes can be in the yard at the same time (unloaded, waiting for washing).
cfg.yardCapacity = 10;

%% ---------------- Logistics (unloading / loading) ----------------
cfg.logistics.forklifts = 1;            % forklifts available
cfg.logistics.certifiedDrivers = 1;     % workers with forklift certificate
cfg.logistics.otherWorkers = 2;         % workers without certificate
cfg.logistics.crewSize = 3;             % workers per unload/load (1 must be certified driver)
cfg.logistics.unloadMinutes = 3;        % per pipe, incoming truck -> yard
cfg.logistics.loadMinutes = 3;          % per pipe, ready-to-ship -> customer truck
cfg.logistics.shipmentSize = 10;        % pipes per customer shipment (last one may be smaller)
cfg.logistics.customerTravelMinutes = 60;  % one-way drive to the customer

%% ---------------- Operations workers (shared by washing, inspection, repair) ----------------
cfg.workers.trainee = 2;
cfg.workers.junior = 2;
cfg.workers.senior = 2;

%% ---------------- Washing ----------------
cfg.washing.minutes = 20;               % time to wash one pipe
cfg.washing.difficulty = 'easy';
cfg.washing.workers = 1;                % people needed per pipe
cfg.washing.bays = 2;                   % pipes that can be washed at the same time

%% ---------------- Inspection ----------------
cfg.inspection.stations = 4;            % pipes that can be inspected at the same time
% One row per inspection step, done in this order.
% Difficulty: 'easy' | 'moderate' | 'hard'.  Workers: people needed (1-6).
cfg.inspection.steps = table( ...
    {'Visual check'; 'Thread check'; 'Wall thickness'; 'MPI'; 'Drift test'; 'Final sign-off'}, ...
    {'easy';         'easy';         'moderate';       'moderate'; 'hard';   'hard'}, ...
    [10;             15;             20;               25;     30;           10], ...
    [1;              1;              1;                2;      1;            1], ...
    'VariableNames', {'Name', 'Difficulty', 'Minutes', 'Workers'});

% Percent of all pipes scrapped. Scrapped pipes leave inspection at a random
% step, before the remaining steps are done.
cfg.scrapPercent = 5;

%% ---------------- Repair (decided at the end of inspection) ----------------
cfg.repair.stations = 2;                % pipes that can be repaired at the same time
cfg.repair.easy.percent = 15;           % percent of all pipes needing easy repair
cfg.repair.easy.minutes = 30;
cfg.repair.easy.difficulty = 'moderate';
cfg.repair.easy.workers = 1;
cfg.repair.hard.percent = 5;            % percent of all pipes needing hard repair
cfg.repair.hard.minutes = 120;
cfg.repair.hard.difficulty = 'hard';
cfg.repair.hard.workers = 1;

%% ---------------- IT ----------------
cfg.it.registerMinutes = 0.5;           % time IT uses to register a status change

%% ---------------- Simulation ----------------
% Clock step. GPenSIM needs firing times > 0, so routing decisions and
% truck-to-customer hand-over take one tick. All other times must be >= this.
% Run time grows with (finish time / tickMinutes).
cfg.tickMinutes = 0.5;              % smaller = more precise but slower
cfg.stopMinutes = 5000;                 % hard stop (simulation ends earlier when all pipes are done)
cfg.seed = 1;                           % random seed for scrap/repair decisions
end
