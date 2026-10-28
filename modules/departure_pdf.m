% PDF: departure_pdf.m
%
% %%%%%%%   Departure
% tDTicket turns global_info.demand into demand tokens, one per joint, each
% when its time has come (COMMON_PRE). tDShip ships one stock joint per demand token.

function [png] = departure_pdf()

png.PN_name = 'Departure';
png.set_of_Ps = {'pDClock', 'pDDemand', 'pDShipped'};
png.set_of_Ts = {'tDTicket', 'tDShip'};
png.set_of_As = { ...
  'pDClock',  'tDTicket', 1, 'tDTicket', 'pDClock',   1, 'tDTicket', 'pDDemand', 1 ...
  'pDDemand', 'tDShip',   1, 'tDShip',   'pDShipped', 1 ...
 };
