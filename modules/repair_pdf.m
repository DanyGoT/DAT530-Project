% PDF: repair_pdf.m
%
% %%%%%%%   Repair (external workshops)
% Joints wait in pRMach (machining) or pRHb (hardbanding) for their order's
% repair time. Then they go through the hall again (tRMachHall, tRHbHall) or
% straight to rig-ready stock (tRMachReady, tRHbReady); COMMON_PRE decides.
% Any number of joints can be at the workshops at once.

function [png] = repair_pdf()

png.PN_name = 'Repair';
png.set_of_Ps = {'pRMach', 'pRHb'};
png.set_of_Ts = {'tRMachHall', 'tRMachReady', 'tRHbHall', 'tRHbReady'};
png.set_of_As = {'pRMach', 'tRMachHall', 1, 'pRMach', 'tRMachReady', 1, ...
                 'pRHb',   'tRHbHall',   1, 'pRHb',   'tRHbReady',   1};
