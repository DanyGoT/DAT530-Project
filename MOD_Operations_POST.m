function MOD_Operations_POST(transition)
global global_info

if strcmp(transition.name, 'tOInspect')
    global_info.inspectionOutcome = find( ...
        rand < cumsum(global_info.inspectionProbabilities), 1);
    global_info.inspectionCounts(global_info.inspectionOutcome) = ...
        global_info.inspectionCounts(global_info.inspectionOutcome) + 1;
elseif strcmp(transition.name, 'tOReinspect')
    global_info.reinspectionScrap = rand < global_info.reinspectionScrapProbability;
    global_info.reinspectionCounts(1 + global_info.reinspectionScrap) = ...
        global_info.reinspectionCounts(1 + global_info.reinspectionScrap) + 1;
end
end