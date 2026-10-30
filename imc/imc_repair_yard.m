% PDF: imc_repair_yard.m
%
% Inter-modular connector (IMC): Repair -> Yard
% pRYReady: repaired joints that go straight to rig-ready stock.
function [png] = imc_repair_yard()
png.PN_name = 'imc_repair_yard';
png.set_of_Ps = {'pRYReady'};
png.set_of_Ts = {};
png.set_of_As = {'tRMachReady', 'pRYReady', 1, 'tRHbReady', 'pRYReady', 1, ...
                 'pRYReady', 'tYInRepaired', 1};
