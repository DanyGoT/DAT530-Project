function [] = MOD_Inspection_POST(transition)
% Hand back the worker; on to the next joint that starts on the floor.
% Drain test (P.stop_clear): stop the run when the last joint has left the
% hall and no more are coming.
global global_info
if strcmp(transition.name, 'tIStart')
    global_info.next_floor = global_info.next_floor + 1;
end
release();
if global_info.P.stop_clear && ismember(transition.name, {'tIOk', 'tIMach', 'tIHb', 'tIScrap'}) && hall_clear()
    global_info.clear_at = current_time();
    global_info.STOP_SIMULATION = 1;
end


function yes = hall_clear()
% Every joint has arrived and left the yard for the hall, the floor is
% empty, and every credit is back in the yard (nothing at the wash or
% waiting for room).
global global_info
P = global_info.P;
yes = global_info.next_pipe > numel(global_info.pipes) ...
      && global_info.next_hall > numel(global_info.hall) ...
      && ntokens('pISpace') == P.hall_space && ntokens('pYRoom') == P.hall_buffer;
