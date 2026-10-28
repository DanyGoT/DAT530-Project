% PDF: imc_arrival_yard.m
%
% Inter-modular connector (IMC): Arrival -> Yard
% Only arcs: each module owns its input places, the IMC adds the arcs into them.

function [png] = imc_arrival_yard()

png.PN_name = 'imc_arrival_yard';
png.set_of_Ps = {};
png.set_of_Ts = {};
png.set_of_As = { ...
  'tALong',   'pYLong',  1 ...
  'tAShort',  'pYShort', 1 ...
  'tABypass', 'pYReady', 1 ...
 };
