function [fire, transition] = MOD_Operations_PRE(transition)
global global_info

fire = true;
routeNames = {'tOPass', 'tOMinor', 'tOModerate', 'tOMajor', 'tOScrap'};
routeIndex = find(strcmp(transition.name, routeNames), 1);
if ~isempty(routeIndex)
    fire = global_info.inspectionOutcome == routeIndex;
elseif strcmp(transition.name, 'tORePass')
    fire = ~global_info.reinspectionScrap;
elseif strcmp(transition.name, 'tOReScrap')
    fire = global_info.reinspectionScrap;
end

repairMatch = regexp(transition.name, '^tR(Minor|Moderate|Major)L([123])$', 'tokens', 'once');
if ~isempty(repairMatch)
    repairNames = {'Minor', 'Moderate', 'Major'};
    requiredLevel = find(strcmp(repairMatch{1}, repairNames), 1);
    workerLevel = str2double(repairMatch{2});
    for lowerLevel = requiredLevel:workerLevel-1
        if tokenAny(sprintf('pRWorkerL%d', lowerLevel), 1)
            fire = false;
            break
        end
    end
end
end