% PDF: repair_pdf.m
%
% %%%%%%%   Repair (external workshops)
% Joints wait in pRMach (machining) or pRHb (hardbanding) for their repair
% time. tRMach / tRHb release the oldest one when its time is up (COMMON_PRE),
% so any number of joints can be at the workshops at once.

function [png] = repair_pdf()

png.PN_name = 'Repair';
png.set_of_Ps = {'pRMach', 'pRHb'};
png.set_of_Ts = {'tRMach', 'tRHb'};
png.set_of_As = {'pRMach', 'tRMach', 1, 'pRHb', 'tRHb', 1};
