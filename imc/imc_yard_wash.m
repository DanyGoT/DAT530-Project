% PDF: imc_yard_wash.m
%
% Inter-modular connector (IMC): Yard -> Washing
% pYW: hall joints on their way to the wash, coloured.
function [png] = imc_yard_wash()
png.PN_name = 'imc_yard_wash';
png.set_of_Ps = {'pYW'};
png.set_of_Ts = {};
png.set_of_As = {'tYLong', 'pYW', 1, 'tYShort', 'pYW', 1, 'pYW', 'tWIn', 1};
