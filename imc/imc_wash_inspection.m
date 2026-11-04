% PDF: imc_wash_inspection.m
%
% Inter-modular connector (IMC): Washing -> Inspection, for each hall (hall_name)
% pWI: washed joints waiting for room on the hall floor.
function [png] = imc_wash_inspection()
global global_info
png.PN_name = 'imc_wash_inspection';
png.set_of_Ps = {};
png.set_of_Ts = {};
png.set_of_As = {};
for h = 1:global_info.P.halls
    n = @(name) hall_name(name, h);
    png.set_of_Ps{end+1} = n('pWI');
    png.set_of_As = [png.set_of_As, {n('tWOut'), n('pWI'), 1, n('pWI'), n('tIIn'), 1}];
end
