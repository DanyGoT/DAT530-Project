% PDF: operations_pn_pdf.m
%
% %%%%%%%   Operasjonell avdeling
% Washing:    pIReadyForWash -> pOWashed (frees yard space)
% Inspection: pIReadyForInspection -> step 1 -> ... -> step N
%   After every step a decision place routes the pipe:
%     tORouteNext<k>  : continue to the next step
%     tORouteScrap<k> : scrapped, leaves inspection early (pOScrap)
%   After the last step: tORoutePass / tORouteEasyRepair / tORouteHardRepair
% Repair:     pIReadyForEasy/HardRepair -> pORepaired
%
% Workers are tokens in pOTrainee / pOJunior / pOSenior and are shared by all
% tasks. Crew transitions are named <task>_L<lane>_T<n>J<n>S<n>; one variant
% exists per allowed crew mix, and MOD_Operations_PRE lets only the cheapest
% qualified crew fire. Lanes allow the same task to run on several pipes at
% once (GPenSIM transitions are single-server).

function [pns] = operations_pn_pdf()
global global_info
cfg = global_info.cfg;
staff = [cfg.workers.trainee, cfg.workers.junior, cfg.workers.senior];
steps = cfg.inspection.steps;
stepCount = height(steps);

pns.PN_name = 'Operations';
pns.set_of_Ps = {'pOTrainee', 'pOJunior', 'pOSenior', 'pOWashBay', 'pOWashed', ...
    'pOInspStation', 'pOPassed', 'pOEasyRepair', 'pOHardRepair', ...
    'pORepairStation', 'pORepaired', 'pOScrap'};
pns.set_of_Ts = {};
pns.set_of_As = {};
pns.set_of_Ports = {};

% Washing
addCrewTask('tOWash', cfg.washing.bays, cfg.washing.workers, cfg.washing.difficulty, ...
    {'pIReadyForWash', 1, 'pOWashBay', 1}, ...
    {'pOWashed', 1, 'pOWashBay', 1, 'pLYardSpace', 1}, true);

% Inspection
addTask('tOStartInspection', {'pIReadyForInspection', 1, 'pOInspStation', 1}, ...
    {'pOStep1', 1}, true);
for step = 1:stepCount
    queue = sprintf('pOStep%d', step);
    decision = sprintf('pODecision%d', step);
    pns.set_of_Ps = [pns.set_of_Ps, {queue, decision}];
    addCrewTask(sprintf('tOStep%d', step), cfg.inspection.stations, ...
        steps.Workers(step), steps.Difficulty{step}, {queue, 1}, {decision, 1}, false);
    addTask(sprintf('tORouteScrap%d', step), {decision, 1}, ...
        {'pOScrap', 1, 'pOInspStation', 1}, false);
    if step < stepCount
        addTask(sprintf('tORouteNext%d', step), {decision, 1}, ...
            {sprintf('pOStep%d', step + 1), 1}, false);
    end
end
finalDecision = sprintf('pODecision%d', stepCount);
addTask('tORoutePass', {finalDecision, 1}, {'pOPassed', 1, 'pOInspStation', 1}, false);
addTask('tORouteEasyRepair', {finalDecision, 1}, {'pOEasyRepair', 1, 'pOInspStation', 1}, false);
addTask('tORouteHardRepair', {finalDecision, 1}, {'pOHardRepair', 1, 'pOInspStation', 1}, false);

% Repair
addCrewTask('tORepairEasy', cfg.repair.stations, cfg.repair.easy.workers, cfg.repair.easy.difficulty, ...
    {'pIReadyForEasyRepair', 1, 'pORepairStation', 1}, {'pORepaired', 1, 'pORepairStation', 1}, true);
addCrewTask('tORepairHard', cfg.repair.stations, cfg.repair.hard.workers, cfg.repair.hard.difficulty, ...
    {'pIReadyForHardRepair', 1, 'pORepairStation', 1}, {'pORepaired', 1, 'pORepairStation', 1}, true);

    function addCrewTask(task, stations, workers, difficulty, inputs, outputs, isPort)
        minLevel = pipe_yard_level(difficulty);
        crews = pipe_yard_crews(workers, minLevel, staff);
        assert(~isempty(crews), '%s needs %d %s+ worker(s), but not enough are staffed.', ...
            task, workers, difficulty);
        % More lanes than this can never be busy at the same time
        eligible = sum(staff(minLevel:end));
        lanes = min(stations, floor(eligible / workers));
        for lane = 1:lanes
            for row = 1:size(crews, 1)
                crew = crews(row, :);
                name = sprintf('%s_L%d_T%dJ%dS%d', task, lane, crew);
                workerArcs = {'pOTrainee', crew(1), 'pOJunior', crew(2), 'pOSenior', crew(3)};
                addTask(name, [inputs, workerArcs], [outputs, workerArcs], isPort);
            end
        end
    end

    function addTask(name, inputs, outputs, isPort)
        pns.set_of_Ts{end+1} = name;
        pns.set_of_As = [pns.set_of_As, pipe_yard_task(name, inputs, outputs)];
        if isPort
            pns.set_of_Ports{end+1} = name;
        end
    end
end
