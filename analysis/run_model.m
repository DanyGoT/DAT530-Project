function [Y, R] = run_model(P)
% One run of the whole model with parameters P, and what the analyses and
% the report's figures need from it. sens_run (sensitivity analysis) and
% exp_run (experiments) both run the model through here.
%
%   Y  one number per output; counts are per week of five weekdays
%      (x 5/weekdays), so runs shorter than a week compare with weeks
%   R  what the figures need: the state every hour, every joint leaving the
%      hall, days in the yard per joint, and the crew's work log

global global_info

model_init(P);
pns = pnstruct({'arrival_pdf', 'yard_pdf', 'wash_pdf', 'inspection_pdf', ...
                'repair_pdf', 'departure_pdf', ...
                'imc_arrival_yard', 'imc_yard_wash', 'imc_wash_inspection', ...
                'imc_inspection_yard', 'imc_inspection_repair', 'imc_repair_yard', ...
                'imc_yard_departure'});
pni = initialdynamics(pns, model_dyn(P, pns));
tic;
sim = gpensim(pni);
minutes = toc / 60;

weekdays = sum(mod(0:P.days-1, 7) < 5);
week = 5 / weekdays;
work = weekdays * diff(P.shift);                 % shift minutes per person
exits = {'tIOk', 'tIMach', 'tIHb', 'tIScrap'};
n = cellfun(@timesfired, exits);
[~, ~, RU] = evalc('prnschedule(sim)');          % text, LE, RES_USAGE
levels = {sim.system_resources.name};
lanes = 1:P.wash_lanes;

Y.inspected  = sum(n) * week;
Y.per_hour   = sum(n) / (sum(P.crew) * work/60); % joints per man-hour, whole crew
Y.busy       = sum(RU(:, 2)) / (sum(P.crew) * work);
for L = 0:3                                      % busy share per level
    i = find(strcmp(levels, sprintf('L%d', L)));
    Y.(sprintf('busy_L%d', L)) = nan;
    if not(isempty(i)) && P.crew(L+1) > 0
        Y.(sprintf('busy_L%d', L)) = RU(i, 2) / (P.crew(L+1) * work);
    end
end
Y.yard_queue = ntokens('pYLong') + ntokens('pYShort');   % hall joints still in the yard at the end
Y.waiting    = av_tokens(sim, {'pWI'});          % washed, waiting for room on the floor
Y.free_floor = av_tokens(sim, {'pISpace'});
Y.changes    = sum(arrayfun(@(k) timesfired(sprintf('tWToShort_%d', k)) + ...
                             timesfired(sprintf('tWToLong_%d', k)), lanes)) * week;
% Unmet demand: joints asked for and not loaded yet. tYOrder moves them from
% the connector (pDYOrder) into the yard (pYOrder), where they wait for stock.
Y.unmet      = av_tokens(sim, {'pDYOrder', 'pYOrder'});
Y.unmet_end  = ntokens('pDYOrder') + ntokens('pYOrder');
Y.shipped    = timesfired('tDShip') * week;

% Days in the yard, per hall joint that came onto the floor: from its
% order's receipt to the floor. Joints of the starting backlog have no
% receipt time (they were already waiting at t = 0) and are left out.
R.yard = yard_days(global_info);
new = not(R.yard.backlog);
d = R.yard.days(new);
Y.yard_n        = numel(d);
Y.yard_days_med = quantile_(d, 0.5);
Y.yard_days_p90 = quantile_(d, 0.9);
Y.yard_days_max = quantile_(d, 1);
Y.minutes       = minutes;                        % run time

% Every hour: hall joints in the yard, joints on the floor, between the
% yard and the floor (on the way, on the wash rack, washed and waiting for
% room), unmet demand and stock.
R.hour = (0:60:P.days*1440)' / 60;
X = hourly(sim, R.hour*60, {'pYLong', 'pYShort', 'pISpace', 'pYW', 'pWRack', 'pWDone', 'pWI', ...
                            'pDYOrder', 'pYOrder', 'pYReady'});
