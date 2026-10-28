% PDF: imc_inspection_repair.m
%
% Inter-modular connector (IMC): Inspection <-> Repair
% Only arcs: each module owns its input places, the IMC adds the arcs into them.
% Repaired joints are already clean: they go straight back onto the hall floor.

function [png] = imc_inspection_repair()

global global_info
first = global_info.S(1).place;

png.PN_name = 'imc_inspection_repair';
png.set_of_Ps = {};
png.set_of_Ts = {};
png.set_of_As = { ...
  'tIMach', 'pRMach', 1, 'tIHb', 'pRHb', 1 ...
  'pISpace', 'tRMach', 1, 'tRMach', first, 1 ...
  'pISpace', 'tRHb',   1, 'tRHb',   first, 1 ...
 };
