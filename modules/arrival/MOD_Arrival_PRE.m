function [fire, transition] = MOD_Arrival_PRE(transition)
% The next joint is unloaded once its time has come, by the port for its kind.

switch transition.name
    case 'tALong'
        fire = next_arrival('hall', 'long');
    case 'tAShort'
        fire = next_arrival('hall', 'short');
    case 'tABypass'
        fire = next_arrival('bypass', '');
end


function fire = next_arrival(route, len)
global global_info
i = global_info.next_pipe;
fire = 0;
if i > numel(global_info.pipes), return, end
p = global_info.pipes(i);
fire = p.t <= current_time() && strcmp(p.route, route) && (isempty(len) || strcmp(p.len, len));
