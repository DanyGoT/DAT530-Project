% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%   IT avdeling test

clear all; clc;
run(fullfile(fileparts(mfilename('fullpath')), '..', '..', 'setup.m'));

pns = pnstruct('it_pn_pdf');

dyn.m0 = {IT.pNewOrders, 10};
pni = initialdynamics(pns, dyn);

Sim_Results = gpensim(pni);
prnss(Sim_Results);
plotp(Sim_Results, {IT.pNewOrders, IT.pOngoingOrders, IT.pCompletedOrders});
