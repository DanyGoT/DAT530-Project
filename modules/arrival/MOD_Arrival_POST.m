function [] = MOD_Arrival_POST(transition)
% On to the next joint.
global global_info
global_info.next_pipe = global_info.next_pipe + 1;
