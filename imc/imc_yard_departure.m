% PDF: imc_yard_departure.m
%
% Inter-modular connector (IMC): Yard -> Departure
% Only arcs: each module owns its input places, the IMC adds the arcs into them.

function [png] = imc_yard_departure()

png.PN_name = 'imc_yard_departure';
png.set_of_Ps = {};
png.set_of_Ts = {};
png.set_of_As = { ...
  'pYReady', 'tDShip', 1 ...  % ship from stock
 };
