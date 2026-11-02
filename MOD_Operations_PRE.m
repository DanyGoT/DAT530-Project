function [fire, transition] = MOD_Operations_PRE(transition)
global global_info

fire = true;
crew = regexp(transition.name, '^(tO\w+?)_L\d+_T(\d+)J(\d+)S(\d+)$', 'tokens', 'once');
if ~isempty(crew)
    task = global_info.crewTasks.(crew{1});
    available = [ntokens('pOTrainee'), ntokens('pOJunior'), ntokens('pOSenior')];
    fire = isequal(str2double(crew(2:4)), ...
        pipe_yard_pick_crew(task.workers, task.minLevel, available));
    return
end

route = regexp(transition.name, '^tORoute(Next|Scrap|Pass|EasyRepair|HardRepair)(\d*)$', ...
    'tokens', 'once');
if ~isempty(route)
    step = str2double(route{2});
    if isnan(step)
        step = height(global_info.cfg.inspection.steps);
    end
    % Pipe tokens are identical, so one pending outcome per decision place
    % is drawn the first time any route out of it is tried.
    if isempty(global_info.pendingDecision{step})
        global_info.pendingDecision{step} = drawOutcome(step);
    end
    fire = strcmp(global_info.pendingDecision{step}, route{1});
    if fire
        global_info.pendingDecision{step} = '';
    end
end
end

function outcome = drawOutcome(step)
global global_info
cfg = global_info.cfg;
stepCount = height(cfg.inspection.steps);
scrap = cfg.scrapPercent / 100;
% Scrap is spread evenly over the steps: P(scrap at step k | survived k-1)
survivedSoFar = 1 - scrap * (step - 1) / stepCount;
if survivedSoFar > 0 && rand < (scrap / stepCount) / survivedSoFar
    outcome = 'Scrap';
elseif step < stepCount
    outcome = 'Next';
else
    survivors = 1 - scrap;
    easy = cfg.repair.easy.percent / 100 / survivors;
    hard = cfg.repair.hard.percent / 100 / survivors;
    r = rand;
    if r < easy
        outcome = 'EasyRepair';
    elseif r < easy + hard
        outcome = 'HardRepair';
    else
        outcome = 'Pass';
    end
end
end
