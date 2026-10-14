clear all; clc;
global global_info
global_info.MAX_LOOP = 1000;
global_info.STOP_AT = 200;

pns = pnstruct('logistics_pn_pdf');

% tid det tar mellom yards (minutter)
distYard1 = 10;
distYard2 = 25;

dyn.m0 = {'pLYard1',2, 'pLYard2',2, 'pLTruckAvailable',1, ...
          'pLForkliftYard1',1, 'pLForkliftYard2',1, 'pLForkliftWorkshop',1};
dyn.ft = {'tLDriveToYard1',distYard1, 'tLDriveFromYard1',distYard1, ...
          'tLDriveToYard2',distYard2, 'tLDriveFromYard2',distYard2, ...
          'tLLoad1',2, 'tLLoad2',2, 'tLUnload',2};
pni = initialdynamics(pns, dyn);

Sim_Results = gpensim(pni);
prnss(Sim_Results);
plotp(Sim_Results, {'pLYard1', 'pLYard2', 'pLOutput'});
