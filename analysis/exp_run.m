function Y = exp_run(tag, seed, days, varargin)
% One run of an experiment: the parameters of params.m, seed seed, days
% days, with any number of changes as name/value pairs, e.g.
%   exp_run('crew8', 1, 7, 'crew', [2 4 1 1])
% Saves results/experiments/<tag>_s<seed>.mat (Y, R, P, the changes and the
% git commit) and <tag>_s<seed>.csv, one row: tag, seed, days and each
% output in Y. The model is run and measured by run_model. Each run starts a
% fresh MATLAB (run_experiments.sh).

P = params();
P.seed = seed;
P.days = days;
changes = varargin;
for k = 1:2:numel(changes)
    assert(isfield(P, changes{k}), ['no parameter ', changes{k}]);
    P.(changes{k}) = changes{k+1};
end

[Y, R] = run_model(P);

root = fileparts(fileparts(mfilename('fullpath')));
[~, commit] = system(['git -C "', root, '" rev-parse --short HEAD']);
[~, dirty] = system(['git -C "', root, '" status --porcelain --untracked-files=no']);
commit = strtrim(commit);
if not(isempty(strtrim(dirty))), commit = [commit, '+dirty']; end

folder = fullfile(root, 'results', 'experiments');
if not(isfolder(folder)), mkdir(folder); end
name = fullfile(folder, sprintf('%s_s%d', tag, seed));
save([name, '.mat'], 'Y', 'R', 'P', 'tag', 'seed', 'changes', 'commit');
row = [table(string(tag), seed, days, string(commit), 'VariableNames', {'tag', 'seed', 'days', 'commit'}), ...
       struct2table(Y)];
writetable(row, [name, '.csv']);
disp(Y);
