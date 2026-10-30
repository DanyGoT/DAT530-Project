% PDF: imc_wash_inspection.m
%
% Inter-modular connector (IMC): Washing -> Inspection
% pWI: washed joints waiting for room on the hall floor.
function [png] = imc_wash_inspection()
png.PN_name = 'imc_wash_inspection';
png.set_of_Ps = {'pWI'};
png.set_of_Ts = {};
png.set_of_As = {'tWOut', 'pWI', 1, 'pWI', 'tIIn', 1};
