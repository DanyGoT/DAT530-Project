function [fire, transition] = MOD_Yard_PRE(transition)
% The yard works during the shift. Hall joints leave for the wash in arrival
% order (global_info.hall), so the joints of an order stay together.

global global_info
fire = in_shift(global_info.P);
if not(fire), return, end

switch transition.name
    case 'tYLong'
        fire = next_hall_is('long');
    case 'tYShort'
        fire = next_hall_is('short');
end


function yes = next_hall_is(len)
global global_info
i = global_info.next_hall;
yes = i <= numel(global_info.hall) && strcmp(global_info.hall(i).len, len);
