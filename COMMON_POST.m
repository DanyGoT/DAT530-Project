function [] = COMMON_POST(transition)
% Move the generators and the yard on to their next joint, and hand back any workers.

global global_info

switch transition.name
    case {'tALong', 'tAShort', 'tABypass'}
        global_info.next_pipe = global_info.next_pipe + 1;
    case {'tYLong', 'tYShort'}
        global_info.next_hall = global_info.next_hall + 1;
    case 'tDTicket'
        global_info.next_demand = global_info.next_demand + 1;
end
release();
