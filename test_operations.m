clear all; clc;

dyn.m0 = {'pInput',4};
pni = initialdynamics(pns, dyn); 

Sim_Results = gpensim(pni);
prnss(Sim_Results);
plotp(Sim_Results, {'pInput', 'pCleaning', 'pInspection', 'pOutput'});
