% PDF: imc_yard_wash.m
%
% Inter-modular connector (IMC): Yard -> Washing, for each hall (hall_name)
% pYW: hall joints on their way to the wash, coloured.
function [png] = imc_yard_wash()
global global_info
png.PN_name = 'imc_yard_wash';
png.set_of_Ps = {};
png.set_of_Ts = {};
png.set_of_As = {};
for h = 1:global_info.P.halls
    n = @(name) hall_name(name, h);
    png.set_of_Ps{end+1} = n('pYW');
    png.set_of_As = [png.set_of_As, {n('tYLong'), n('pYW'), 1, n('tYShort'), n('pYW'), 1, n('pYW'), n('tWIn'), 1}];
end
