% PDF: imc_wash_inspection.m
%
% Inter-modular connector (IMC): Washing -> Inspection
% Only arcs: each module owns its input places, the IMC adds the arcs into them.
% A joint is only washed when there is room for it on the hall floor (pISpace).

function [png] = imc_wash_inspection()

global global_info
first = global_info.S(1).place;

png.PN_name = 'imc_wash_inspection';
png.set_of_Ps = {};
png.set_of_Ts = {};
png.set_of_As = { ...
  'pISpace', 'tWLong',  1, 'tWLong',  first, 1 ...
  'pISpace', 'tWShort', 1, 'tWShort', first, 1 ...
 };
