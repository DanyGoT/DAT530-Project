clear all; clc;
global global_info
global_info.MAX_LOOP = 1000;
global_info.STOP_AT = 200;

pns = pnstruct('logistics_pn_pdf');

% tid det tar mellom yards (minutter)
distYard1 = 10;
distYard2 = 25;

dyn.m0 = {'pYard1',2, 'pYard2',2, 'pTruckAvailable',1, ...
          'pForkliftYard1',1, 'pForkliftYard2',1, 'pForkliftWorkshop',1};
dyn.ft = {'tDriveToYard1',distYard1, 'tDriveFromYard1',distYard1, ...
          'tDriveToYard2',distYard2, 'tDriveFromYard2',distYard2, ...
          'tLoad1',2, 'tLoad2',2, 'tUnload',2};
pni = initialdynamics(pns, dyn);

Sim_Results = gpensim(pni);
prnss(Sim_Results);
plotp(Sim_Results, {'pYard1', 'pYard2', 'pLogOutput'});
