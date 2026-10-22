% setup.m: put the project folders on the MATLAB path.
% Run from anywhere: the main file and tests call it first.

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'lib'), fullfile(root, 'imc'), genpath(fullfile(root, 'modules')));
clear root
