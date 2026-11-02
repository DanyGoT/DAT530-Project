function [sim, report] = run_pipe_yard(cfg, showPlots)
% RUN_PIPE_YARD  Simulate pipes from incoming truck to customer shipment.
%   run_pipe_yard                  - uses pipe_yard_config.m
%   run_pipe_yard(cfg)             - uses your own cfg struct
%   [sim, report] = run_pipe_yard(cfg, false)  - no plots
%
% Modules: Logistics (logistics_pn_pdf), Operations (operations_pn_pdf),
%          IT (it_pn_pdf). See pipe_yard_config.m for all input fields.
global global_info
if nargin < 1 || isempty(cfg)
    cfg = pipe_yard_config();
end
if nargin < 2
    showPlots = true;
end
if ~exist('gpensim', 'file')
    addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', ...
        '3_ GPenSIM_v11_System_Files')));
end

pipe_yard_init(cfg);
rng(cfg.seed, 'twister');
pns = pnstruct({'logistics_pn_pdf', 'operations_pn_pdf', 'it_pn_pdf'});
dyn = pipe_yard_dynamics(cfg, pns);
sim = gpensim(initialdynamics(pns, dyn));

report = buildReport(sim, cfg);
printReport(report);
if showPlots
    figure('Name', 'IT status registers');
    plotp(sim, [global_info.itRegisters, {'pLDelivered'}]);
    figure('Name', 'Free workers');
    plotp(sim, {'pOTrainee', 'pOJunior', 'pOSenior', 'pLCertified', 'pLHelpers'});
    figure('Name', 'Yard and shipping');
    plotp(sim, {'pIIncoming', 'pLYardSpace', 'pLOnTruck', 'pLDelivered'});
end
end

function report = buildReport(sim, cfg)
global global_info
placeNames = {sim.global_places.name};
marking = @(name) sim.X(strcmp(placeNames, name));
itEvents = global_info.itLog(:, 2);
registered = @(event) sum(strcmp(itEvents, event));

delivered = marking('pLDelivered');
scrapped = marking('pIScrapped');
report.completed = delivered + scrapped == global_info.totalPipes;
if report.completed
    finishedAt = max([cell2mat(global_info.itLog(:, 1)); global_info.shipments(:, 1)]);
else
    finishedAt = cfg.stopMinutes;
    warning('Not all pipes finished within stopMinutes = %g. Increase cfg.stopMinutes.', ...
        cfg.stopMinutes);
end
report.finishedAtMinute = finishedAt;

metric = {'Pipes received'; 'Passed without repair'; 'Easy repairs'; 'Hard repairs'; ...
    'Scrapped'; 'Delivered to customer'; 'Customer shipments'; 'Finished at (min)'};
value = [global_info.totalPipes; registered('tIRegisterPassed'); ...
    registered('tIRegisterEasyRepair'); registered('tIRegisterHardRepair'); ...
    scrapped; delivered; size(global_info.shipments, 1); finishedAt];
report.summary = table(metric, value, 'VariableNames', {'Metric', 'Value'});

report.shipments = table((1:size(global_info.shipments, 1))', global_info.shipments(:, 1), ...
    global_info.shipments(:, 2), 'VariableNames', {'Shipment', 'ArrivedAtCustomerMinute', 'Pipes'});

staff = [cfg.workers.trainee; cfg.workers.junior; cfg.workers.senior];
busy = global_info.workerBusyMinutes(:);
utilization = 100 * busy ./ max(staff * finishedAt, eps);
utilization(staff == 0) = 0;
report.workers = table({'Trainee'; 'Junior'; 'Senior'}, staff, busy, round(utilization, 1), ...
    'VariableNames', {'Level', 'Staffed', 'BusyMinutes', 'UtilizationPercent'});

steps = cfg.inspection.steps;
report.inspection = [steps, table(global_info.scrapAtStep(:), 'VariableNames', {'ScrappedHere'})];

registers = global_info.itRegisters';
counts = zeros(numel(registers), 1);
for i = 1:numel(registers)
    counts(i) = marking(registers{i});
end
report.itRegisters = table(registers, counts, 'VariableNames', {'Register', 'PipesAtEnd'});
report.itLog = cell2table(global_info.itLog, 'VariableNames', ...
    [{'Minute', 'Event'}, global_info.itRegisters]);
end

function printReport(report)
disp('=== Pipe yard summary ===');
disp(report.summary);
disp('=== Customer shipments ===');
disp(report.shipments);
disp('=== Operations workers ===');
disp(report.workers);
disp('=== Inspection steps ===');
disp(report.inspection);
disp('=== IT registers at end ===');
disp(report.itRegisters);
end
