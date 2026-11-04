% What the crew bound (crew_bound.m) predicts for each scenario, before
% running it: joints a week at most, and what sets the limit. No
% simulation; seconds. Writes results/experiments/scenario_bounds.csv.

clear all; clc;

scenarios = {
  'base',        {}
  'floor50',     {'hall_space', 50}
  'floor90',     {'hall_space', 90}
  'crew8',       {'crew', [2 4 1 1]}
  'overtime',    {'shift', [7 17]*60}
  'lanes3',      {'wash_lanes', 3}
  'auto_clean',  {'auto', {'Clean'}}
  'auto_finish', {'auto', {'Finish'}}
  'auto_both',   {'auto', {'Clean', 'Finish'}}
  'auto_wash',   {'auto', {'Wash'}}
  'auto_ut',     {'auto', {'UT'}}
  'noL3',        {'crew', [2 3 1 0]}
  'L2toL3',      {'crew', [2 3 0 2]}
};
limits = {'whole crew', 'L1+', 'L2+', 'L3', 'wash lanes', 'machine'};

rows = {};
base = nan;
fprintf('%-12s %8s %8s %8s  %s\n', 'scenario', 'bound', 'vs base', 'min/jt', 'limit');
for k = 1:size(scenarios, 1)
    P = params();
    c = scenarios{k, 2};
    for i = 1:2:numel(c), P.(c{i}) = c{i+1}; end
    B = crew_bound(P);
    [~, at] = min([B.level, B.wash_cap, B.machine]);
    if k == 1, base = B.bound; end
    fprintf('%-12s %8.0f %+7.1f%% %8.1f  %s\n', scenarios{k, 1}, B.bound, 100*(B.bound/base - 1), ...
            B.minutes, limits{at});
    rows(end+1, :) = {scenarios{k, 1}, B.bound, 100*(B.bound/base - 1), B.minutes, limits{at}, ...
                      B.level(1), B.level(2), B.level(3), B.level(4), B.wash_cap, B.machine};
end
T = cell2table(rows, 'VariableNames', {'scenario', 'bound', 'gain_pct', 'crew_min_per_joint', 'limit', ...
                                       'bound_L0', 'bound_L1', 'bound_L2', 'bound_L3', 'wash_cap', 'machine'});
writetable(T, fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results', 'experiments', 'scenario_bounds.csv'));
