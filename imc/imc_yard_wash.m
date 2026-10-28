% PDF: imc_yard_wash.m
%
% Inter-modular connector (IMC): Yard -> Washing
% Only arcs: each module owns its input places, the IMC adds the arcs into them.
% The inhibitor arcs stop the yard while P.wash_buffer joints wait at the wash.

function [png] = imc_yard_wash()

global global_info
n = global_info.P.wash_buffer;

png.PN_name = 'imc_yard_wash';
png.set_of_Ps = {};
png.set_of_Ts = {};
png.set_of_As = {'tYLong', 'pWBuf', 1, 'tYShort', 'pWBuf', 1};
png.set_of_Is = {'pWBuf', 'tYLong', n, 'pWBuf', 'tYShort', n};
