% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%   IT avdeling test

clear all; clc;

pns = pnstruct('it_pn_pdf');

dyn.m0 = {'pNewOrders', 10};
pni = initialdynamics(pns, dyn);

Sim_Results = gpensim(pni);
prnss(Sim_Results);
plotp(Sim_Results, {'pNewOrders', 'pOngoingOrders', 'pCompletedOrders'});
