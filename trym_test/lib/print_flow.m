function T = print_flow(R, name)
% Trym's calendar elapsed time and inspection queueing reports.
L = R.log(R.log.completed, :);
C = R.C;
fprintf('\n=== %s: %d pipes (%d initially in yard, %d incoming) ===\n', ...
    name, C.total, C.initial, C.total - C.initial);
fprintf('Crew L0-L3 %s; certified %s; forklifts %d; wash lanes %d\n', ...
    mat2str(R.P.crew), mat2str(C.certified), C.forklifts, R.P.wash_lanes);
tasks = {'unload', 'feed_wash', 'wash', 'wash_close', 'enter_hall', 'inspect', ...
    'move_out', 'repair', 'return', 'load', 'departure'};
fprintf('%-14s %7s %14s %14s\n', 'Task', 'jobs', 'first day', 'last day');
for i = 1:numel(tasks)
    rows = strcmp(L.task, tasks{i});
    if any(rows)
        fprintf('%-14s %7d %14.3f %14.3f\n', tasks{i}, sum(rows), ...
            (min(L.start(rows)) - C.start)/1440, (max(L.finish(rows)) - C.start)/1440);
    end
end
first = strcmp(L.task, 'move_out') & L.pass == 1;
first_pass = NaN;
if sum(first) == C.total
    first_pass = (max(L.finish(first)) - C.start)/1440;
end
fprintf('\nInspection: wait is elapsed queue time, including nights/weekends.\n');
fprintf('%-12s %8s %12s %12s\n', 'Step', 'jobs', 'work min', 'mean wait');
for k = 1:size(R.P.steps, 1)
    rows = strcmp(L.task, 'inspect') & L.step == k;
    wait = NaN;
    if any(rows), wait = mean(L.wait(rows)); end
    fprintf('%-12s %8d %12.1f %12.1f\n', R.P.steps{k, 1}, sum(rows), ...
        sum(L.finish(rows) - L.start(rows)), wait);
end
fprintf('Shipped %d + scrap %d + unfinished %d = %d\n', ...
    R.shipped, R.scrap, R.remaining, C.total);
fprintf('Peak occupied inspection floor: %d / %d; wash: %d / %d\n', ...
    max(R.history.hall), R.P.hall_space, max(R.history.wash), C.wash_space);
fprintf('Full first pass: %.3f days; run ended: %.3f days; complete: %d\n', ...
    first_pass, (R.end_time - C.start)/1440, R.complete);
T = table({name}, sum(R.P.crew), first_pass, (R.end_time - C.start)/1440, ...
    R.shipped, R.scrap, R.remaining, R.complete, 'VariableNames', ...
    {'Scenario', 'Workers', 'FirstPassDays', 'EndDays', 'Shipped', 'Scrap', 'Unfinished', 'Complete'});
end
