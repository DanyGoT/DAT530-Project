function MOD_PipeLifecycle_POST(transition)
global global_info
parts = strsplit(transition.name, '_');
if ~ismember(parts{1}, {'tInspect', 'tReinspect'})
    return
end
cfg = global_info.lifecycleConfig;
worker = str2double(parts{3});
typeIndex = find(strcmp(parts{2}, cfg.pipeTypes), 1);
if strcmp(parts{1}, 'tInspect')
    thresholds = cumsum(cfg.inspectionProbabilities);
    thresholds(end) = 1;
    outcome = find(rand < thresholds, 1);
    global_info.lifecycleInspectionCounts(typeIndex, outcome) = ...
        global_info.lifecycleInspectionCounts(typeIndex, outcome) + 1;
else
    scrap = rand < cfg.reinspectionScrapProbability;
    outcome = 1 + 4*scrap;
    global_info.lifecycleReinspectionCounts(typeIndex, 1+scrap) = ...
        global_info.lifecycleReinspectionCounts(typeIndex, 1+scrap) + 1;
end
global_info.lifecycleOutcome(worker) = outcome;
end