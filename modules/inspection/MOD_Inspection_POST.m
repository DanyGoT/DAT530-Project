function [] = MOD_Inspection_POST(transition)
% Hand back the worker; on to the next joint that starts on the floor.
global global_info
if strcmp(transition.name, 'tIStart')
    global_info.next_floor = global_info.next_floor + 1;
end
release();
