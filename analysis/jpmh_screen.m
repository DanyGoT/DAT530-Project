% Joints per man-hour at most, from the crew bound (crew_bound.m), for every
% crew mix of 5-8 people under each automation option. Man-hours count the
% whole crew, wash included, as the company's KPI does (target 4.0). No
% simulation; seconds. Writes results/experiments/jpmh_screen.csv, and
% prints the best mix of 7 and of 6 people for each option. "steps" counts
% the training it takes from today's crew: one person up one level is one
% step (an L0 who leaves counts as the steps of the people left).

clear all; clc;

autos = {{}, {'Clean'}, {'Finish'}, {'Clean', 'Finish'}, {'Wash'}, {'UT'}, ...
         {'Clean', 'Finish', 'Wash'}, {'Clean', 'Finish', 'Wash', 'UT'}};
P0 = params();
rows = {};
for a = 1:numel(autos)
    for c = combos()'
        P = P0;
        P.crew = c';
        P.auto = autos{a};
        if P.crew(4) == 0 && not(ismember('UT', P.auto)), continue, end   % no one for UT
        B = crew_bound(P);
        hours = sum(P.crew) * 5 * diff(P.shift) / 60;
        moved = sum(abs(cumsum(P.crew, 'reverse') - cumsum(P0.crew, 'reverse')));  % level steps up or down
        rows(end+1, :) = {strjoin([{'none'}, autos{a}], '+'), mat2str(P.crew), sum(P.crew), ...
                          B.bound, B.bound / hours, B.minutes, moved};
    end
end
T = cell2table(rows, 'VariableNames', {'auto', 'crew', 'people', 'bound', 'jpmh', 'crew_min_per_joint', 'moved'});
T.auto = strrep(T.auto, 'none+', '');
writetable(T, fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results', 'experiments', 'jpmh_screen.csv'));

base = crew_bound(P0);
fprintf('Today [%s]: %.0f a week, %.2f joints per man-hour at most (%.1f crew min a joint)\n\n', ...
        num2str(P0.crew), base.bound, base.bound / (sum(P0.crew)*5*diff(P0.shift)/60), base.minutes);
fprintf('%-24s %-10s %6s %6s %5s   %-10s %6s %6s %5s\n', 'automated', '7 people', '/week', 'jpmh', 'steps', ...
        '6 people', '/week', 'jpmh', 'steps');
for a = unique(T.auto, 'stable')'
    s = T(strcmp(T.auto, a{1}), :);
    b7 = best(s(s.people == 7, :));
    b6 = best(s(s.people == 6, :));
    fprintf('%-24s %-10s %6.0f %6.2f %5d   %-10s %6.0f %6.2f %5d\n', a{1}, b7.crew{1}, b7.bound, b7.jpmh, ...
            b7.moved, b6.crew{1}, b6.bound, b6.jpmh, b6.moved);
end


function C = combos()
% Crew mixes [L0 L1 L2 L3] of 5-8 people, at least one at L1 and at L2 or L3.
C = [];
for L0 = 0:3, for L1 = 1:5, for L2 = 0:2, for L3 = 0:2
    c = [L0 L1 L2 L3];
    if sum(c) >= 5 && sum(c) <= 8 && L2 + L3 > 0, C(end+1, :) = c; end
end, end, end, end
end


function r = best(s)
% The mix with the most joints per man-hour (to 0.01); ties go to the mix
% closest to today's (fewest level steps of training), then the most joints.
s.j = round(s.jpmh, 2);
s = sortrows(s, {'j', 'moved', 'bound'}, {'descend', 'ascend', 'descend'});
r = s(1, :);
end
