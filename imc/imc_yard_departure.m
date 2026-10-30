% PDF: imc_yard_departure.m
%
% Inter-modular connector (IMC): Yard <-> Departure
% pDYOrder: one token per joint asked for and not yet loaded (unmet demand).
% pYDOut: loaded joints on their way out.
function [png] = imc_yard_departure()
png.PN_name = 'imc_yard_departure';
png.set_of_Ps = {'pDYOrder', 'pYDOut'};
png.set_of_Ts = {};
png.set_of_As = { ...
  'tDTicket', 'pDYOrder', 1, 'pDYOrder', 'tYOrder', 1 ...
  'tYShip',   'pYDOut',   1, 'pYDOut',   'tDShip', 1 ...
 };
