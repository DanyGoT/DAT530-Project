function [] = MOD_Departure_POST(transition)
% On to the next joint asked for.
global global_info
if strcmp(transition.name, 'tDTicket')
    global_info.next_demand = global_info.next_demand + 1;
end
