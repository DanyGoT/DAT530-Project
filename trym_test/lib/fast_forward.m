function [] = fast_forward()
% Skip idle time in legacy GPenSIM batches. The clock moves 15 s per loop even when nothing can
% happen, so a batch whose joints wait weeks at the workshops would take
% millions of loops. When the net has been quiet for a whole loop (nothing
% firing, nothing completed, nothing started), the state can only change at
% a time-based event: a shift starts or ends, a joint arrives, demand comes
% due, or a repair is done. Jump the clock to just before the next one.
% Only on when global_info.FAST_FORWARD is set (run_batch); called every loop
% from COMMON_PRE (tDTicket's clock token keeps it enabled).

global global_info PN
if not(isfield(global_info, 'FAST_FORWARD') && global_info.FAST_FORWARD), return, end
now = PN.current_time;
dt = PN.delta_T;
if not(isfield(global_info, 'ff')), global_info.ff = struct('last', -inf, 'quiet', 0, 'jumps', 0); end
ff = global_info.ff;

if any(PN.Firing_Transitions) || ntokens('pWOff') == 0      % busy, or the wash unit is manned
    ff.quiet = 0;
elseif now > ff.last                                         % the last loop moved the clock: no completions
    ff.quiet = ff.quiet + 1;
else
    ff.quiet = 0;
end
ff.last = now;

if ff.quiet >= 2
    T = next_event(now, global_info);
    if T - now > 2*dt
        PN.current_time = ceil(T/dt)*dt - dt;                % the next loop runs at T
        ff.last = PN.current_time;
        ff.quiet = 0;
        ff.jumps = ff.jumps + 1;
    end
end
global_info.ff = ff;


function T = next_event(now, g)
% The first time after now at which something may become possible.
P = g.P;
day = floor(now/1440);
T = inf;
for d = day:day+7                                            % next shift start or end
    if mod(d, 7) >= 5, continue, end
    for edge = d*1440 + P.shift
        if edge > now, T = min(T, edge); end
    end
    if T < inf, break, end
end
if g.next_pipe <= numel(g.pipes), T = min(T, g.pipes(g.next_pipe).t); end
if g.next_demand <= numel(g.demand), T = min(T, g.demand(g.next_demand)); end
for w = 1:numel(g.workshop)
    if not(isempty(g.workshop{w})), T = min(T, min(g.workshop{w}(:, 1))); end
end
