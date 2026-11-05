function [] = COMMON_POST(transition)
% Legacy GPenSIM batch runs only (run_batch.m sets global_info.batch_size); does nothing in
% other runs. Runs after every port firing:
% - keeps when each port fired first and last (global_info.when), and when
%   each joint came out of the hall (first pass, or again after repair) and
%   when it became rig-ready or scrap in the yard
% - stops the run once every joint of the batch is done:
%     batch_until = 'hall'  - out of the hall: in the yard (ok, scrap) or at a workshop
%     batch_until = 'ready' - rig-ready in the yard (ok, or repaired and back) or scrap
global global_info
if not(isfield(global_info, 'batch_size')), return, end
t = transition.name;
now = current_time();
if isfield(global_info.when, t)
    global_info.when.(t)(2) = now;
else
    global_info.when.(t) = [now now];
end
switch t
    case 'tIOk'
        if global_info.ok_repaired
            global_info.t_rehall(end+1) = now;
        else
            global_info.t_hall(end+1) = now;
        end
    case {'tIMach', 'tIHb', 'tIScrap'}
        global_info.t_hall(end+1) = now;
    case {'tYInOk', 'tYInRepaired', 'tYInScrap'}
        global_info.t_ready(end+1) = now;
end

if strcmp(global_info.batch_until, 'hall')
    done = sum(cellfun(@timesfired, {'tYInOk', 'tYInScrap', 'tRInMach', 'tRInHb'}));
else
    done = numel(global_info.t_ready);
end
if done >= global_info.batch_size
    global_info.STOP_SIMULATION = 1;
end
