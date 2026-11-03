function Y = sens_run(tag, seed, field, value, days)
% One run of the model for the sensitivity analysis (sensitivity.m): the
% parameters of params.m with P.(field) = value (no change if field is
% ''), seed seed. Saves the outputs Y to results/sensitivity/<tag>_s<seed>.mat
% and returns them. Each run starts a fresh MATLAB (run_sensitivity.sh).
% The model is run and measured by run_model.

P = params();
P.seed = seed;
if nargin >= 5, P.days = days; end
if not(isempty(field)), P.(field) = value; end

Y = run_model(P);

folder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results', 'sensitivity');
if not(isfolder(folder)), mkdir(folder); end
save(fullfile(folder, sprintf('%s_s%d.mat', tag, seed)), 'Y', 'tag', 'seed', 'field', 'value', 'P');
disp(Y);
