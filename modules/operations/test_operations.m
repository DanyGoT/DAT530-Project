clear all; clc;
run(fullfile(fileparts(mfilename('fullpath')), '..', '..', 'setup.m'));

pns = pnstruct('operations_pn_pdf');

dyn.m0 = {'pOInput',4};
pni = initialdynamics(pns, dyn); 

Sim_Results = gpensim(pni);
prnss(Sim_Results);
plotp(Sim_Results, {'pOInput', 'pOCleaning', 'pOInspection', 'pOOutput'});
