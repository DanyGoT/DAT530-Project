function root = trym_test_setup(gpensim)
% Add this experiment and shared original parameters/order helpers to the path.
if nargin < 1, gpensim = false; end
root = fileparts(mfilename('fullpath'));
project = fileparts(root);
addpath(genpath(root));
addpath(project, fullfile(project, 'lib'));
if gpensim
    addpath(genpath(fullfile(project, 'modules')));
    addpath(fullfile(project, 'imc'));
end
end
