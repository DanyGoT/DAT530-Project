function [fire, transition] = MOD_Arrival_PRE(transition)
% The next joint is handed over once its time has come, by the port for its
% kind and yard.

switch transition.name
    case 'tALong'
        fire = next_arrival('hall', 'long', false);
    case 'tAShort'
        fire = next_arrival('hall', 'short', false);
    case 'tABypass'
        fire = next_arrival('bypass', '', false);
    case 'tACHall'
        fire = next_arrival('hall', '', true);
    case 'tACBypass'
        fire = next_arrival('bypass', '', true);
end


function fire = next_arrival(route, len, coop)
global global_info
i = global_info.next_pipe;
fire = 0;
if i > numel(global_info.pipes), return, end
p = global_info.pipes(i);
fire = p.t <= current_time() && strcmp(p.route, route) && p.coop == coop ...
       && (isempty(len) || strcmp(p.len, len));
