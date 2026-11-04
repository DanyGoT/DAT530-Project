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
pns = pnstruct(model_pdfs(P));
pni = initialdynamics(pns, model_dyn(P, pns));
tic;
sim = gpensim(pni);
minutes = toc / 60;

weekdays = sum(mod(0:P.days-1, 7) < 5);
week = 5 / weekdays;
work = weekdays * diff(P.shift);                 % shift minutes per person
H = 1:P.halls;
exits = hall_name({'tIOk', 'tIMach', 'tIHb', 'tIScrap'}, H);   % hall by hall
n = cellfun(@timesfired, exits);
[~, ~, RU] = evalc('prnschedule(sim)');          % text, LE, RES_USAGE
levels = {sim.system_resources.name};

Y.inspected  = sum(n) * week;
Y.hall2      = sum(n(5:end)) * week;              % of them in the second hall
Y.per_hour   = sum(n) / (sum(P.crew) * work/60); % joints per man-hour, whole crew
Y.busy       = sum(RU(:, 2)) / (sum(P.crew) * work);
for L = 0:3                                      % busy share per level, with or without certificate
    i = ismember(levels, {sprintf('L%d', L), sprintf('L%dT', L)});
    Y.(sprintf('busy_L%d', L)) = nan;
    if P.crew(L+1) > 0
        Y.(sprintf('busy_L%d', L)) = sum(RU(i, 2)) / (P.crew(L+1) * work);
    end
end
certified = endsWith(levels, 'T');
Y.busy_cert  = sum(RU(certified, 2)) / max(1, sum(P.certified) * work);   % the forklift drivers
% Forklift work: minutes the forklifts were in use (jobs and drives between
% the yards), and person-minutes of yard work (driver, and helpers at lorries).
W = yard_work(P);
jobs = cellfun(@timesfired, W.name);
Y.fork_busy  = sum(jobs .* W.minutes) / (P.forklifts * work);
Y.yard_hours = sum(jobs .* W.minutes .* (1 + P.lorry_helpers * W.lorry)) / 60 * week;
Y.fork_trips = timesfired('tYForkToCoop') * week;
Y.from_coop  = (timesfired('tYFromCoopLong') + timesfired('tYFromCoopShort')) * week;
Y.gate       = av_tokens(sim, {'pAYLong', 'pAYShort', 'pAYBypass', 'pAYCHall', 'pAYCBypass'});  % waiting to be unloaded
% Hall joints not yet sent to the wash at the end: at the gate, at either
% yard, or on a lorry from Coop.
Y.yard_queue = sum(cellfun(@ntokens, {'pAYLong', 'pAYShort', 'pAYCHall', 'pYLong', 'pYShort', 'pCHall', 'pYToMain'}));
Y.waiting    = av_tokens(sim, hall_name({'pWI'}, H));      % washed, waiting for room on the floor
Y.free_floor = av_tokens(sim, hall_name({'pISpace'}, H));  % all halls
% Unmet demand: joints asked for and not loaded yet. tYOrder/tYOrderCoop move
% them from the connector (pDYOrder) into a yard (pYOrder, pCOrder), where they
% wait for stock and a forklift.
Y.unmet      = av_tokens(sim, {'pDYOrder', 'pYOrder', 'pCOrder'});
Y.unmet_end  = ntokens('pDYOrder') + ntokens('pYOrder') + ntokens('pCOrder');
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

% Every hour: hall joints at Main and at Coop, joints on the floors, between
% the yard and the floors (on the way, on the wash racks, washed and waiting
% for room), unmet demand, stock at both yards, and joints at the gate.
R.hour = (0:60:P.days*1440)' / 60;
X = hourly(sim, R.hour*60, {'pYLong', 'pYShort', 'pDYOrder', 'pYOrder', 'pCOrder', 'pYReady', 'pCReady', ...
                            'pCHall', 'pAYLong', 'pAYShort', 'pAYBypass', 'pAYCHall', 'pAYCBypass'});
halls = @(places) sum(hourly(sim, R.hour*60, hall_name(places, H)), 2);
R.yard_long  = X(:, 1);
R.yard_short = X(:, 2);
R.floor      = P.halls*P.hall_space - halls({'pISpace'});
R.to_wash    = halls({'pYW', 'pWRack', 'pWDone'});
R.washed     = halls({'pWI'});
R.unmet      = X(:, 3) + X(:, 4) + X(:, 5);
R.stock      = X(:, 6);
R.stock_coop = X(:, 7);
R.coop_hall  = X(:, 8);
R.gate       = sum(X(:, 9:13), 2);

% Every joint leaving a hall: when (minutes) and how (1 ok, 2 machining,
% 3 hardbanding, 4 scrap).
D = extractt(sim, exits);
if isempty(D), D = zeros(0, 3); end              % nothing left the hall (noL3: no one for UT)
[~, how] = ismember(D(:, 1), cellfun(@(t) find(strcmp({sim.global_transitions.name}, t)), exits));
R.out = sortrows([D(:, 3), mod(how - 1, 4) + 1]);
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
Yd.waiting_since = [gi.hall(not(gi.sent)).t]';
Yd.waiting_backlog = ismember([gi.hall(not(gi.sent)).order], [gi.backlog.order])';


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
