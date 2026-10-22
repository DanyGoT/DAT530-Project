function dyn = operations_dynamics()
global global_info

global_info.inspectionProbabilities = [0.65, 0.20, 0.08, 0.04, 0.03];
global_info.reinspectionScrapProbability = 0.05;
global_info.inspectionOutcome = 0;
global_info.reinspectionScrap = false;
global_info.inspectionCounts = zeros(1, 5);
global_info.reinspectionCounts = zeros(1, 2);

workerCounts = [1, 1, 1];
repairMinutes = [15, 60, 180];
transportMinutes = 5;

dyn.m0 = {'pOInspector', 1, 'pRStation', 1, 'pRTransport', 1, ...
          'pRWorkerL1', workerCounts(1), 'pRWorkerL2', workerCounts(2), ...
          'pRWorkerL3', workerCounts(3)};
dyn.ft = {'tOClean', 2, 'tOInspect', 3, 'tOReinspect', 3, ...
          'tRReturn', transportMinutes, 'allothers', 0.1};
repairNames = {'Minor', 'Moderate', 'Major'};
for difficulty = 1:numel(repairNames)
    dyn.ft = [dyn.ft, {['tRTransport' repairNames{difficulty}], transportMinutes}];
    for workerLevel = difficulty:3
        dyn.ft = [dyn.ft, ...
            {sprintf('tR%sL%d', repairNames{difficulty}, workerLevel), ...
             repairMinutes(difficulty)}];
    end
end
end