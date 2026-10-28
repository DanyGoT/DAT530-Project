% PDF: arrival_pdf.m
%
% %%%%%%%   Arrival
% Unloads the joints in global_info.pipes one at a time, each when its time
% has come (COMMON_PRE). The joint's kind picks the transition: tALong and
% tAShort for joints that need the hall, tABypass for storage only.
% The clock token loops back so the next joint can be unloaded.

function [png] = arrival_pdf()

png.PN_name = 'Arrival';
png.set_of_Ps = {'pAClock'};
png.set_of_Ts = {'tALong', 'tAShort', 'tABypass'};
png.set_of_As = { ...
  'pAClock', 'tALong',   1, 'tALong',   'pAClock', 1 ...
  'pAClock', 'tAShort',  1, 'tAShort',  'pAClock', 1 ...
  'pAClock', 'tABypass', 1, 'tABypass', 'pAClock', 1 ...
 };
