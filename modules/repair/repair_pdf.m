% PDF: repair_pdf.m
%
% %%%%%%%   Repair (external workshops, module)
% Joints wait in pRMach (machining) or pRHb (hardbanding) for their order's
% repair time. Then they go through the hall again or straight to rig-ready
% stock; MOD_Repair_PRE decides. Any number of joints can be at the
% workshops at once, and the workshops don't stop at night.
% Input ports:  tRInMach, tRInHb (joints coloured with their order)
% Output ports: tRMachHall, tRHbHall   (to Inspection, coloured 'ok' 'repaired')
%               tRMachReady, tRHbReady (to the yard, colourless)

function [png] = repair_pdf()

png.PN_name = 'Repair';
png.set_of_Ps = {'pRMach', 'pRHb'};
png.set_of_Ts = {'tRInMach', 'tRInHb', 'tRMachHall', 'tRMachReady', 'tRHbHall', 'tRHbReady'};
png.set_of_As = {'tRInMach', 'pRMach', 1, 'tRInHb', 'pRHb', 1, ...
                 'pRMach', 'tRMachHall', 1, 'pRMach', 'tRMachReady', 1, ...
                 'pRHb',   'tRHbHall',   1, 'pRHb',   'tRHbReady',   1};
png.set_of_Ports = png.set_of_Ts;
