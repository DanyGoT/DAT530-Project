clear all; clc;

global global_info
global_info = struct();
global_info.MAX_LOOP = 20000;
global_info.STOP_AT = 600;
rng(0, 'twister');

dyn = operations_dynamics();
pns = pnstruct({'operations_pn_pdf', 'logistics_pn_pdf', 'imc_lo_pdf'});
pipeCount = 8;
dyn.m0 = [dyn.m0, {'pIMC_LO', pipeCount}];
pni = initialdynamics(pns, dyn); 

Sim_Results = gpensim(pni);
placeNames = {Sim_Results.global_places.name};
marking = @(name) Sim_Results.X(strcmp(placeNames, name));
assert(marking('pOOutput') + marking('pOScrap') == pipeCount, ...
	'Pipes remain unfinished; increase STOP_AT or check resource availability.');
assert(sum(global_info.inspectionCounts) == pipeCount);
assert(sum(global_info.reinspectionCounts) == sum(global_info.inspectionCounts(2:4)));
resourceNames = {'pOInspector', 'pRStation', 'pRTransport', ...
		   'pRWorkerL1', 'pRWorkerL2', 'pRWorkerL3'};
for resourceIndex = 1:numel(resourceNames)
    resourceName = resourceNames{resourceIndex};
    initialIndex = find(strcmp(dyn.m0(1:2:end), resourceName), 1);
    assert(marking(resourceName) == dyn.m0{2*initialIndex}, ...
	    ['Resource not released: ' resourceName]);
end
prnss(Sim_Results);
disp('Initial inspection counts: pass, minor, moderate, major, scrap');
disp(global_info.inspectionCounts);
disp('Reinspection counts: pass, scrap');
disp(global_info.reinspectionCounts);
plotp(Sim_Results, {'pIMC_LO', 'pOOutput', 'pOScrap', ...
				   'pORepairMinor', 'pORepairModerate', 'pORepairMajor'});
