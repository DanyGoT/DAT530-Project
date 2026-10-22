clear all; clc;
run(fullfile(fileparts(mfilename('fullpath')), '..', '..', 'setup.m'));
global global_info
global_info.MAX_LOOP = 1000;
global_info.STOP_AT = 200;

pns = pnstruct('logistics_pn_pdf');

% tid det tar mellom yards (minutter)
distYard1 = 10;
distYard2 = 25;

dyn.m0 = {Lgs.pYard1,2, Lgs.pYard2,2, Lgs.pTruckAvailable,1, ...
          Lgs.pForkliftYard1,1, Lgs.pForkliftYard2,1, Lgs.pForkliftWorkshop,1};
dyn.ft = {Lgs.tDriveToYard1,distYard1, Lgs.tDriveFromYard1,distYard1, ...
          Lgs.tDriveToYard2,distYard2, Lgs.tDriveFromYard2,distYard2, ...
          Lgs.tLoad1,2, Lgs.tLoad2,2, Lgs.tUnload,2};
pni = initialdynamics(pns, dyn);

Sim_Results = gpensim(pni);
prnss(Sim_Results);
plotp(Sim_Results, {Lgs.pYard1, Lgs.pYard2, Lgs.pOutput});
