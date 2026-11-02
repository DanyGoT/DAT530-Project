function MOD_Operations_POST(transition)
global global_info

crew = regexp(transition.name, '^(tO\w+?)_L\d+_T(\d+)J(\d+)S(\d+)$', 'tokens', 'once');
if ~isempty(crew)
    task = global_info.crewTasks.(crew{1});
    global_info.workerBusyMinutes = global_info.workerBusyMinutes + ...
        str2double(crew(2:4)) * task.minutes;
    global_info.taskCounts.(crew{1}) = global_info.taskCounts.(crew{1}) + 1;
    return
end

route = regexp(transition.name, '^tORoute(Scrap)(\d+)$', 'tokens', 'once');
if ~isempty(route)
    step = str2double(route{2});
    global_info.scrapAtStep(step) = global_info.scrapAtStep(step) + 1;
end
end
