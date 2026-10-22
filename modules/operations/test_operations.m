clear all; clc;
run(fullfile(fileparts(mfilename('fullpath')), '..', '..', 'setup.m'));
global global_info
global_info.MAX_LOOP = 30;  % tInput has no input place here, so it fires forever

pns = pnstruct('operations_pn_pdf');

net = Ops.net;
dyn.ft = [{Ops.tInput,1, Ops.tOutput,1}, each(net.t.Clean, 2), each(net.t.Inspect, 5)];
pni = initialdynamics(pns, dyn);

Sim_Results = gpensim(pni);
prnss(Sim_Results);
plotp(Sim_Results, {net.p.Clean, net.p.Inspect, Ops.pDone});