R.yard_long  = X(:, 1);
R.yard_short = X(:, 2);
R.floor      = P.hall_space - X(:, 3);
R.to_wash    = X(:, 4) + X(:, 5) + X(:, 6);
R.washed     = X(:, 7);
R.unmet      = X(:, 8) + X(:, 9);
R.stock      = X(:, 10);

% Every joint leaving the hall: when (minutes) and how (1 ok, 2 machining,
% 3 hardbanding, 4 scrap).
D = extractt(sim, exits);
if isempty(D), D = zeros(0, 3); end              % nothing left the hall (noL3: no one for UT)
[~, how] = ismember(D(:, 1), cellfun(@(t) find(strcmp({sim.global_transitions.name}, t)), exits));
R.out = sortrows([D(:, 3), how]);
R.exits = exits;

% The crew's work: one row per job [resource, transition, start, end,
% instance], as prnschedule reads it.
R.crew_log = sim.Resource_usage_LOG;
R.levels = levels;
R.transitions = {sim.global_transitions.name};
R.n_backlog = numel(global_info.backlog);
R.stop = sim.completion_time;

% Per joint leaving the hall [time, order, how] (order 0: back from repair),
% when each order came in [order, received], the repair days per order, the
% joints still at the workshops at the end [done again], and for the drain
% test when the hall was clear.
R.hall_out = global_info.hall_out;
h = global_info.hall;
[~, first] = unique([h.order]);
R.received = [[h(first).order]', [h(first).t]'];
R.repair = global_info.repair;
R.workshop = global_info.workshop;
R.clear_at = global_info.clear_at;


function Yd = yard_days(gi)
% One row per joint that came from the yard onto the floor. The yard logs
% each joint it sends to the wash [time, received, order]; the hall logs each
% joint coming onto the floor [time, order]. Joints of an order go in turn,
% so the k-th of an order onto the floor is the k-th of it out of the yard.
out = gi.yard_out;
fl = gi.floor_in;
m = size(fl, 1);
Yd.order    = fl(:, 2);
Yd.floor    = fl(:, 1);
Yd.left     = nan(m, 1);
Yd.received = nan(m, 1);
for o = unique(fl(:, 2))'
    i = find(fl(:, 2) == o);
    j = find(out(:, 3) == o);
    k = min(numel(i), numel(j));
    Yd.left(i(1:k)) = out(j(1:k), 1);
    Yd.received(i(1:k)) = out(j(1:k), 2);
end
Yd.backlog = ismember(Yd.order, [gi.backlog.order]);
Yd.days = (Yd.floor - Yd.received) / 1440;
% Still in the yard at the end, not yet sent: when they were received.
Yd.waiting_since = [gi.hall(gi.next_hall:end).t]';
Yd.waiting_backlog = ismember([gi.hall(gi.next_hall:end).order], [gi.backlog.order])';


function X = hourly(sim, times, places)
% Tokens in each place at the given times (minutes): the marking of the
% last state change at or before each time.
global PN
PN = sim;
TM = extractp(places);
t = TM(2:end, 1);
M = TM(2:end, 2:end);
X = zeros(numel(times), numel(places));
for h = 1:numel(times)
    k = find(t <= times(h), 1, 'last');
    if isempty(k), k = 1; end
    X(h, :) = M(k, :);
end


function a = av_tokens(sim, places)
% Time-weighted mean of the tokens in places (summed), over the whole run.
% GPenSIM v11 has no avtokens; the log has a row per state change.
global PN
PN = sim;
TM = extractp(places);
t = TM(2:end, 1);                       % a row holds from its time to the next row's
T = max(PN.completion_time, t(end));
tok = sum(TM(2:end, 2:end), 2);
a = sum(tok .* diff([t; T])) / (T - t(1));


function q = quantile_(x, p)
% The p-quantile of x (nearest rank), NaN for no data. No Statistics Toolbox.
x = sort(x(not(isnan(x))));
q = nan;
if isempty(x), return, end
q = x(max(1, ceil(p * numel(x))));
