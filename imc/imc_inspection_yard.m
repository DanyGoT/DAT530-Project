% PDF: imc_inspection_yard.m
%
% Inter-modular connector (IMC): Inspection -> Yard
% Only arcs: each module owns its input places, the IMC adds the arcs into them.

function [png] = imc_inspection_yard()

png.PN_name = 'imc_inspection_yard';
png.set_of_Ps = {};
png.set_of_Ts = {};
png.set_of_As = { ...
  'tIOk',    'pYReady', 1 ...
  'tIScrap', 'pYScrap', 1 ...
 };
