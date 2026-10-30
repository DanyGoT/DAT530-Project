% PDF: yard_pdf.m
%
% %%%%%%%   Yard (module)
% pYLong / pYShort - joints waiting for the hall, by length (racks by type)
% pYReady          - rig-ready stock
% pYScrap          - scrap
% pYRoom           - credits: room in front of the hall (P.hall_buffer)
% pYOrder          - joints asked for and not yet loaded
% Joints in the yard carry no colours.
% Input ports:  tYInLong, tYInShort, tYInBypass  (from Arrival)
%               tYInOk, tYInScrap                (from Inspection)
%               tYInRepaired                     (from Repair, rig-ready)
%               tYRoom   (a credit handed back by the hall)
%               tYOrder  (one joint asked for, from Departure)
% Output ports: tYLong, tYShort - the next hall joint to the wash; each
%               spends a credit
%               tYShip - one stock joint per joint asked for (Departure)

function [png] = yard_pdf()

png.PN_name = 'Yard';
png.set_of_Ps = {'pYLong', 'pYShort', 'pYReady', 'pYScrap', 'pYRoom', 'pYOrder'};
png.set_of_Ts = {'tYInLong', 'tYInShort', 'tYInBypass', 'tYInOk', 'tYInScrap', 'tYInRepaired', ...
                 'tYRoom', 'tYOrder', 'tYLong', 'tYShort', 'tYShip'};
png.set_of_As = { ...
  'tYInLong',  'pYLong',  1, 'tYInShort', 'pYShort', 1, 'tYInBypass',   'pYReady', 1 ...
  'tYInOk',    'pYReady', 1, 'tYInScrap', 'pYScrap', 1, 'tYInRepaired', 'pYReady', 1 ...
  'tYRoom', 'pYRoom', 1, 'tYOrder', 'pYOrder', 1 ...
  'pYLong', 'tYLong', 1, 'pYRoom', 'tYLong', 1, 'pYShort', 'tYShort', 1, 'pYRoom', 'tYShort', 1 ...
  'pYOrder', 'tYShip', 1, 'pYReady', 'tYShip', 1 ...
 };
png.set_of_Ports = png.set_of_Ts;
