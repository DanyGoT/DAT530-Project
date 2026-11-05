function [] = print_batch(R, title)
% Report of a legacy GPenSIM run_batch run: when each stage was done, how long each hall
% step took and where the joints ended up. Times are shown as day and clock
% (day 1 is Monday) and as days after the batch arrived.

P = R.P;
B = R.B;
fprintf('\n=== %s ===\n', title);
fprintf('Crew L0-L3: [%s] (%d people). %d joints arrived %s.\n', ...
        num2str(P.crew), sum(P.crew), B.batch, clock_str(R.t0));
fprintf('Found: %d machining, %d hardbanding, %d scrap, %d ok.\n', ...
        R.finds, B.batch - sum(R.finds));

fprintf('\n%-38s %-20s %-20s %s\n', 'Stage', 'first', 'last', 'days after arrival');
stage(R, 'Unloaded', span(R, {'tALong', 'tAShort'}));
stage(R, 'Washed', span(R, {'tWOut'}));
stage(R, 'Inspected (first pass)', ends(R.t_hall));
stage(R, 'Repaired, inspected again', ends(R.t_rehall));
stage(R, 'Repaired, straight to stock', span(R, {'tYInRepaired'}));
stage(R, 'Rig-ready or scrap in the yard', ends(R.t_ready));

if not(isempty(R.t_ready))
    q = [0.5 0.9 1];
    fprintf('\nShare of the batch done (rig-ready or scrap):');
    for k = 1:numel(q)
        i = ceil(q(k)*B.batch);
        if i <= numel(R.t_ready)
            fprintf('  %d%% after %.1f days', round(100*q(k)), (R.t_ready(i) - R.t0)/1440);
        end
    end
    fprintf('\n');
end

fprintf('\nHall steps (in order; a joint goes through them one after another, the crew\n');
fprintf('works on different joints at different steps at the same time):\n');
fprintf('  %-8s %-5s %8s %7s %9s   %-20s %-20s\n', 'step', 'level', 'min/joint', 'joints', ...
        'labour h', 'first start', 'last end');
total = 0;
for k = 1:numel(R.steps)
    s = R.steps(k);
    L = R.step_log(k, :);
    h = L(1)*s.ft/60;
    total = total + h;
    if L(1) == 0
        fprintf('  %-8s L%-4d %8.2f %7d %9.1f\n', s.name, s.level, s.ft, 0, 0);
    else
        fprintf('  %-8s L%-4d %8.2f %7d %9.1f   %-20s %-20s\n', s.name, s.level, s.ft, L(1), h, ...
                clock_str(L(2)), clock_str(L(3)));
    end
end
fprintf('  Hall labour: %.0f man-hours (%.1f min per joint through the hall)\n', ...
        total, 60*total/max(1, numel(R.t_hall) + numel(R.t_rehall)));
if numel(R.t_hall) >= B.batch
    first_pass = (R.t_hall(B.batch) - R.t0)/1440;
    fprintf('  First pass: %.1f days for the whole batch, %.0f joints a working day\n', ...
            first_pass, B.batch/max(working_days(P, R.t0, R.t_hall(B.batch)), eps));
end

fprintf('\nWhere the joints are:\n');
fprintf('  Yard, rig-ready stock:       %d (ok %d first pass, %d repaired)\n', R.ready, ...
        R.out(1) - numel(R.t_rehall), numel(R.t_rehall) + R.back(2));
fprintf('  Yard, scrap:                 %d\n', R.scrap);
fprintf('  Workshops (mach / hb):       %d / %d\n', R.at_workshop);
fprintf('  Still in the yard/wash/hall: %d\n', B.batch - R.ready - R.scrap - sum(R.at_workshop));
med = median(R.repair);
fprintf('Repair time drawn per order (days), median machining / hardbanding: %.0f / %.0f, longest %.0f / %.0f\n', ...
        med, max(R.repair));
if not(R.done)
    fprintf('NOT finished after %d days. Increase B.max_days or the crew.\n', B.max_days);
end
fprintf('Simulated %.1f days in %.0f s (%d idle stretches skipped)\n', ...
        (R.end_time - R.t0)/1440, R.runtime, R.jumps);


function [] = stage(R, name, t)
if isempty(t)
    fprintf('%-38s %s\n', name, '-');
    return
end
fprintf('%-38s %-20s %-20s %.1f - %.1f\n', name, clock_str(t(1)), clock_str(t(2)), ...
        (t - R.t0)/1440);


function t = span(R, names)
% First and last firing of any of the port transitions.
t = [];
for n = names
    if isfield(R.when, n{1}), t = [t; R.when.(n{1})]; end
end
if not(isempty(t)), t = [min(t(:, 1)), max(t(:, 2))]; end


function t = ends(v)
t = [];
if not(isempty(v)), t = [min(v), max(v)]; end


function n = working_days(P, a, b)
% Shift time between a and b, in shifts.
n = 0;
for d = floor(a/1440):floor(b/1440)
    if mod(d, 7) >= 5, continue, end
    s = d*1440 + P.shift;
    n = n + max(0, min(b, s(2)) - max(a, s(1)))/diff(P.shift);
end


function s = clock_str(t)
days = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'};
d = floor(t/1440);
m = round(mod(t, 1440));
if m == 1440, d = d + 1; m = 0; end
s = sprintf('day %d (%s) %02d:%02d', d + 1, days{mod(d, 7) + 1}, floor(m/60), mod(m, 60));