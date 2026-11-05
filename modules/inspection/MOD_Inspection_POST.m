function [] = MOD_Inspection_POST(transition)
% Hand back the worker; on to the next joint that starts on the floor.
% Keeps, per hall step, how many joints were done and when it was first and
% last worked on (global_info.step_log: [count first_start last_end]).
global global_info
if strcmp(transition.name, 'tIStart')
    global_info.next_floor = global_info.next_floor + 1;
elseif isKey(global_info.step_of, transition.name) && not(endsWith(transition.name, 'Skip'))
    k = global_info.step_of(transition.name);
    now = current_time();
    if global_info.step_log(k, 1) == 0
        global_info.step_log(k, 2) = now - global_info.S(k).ft;
    end
    global_info.step_log(k, 1) = global_info.step_log(k, 1) + 1;
    global_info.step_log(k, 3) = now;
end
release();
