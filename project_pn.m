% Example-01: A Simple Ordinary Petri Net 
% the main simulation file (MSF) to run simulation 

clear all; clc; 
global global_info
global_info.MAX_LOOP = 15;

pns = pnstruct('operations_pn_pdf');


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%   Operasjonell avdeling
% Input buffer
% Cleaning buffer
% Cleaning transition
% Cleaning to inspection transition
% Inspection buffer
% Inspection transition
% Inspection to output transition
% Output buffer


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%   Logistikk avdeling
% Input buffer
% 


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%   IT avdeling
% 


dyn.m0 = {'pInput',4};
pni = initialdynamics(pns, dyn); 

Sim_Results = gpensim(pni); % perform simulation runs
prnss(Sim_Results);  % print the simulation results 
plotp(Sim_Results, {'pInput', 'pCleaning', 'pInspection', 'pOutput'}); % plot the results