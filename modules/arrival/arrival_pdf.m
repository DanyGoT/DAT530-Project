% PDF: arrival_pdf.m
%
% %%%%%%%   Arrival (module)
% Hands the joints in global_info.pipes to the yard one at a time, each when
% its time has come (MOD_Arrival_PRE). The joint's kind and yard pick the
% output port: tALong and tAShort for joints that need the hall, tABypass for
% storage only, all at Main; tACHall and tACBypass for receipts unloaded at
% Coop. Unloading is the yard's work (its input ports).
% The clock token loops back so the next joint can be handed over.
% Output ports: tALong, tAShort, tABypass, tACHall, tACBypass (colourless joints)

function [png] = arrival_pdf()

png.PN_name = 'Arrival';
png.set_of_Ps = {'pAClock'};
png.set_of_Ts = {'tALong', 'tAShort', 'tABypass', 'tACHall', 'tACBypass'};
png.set_of_As = { ...
  'pAClock', 'tALong',    1, 'tALong',    'pAClock', 1 ...
  'pAClock', 'tAShort',   1, 'tAShort',   'pAClock', 1 ...
  'pAClock', 'tABypass',  1, 'tABypass',  'pAClock', 1 ...
  'pAClock', 'tACHall',   1, 'tACHall',   'pAClock', 1 ...
  'pAClock', 'tACBypass', 1, 'tACBypass', 'pAClock', 1 ...
 };
png.set_of_Ports = png.set_of_Ts;
