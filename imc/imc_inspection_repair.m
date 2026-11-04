% PDF: imc_inspection_repair.m
%
% Inter-modular connector (IMC): Inspection <-> Repair
% pIRMach, pIRHb: joints for the workshops, coloured with their order, from
% every hall.
% pRI: repaired joints to be inspected again. They are already clean, so
% they skip the wash. With two halls, whichever hall has room first.
function [png] = imc_inspection_repair()
global global_info
png.PN_name = 'imc_inspection_repair';
png.set_of_Ps = {'pIRMach', 'pIRHb', 'pRI'};
png.set_of_Ts = {};
png.set_of_As = {'pIRMach', 'tRInMach', 1, 'pIRHb', 'tRInHb', 1, ...
                 'tRMachHall', 'pRI', 1, 'tRHbHall', 'pRI', 1};
for h = 1:global_info.P.halls
    n = @(name) hall_name(name, h);
    png.set_of_As = [png.set_of_As, {n('tIMach'), 'pIRMach', 1, n('tIHb'), 'pIRHb', 1, 'pRI', n('tIInRepair'), 1}];
end
