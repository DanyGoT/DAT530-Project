% PDF: departure_pdf.m
%
% %%%%%%%   Departure (module)
% tDTicket turns global_info.demand into orders for the yard, one token per
% joint asked for, each when its time has come (MOD_Departure_PRE).
% tDShip takes the joints the yard has loaded.
% Output port: tDTicket (one colourless token per joint asked for)
% Input port:  tDShip   (colourless joints)

function [png] = departure_pdf()

png.PN_name = 'Departure';
png.set_of_Ps = {'pDClock', 'pDShipped'};
png.set_of_Ts = {'tDTicket', 'tDShip'};
png.set_of_As = { ...
  'pDClock', 'tDTicket', 1, 'tDTicket', 'pDClock', 1 ...
  'tDShip',  'pDShipped', 1 ...
 };
png.set_of_Ports = {'tDTicket', 'tDShip'};
