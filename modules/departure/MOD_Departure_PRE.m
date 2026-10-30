function [fire, transition] = MOD_Departure_PRE(transition)
% The next joint asked for, once its time has come; shipping takes what comes.

global global_info

switch transition.name
    case 'tDTicket'
        i = global_info.next_demand;
        fire = i <= numel(global_info.demand) && global_info.demand(i) <= current_time();
    case 'tDShip'
        fire = 1;
end
