% PDF: imc_repair_yard.m
%
% Inter-modular connector (IMC): Repair -> Yard
% Only arcs: each module owns its input places, the IMC adds the arcs into them.

function [png] = imc_repair_yard()

png.PN_name = 'imc_repair_yard';
png.set_of_Ps = {};
png.set_of_Ts = {};
png.set_of_As = { ...
  'tRMachReady', 'pYReady', 1 ...
  'tRHbReady',   'pYReady', 1 ...
 };
