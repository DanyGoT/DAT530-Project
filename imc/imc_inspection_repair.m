% PDF: imc_inspection_repair.m
%
% Inter-modular connector (IMC): Inspection <-> Repair
% pIRMach, pIRHb: joints for the workshops, coloured with their order.
% pRI: repaired joints to be inspected again. They are already clean, so
% they skip the wash.
function [png] = imc_inspection_repair()
png.PN_name = 'imc_inspection_repair';
png.set_of_Ps = {'pIRMach', 'pIRHb', 'pRI'};
png.set_of_Ts = {};
png.set_of_As = { ...
  'tIMach', 'pIRMach', 1, 'pIRMach', 'tRInMach', 1 ...
  'tIHb',   'pIRHb',   1, 'pIRHb',   'tRInHb',   1 ...
  'tRMachHall', 'pRI', 1, 'tRHbHall', 'pRI', 1, 'pRI', 'tIInRepair', 1 ...
 };
