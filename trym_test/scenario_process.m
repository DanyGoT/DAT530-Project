function [results, summary] = scenario_process(total, batch_clearance, move_minutes)
% Isolated wash -> sequential inspection -> ready for repair / ok / scrap.
% scenario_process(100,true,15): hall-sized groups, 15 minutes per group move.
% Default scenario_process(100) retains continuous flow without removal time.
root = trym_test_setup();
if nargin < 1, total = 100; end
if nargin < 2, batch_clearance = false; end
if nargin < 3, move_minutes = 15; end
base = params();
names = {'3 mixed', '3 L3', '6 mixed', '6 L3', ...
    '7 baseline', '7 promoted', '12 mixed', '15 L3'};
crews = [1 1 0 1; 0 0 0 3; 2 2 1 1; 0 0 0 6; ...
    base.crew; 2 2 1 2; 3 3 3 3; 0 0 0 15];
lanes = unique([base.wash_lanes, 2*base.wash_lanes]);
results = cell(size(crews, 1), numel(lanes));
rows = cell(size(crews, 1)*numel(lanes), 1);
for i = 1:size(crews, 1)
    for j = 1:numel(lanes)
        P = base;
        P.crew = crews(i, :);
        P.wash_lanes = lanes(j);
        % Higher competence includes permission to perform lower-level wash work.
        P.wash_crew = {'L0', 'L1', 'L2', 'L3'};
        C = flow_config(P);
        C.process_only = true;
        C.batch_clearance = batch_clearance;
        C.batch_move_minutes = move_minutes;
        C.total = total;
        C.initial = total;
        C.certified = [0 0 0 0];
        C.step_machines(:) = total; % no artificial one-machine-per-step limit
        R = run_flow(P, C);
        L = R.log(R.log.completed, :);
        inspect = strcmp(L.task, 'inspect');
        wash = strcmp(L.task, 'wash');
        process_end = max(L.finish(inspect));
        last_wash = max(L.finish(wash));
        peak = 0;
        for t = unique(L.start(inspect))'
            peak = max(peak, sum(inspect & L.start <= t & L.finish > t + 1e-8));
        end
        moves = strcmp(L.task, 'batch_move_out');
        yard_hours = (process_end-C.start)/60;
        if any(moves), yard_hours = (max(L.finish(moves))-C.start)/60; end
        if R.remaining > 0, yard_hours = NaN; end
        row = table(names(i), {mat2str(P.crew)}, sum(P.crew), P.wash_lanes, ...
            (last_wash-C.start)/60, (process_end-C.start)/60, ...
            yard_hours, sum(moves), (R.end_time-C.start)/60, peak, R.ok, R.ready_repair, R.scrap, ...
            R.remaining, R.complete, 'VariableNames', {'Crew', 'L0_L3', 'Workers', ...
            'WashLanes', 'LastWashedHours', 'InspectionDoneHours', ...
            'YardReadyHours', 'GroupsMoved', 'IncludingShutdownHours', 'PeakInspectors', 'OK', 'ReadyRepair', ...
            'Scrap', 'Unfinished', 'Complete'});
        [working_shifts, shifts_started, finish_clock] = calendar_report(P, C.start, R.end_time);
        row.ElapsedDays = (R.end_time-C.start)/1440;
        row.FinishDayTime = {finish_clock};
        row.WorkingShifts = working_shifts;
        row.ShiftsStarted = shifts_started;
        rows{(i-1)*numel(lanes)+j} = row;
        results{i, j} = R;
    end
end
summary = vertcat(rows{:});
disp(summary);
fprintf(['Times are elapsed calendar hours (including nights/weekends).\n', ...
    'Inspection has unlimited equipment, shared staff, and %d hall positions.\n', ...
    'One worker per active wash lane; setup/changeover/shutdown use staff.\n'], base.hall_space);
folder = fullfile(root, 'flow_results');
if ~exist(folder, 'dir'), mkdir(folder); end
stem = 'process';
if batch_clearance
    stem = 'process_batches';
    fprintf('Hall groups of %d; one shared worker moves each group in %g minutes.\n', ...
        base.hall_space, move_minutes);
end
save(fullfile(folder, [stem, '.mat']), 'results', 'summary');
writetable(summary, fullfile(folder, [stem, '_summary.csv']));
figure('Name', 'Washing and inspection only');
bar(reshape(summary.YardReadyHours, numel(lanes), [])');
xticklabels(names); xtickangle(30);
ylabel('Elapsed calendar hours until ready in yard');
legend(arrayfun(@(n) sprintf('%d wash lanes', n), lanes, 'UniformOutput', false), ...
    'Location', 'best');
title(sprintf('%d pipes; unlimited inspection equipment', total));
plot_process(results);
end

function [shifts, started, clock] = calendar_report(P, first, last)
% Available shift time elapsed, not worker labour or utilization.
shifts = 0;
started = 0;
for day = floor(first/1440):floor(last/1440)
    if mod(day, 7) >= 5, continue, end
    edges = day*1440 + P.shift;
    minutes = max(0, min(last, edges(2)) - max(first, edges(1)));
    shifts = shifts + minutes/diff(P.shift);
    started = started + (minutes > 0);
end
weekdays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'};
day = floor(last/1440);
minutes = round(mod(last, 1440));
if minutes == 1440, day = day + 1; minutes = 0; end
clock = sprintf('Day %d %s %02d:%02d', day+1, weekdays{mod(day, 7)+1}, ...
    floor(minutes/60), mod(minutes, 60));
end
