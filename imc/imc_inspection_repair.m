% PDF: imc_inspection_repair.m
%
% Inter-modular connector (IMC): Inspection <-> Repair
% Only arcs: each module owns its input places, the IMC adds the arcs into them.
% Repaired joints are already clean: those inspected again go straight back
% onto the hall floor.

function [png] = imc_inspection_repair()

global global_info
first = global_info.S(1).place;

png.PN_name = 'imc_inspection_repair';
png.set_of_Ps = {};
png.set_of_Ts = {};
png.set_of_As = { ...
  'tIMach', 'pRMach', 1, 'tIHb', 'pRHb', 1 ...
  'pISpace', 'tRMachHall', 1, 'tRMachHall', first, 1 ...
  'pISpace', 'tRHbHall',   1, 'tRHbHall',   first, 1 ...
 };
