% Local sensitivity analysis (P3-L11): one parameter at a time, about +20%
% (crew: one person more), against the baseline of params.m. Reads the runs
% of run_sensitivity.sh from results/sensitivity/.
%
%   S = (dY/Y) / (dtheta/theta)
%
% per seed, then the mean and spread over the seeds. Every run with the same
% seed starts from the same arrivals, backlog and demand, so most of the
% week-to-week noise cancels in dY. A coefficient smaller than its spread is
% noise. An output that is 0 in the baseline has no coefficient (NaN).

clear all; clc;

folder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results', 'sensitivity');
files = dir(fullfile(folder, '*_s*.mat'));
outs = {'inspected', 'per_hour', 'busy', 'yard_queue', 'waiting', 'free_floor', 'unmet', 'fork_busy', 'gate'};
base = params();

R = arrayfun(@(f) load(fullfile(folder, f.name)), files)';
tag = {R.tag};
seed = [R.seed];
Y = cell2mat(arrayfun(@(r) cellfun(@(o) r.Y.(o), outs), R', 'UniformOutput', false));

isbase = strcmp(tag, 'base');
fprintf('Baseline, seeds %s: mean (sd)\n', mat2str(seed(isbase)));
for o = 1:numel(outs)
    fprintf('  %-11s %9.2f (%.2f)\n', outs{o}, mean(Y(isbase, o)), std(Y(isbase, o)));
end

params_ = setdiff(unique(tag, 'stable'), {'base'}, 'stable');
Smean = nan(numel(params_), numel(outs));
Ssd = Smean;
rel = nan(numel(params_), 1);
for k = 1:numel(params_)
    i = find(strcmp(tag, params_{k}));
    i = i(ismember(seed(i), seed(isbase)));
    if isempty(i), continue, end
    b = arrayfun(@(s) find(isbase & seed == s), seed(i));   % the baseline run with the same seed
    th0 = base.(R(i(1)).field);
    th = R(i(1)).value;
    j = find(th ~= th0);                          % the element that changed (crew)
    rel(k) = (th(j) - th0(j)) / th0(j);
    S = (Y(i, :) - Y(b, :)) ./ Y(b, :) / rel(k);
    S(Y(b, :) == 0) = nan;
    Smean(k, :) = mean(S, 1);
    Ssd(k, :) = std(S, 0, 1);
end

fprintf('\nSensitivity coefficients S, mean (sd) over seeds:\n%-12s %6s', 'parameter', 'dθ/θ');
fprintf(' %16s', outs{:}); fprintf('\n');
for k = 1:numel(params_)
    fprintf('%-12s %+5.0f%%', params_{k}, 100*rel(k));
    fprintf(' %7.2f (%6.2f)', [Smean(k, :); Ssd(k, :)]);
    fprintf('\n');
end
T = array2table(Smean, 'RowNames', params_, 'VariableNames', outs);
Tsd = array2table(Ssd, 'RowNames', params_, 'VariableNames', outs);
save(fullfile(folder, 'coefficients.mat'), 'T', 'Tsd', 'rel');
