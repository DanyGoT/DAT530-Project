function T = costs(tags)
% The variable cost drivers of each saved experiment run: person-hours (paid,
% worked by where, idle, overtime), joints inspected and orders completed,
% repairs, and deliveries. No prices: these are the quantities a cost model
% would multiply. Reads results/experiments/<tag>_s<seed>.mat for each tag
% in tags (all runs if none), writes results/experiments/costs.csv (one row
% per run) and costs_by_tag.csv (mean over seeds), and returns the per-run
% table. Everything is per week of five weekdays, like run_model's outputs.
%
% Orders completed needs each order's number of hall joints, which the runs
% don't save; it is drawn again from the run's parameters and seed
% (model_init), and checked against the orders the run saved.
%
%   costs({'base3', 'crew2021', 'overtime'})

global global_info
root = fileparts(fileparts(mfilename('fullpath')));
folder = fullfile(root, 'results', 'experiments');
files = dir(fullfile(folder, '*_s*.mat'));
if nargin > 0
    keep = false(size(files));
    for k = 1:numel(files)
        keep(k) = ismember(regexprep(files(k).name, '_s\d+\.mat$', ''), tags);
    end
    files = files(keep);
end

rows = {};
for k = 1:numel(files)
    S = load(fullfile(folder, files(k).name));
    if not(isfield(S, 'R')) || not(isfield(S.R, 'crew_log')), continue, end
    rows{end+1} = one_run(S); %#ok<AGROW>
end
T = struct2table([rows{:}]);
writetable(T, fullfile(folder, 'costs.csv'));
by = groupsummary(T, 'tag', 'mean', T.Properties.VariableNames(3:end));
writetable(by, fullfile(folder, 'costs_by_tag.csv'));


function C = one_run(S)
global global_info
P = S.P; R = S.R;
weekdays = sum(mod(0:P.days-1, 7) < 5);
week = 5 / weekdays;
regular = [7 15]*60;                              % the normal working day (params.m)

C.tag = string(S.tag);
C.seed = S.seed;

% Person-hours. Paid: everyone for the whole shift. Worked: the crew log, one
% row per person per job [resource, transition, start, end, instance], by
% where the job is: hall steps (tI...), wash lanes (tW...), yard (tY...).
people = sum(P.crew);
C.paid_h = people * diff(P.shift)/60 * weekdays * week;
C.overtime_paid_h = people * (max(0, P.shift(2) - regular(2)) + max(0, regular(1) - P.shift(1)))/60 ...
                    * weekdays * week;
L = R.crew_log;
name = R.transitions(L(:, 2));
minutes = L(:, 4) - L(:, 3);
where = @(prefix) sum(minutes(startsWith(regexprep(name, '^tH\d+_', 't'), prefix)))/60 * week;
C.hall_h = where('tI');
C.wash_h = where('tW');
C.yard_h = where('tY');
C.worked_h = sum(minutes)/60 * week;
C.idle_h = C.paid_h - C.worked_h;
C.overtime_worked_h = outside(L(:, 3), L(:, 4), regular, P.days)/60 * week;

% Joints and orders. hall_out: [time, order, how 1 ok 2 machining 3 HB 4
% scrap], order 0 for a joint back from repair.
out = R.hall_out;
C.inspected = size(out, 1) * week;
C.reinspected = sum(out(:, 2) == 0) * week;
C.to_machining = sum(out(:, 3) == 2) * week;
C.to_hardbanding = sum(out(:, 3) == 3) * week;
C.scrapped = sum(out(:, 3) == 4) * week;

model_init(P);                                    % the run's orders, drawn again
assert(isequal(unique([global_info.hall.order])', R.received(:, 1)), ...
       'the orders drawn again differ from the run''s (%s seed %d)', S.tag, S.seed);
orders = [global_info.hall.order, global_info.floor.order];
[ids, ~, j] = unique(orders);
size_of = accumarray(j(:), 1);
done = out(out(:, 2) > 0, 2);
[d, ~, jd] = unique(done);
left = accumarray(jd(:), 1);
[~, at] = ismember(d, ids);
C.orders_done = sum(left == size_of(at)) * week;

% Deliveries (run_model): joints loaded out, and joints asked for and not
% loaded at the end.
C.shipped = S.Y.shipped;
C.tickets_waiting = S.Y.unmet_end;
C.paid_h_per_joint = C.paid_h / C.inspected;


function m = outside(t0, t1, regular, days)
% Minutes of the jobs [t0, t1] outside the regular hours of each day.
m = 0;
for day = 0:days-1
    a = day*1440 + regular(1);
    b = day*1440 + regular(2);
    m = m + sum(max(0, min(t1, a) - max(t0, day*1440))) ...      % before 07:00
          + sum(max(0, min(t1, (day+1)*1440) - max(t0, b)));      % after 15:00
end
