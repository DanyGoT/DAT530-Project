function [] = MOD_Inspection_POST(transition)
% Hand back the worker; on to the next joint that starts on the floor.
% Drain test (P.stop_clear): stop the run when the last joint has left the
% halls and no more are coming.
global global_info
[~, t] = hall_of(transition.name);
if strcmp(t, 'tIStart')
    global_info.next_floor = global_info.next_floor + 1;
end
release();
if global_info.P.stop_clear && ismember(t, {'tIOk', 'tIMach', 'tIHb', 'tIScrap'}) && hall_clear()
    global_info.clear_at = current_time();
    global_info.STOP_SIMULATION = 1;
end


function yes = hall_clear()
% Every joint has arrived and left the yard for a hall, the floors are
% empty, and every credit is back in the yard (nothing at the washes or
% waiting for room).
global global_info
P = global_info.P;
H = 1:P.halls;
tokens = @(name) sum(cellfun(@ntokens, hall_name({name}, H)));
yes = global_info.next_pipe > numel(global_info.pipes) ...
      && global_info.next_hall > numel(global_info.hall) ...
      && tokens('pISpace') == P.halls*P.hall_space && tokens('pYRoom') == P.halls*P.hall_buffer;
