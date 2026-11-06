% PDF: yard_pdf.m
%
% %%%%%%%   Yard (module): two yards, their forklifts and the lorries between them
% Main, by the hall:
%   pYLong / pYShort - joints waiting for the hall, by length (bundles)
%   pYReady          - rig-ready stock (racks)
%   pYScrap          - scrap
%   pYRoom           - credits: room in front of the hall (P.hall_buffer)
%   pYOrder          - joints asked for, to be loaded at Main
%   pYFork           - forklifts at Main
% Coop, ~8 min away:
%   pCHall           - bundles for the hall, fetched to Main by lorry
%   pCReady          - rig-ready stock
%   pCOrder          - joints asked for, to be loaded at Coop
%   pCFork           - forklifts at Coop
% Lorries (rented, never waited for):
%   pYToMain         - hall bundles on their way from Coop
%   pYToCoop         - rig-ready joints on their way from the hall to Coop
% Every transition that moves a joint is forklift work: it takes a forklift
% at its yard and gives it back when done, and a certified worker (and for
% lorries P.lorry_helpers more) from the pool (MOD_Yard_PRE). tYForkToCoop and
% tYForkToMain drive a forklift between the yards. Joints in the yards carry
% no colours.
% Input ports:  tYInLong, tYInShort, tYInBypass   (unload at Main, from Arrival)
%               tYInCHall, tYInCBypass            (unload at Coop, from Arrival)
%               tYInOk     (ok from the hall, into a rack at Main)
%               tYInOkCoop (ok from the hall, straight onto a lorry to Coop)
%               tYInScrap, tYInRepaired           (from Inspection, Repair)
%               tYRoom     (a credit handed back by the hall)
%               tYOrder, tYOrderCoop (one joint asked for, from Departure)
% Output ports: tYLong, tYShort - the next hall joint to the wash; each
%               spends a credit
%               tYShip, tYShipCoop - one stock joint per joint asked for
% With two halls (P.halls) each has its own feeds, credits and tYRoom
% (hall_name: tH2_YLong, pH2_YRoom, ...); they share the queue and forklifts.

function [png] = yard_pdf()

global global_info
H = 1:global_info.P.halls;
feeds = hall_name({'tYLong', 'tYShort'}, H);
main = [{'tYInLong', 'tYInShort', 'tYInBypass', 'tYInOk', 'tYInOkCoop', 'tYInScrap', ...
         'tYInRepaired'}, feeds, {'tYShip', 'tYFromCoopLong', 'tYFromCoopShort'}];
coop = {'tYInCHall', 'tYInCBypass', 'tYFetch', 'tYStoreCoop', 'tYShipCoop'};
inner = {'tYFetch', 'tYFromCoopLong', 'tYFromCoopShort', 'tYStoreCoop', 'tYForkToCoop', 'tYForkToMain'};

png.PN_name = 'Yard';
png.set_of_Ps = [{'pYLong', 'pYShort', 'pYReady', 'pYScrap'}, hall_name({'pYRoom'}, H), ...
                 {'pYOrder', 'pYFork', 'pCHall', 'pCReady', 'pCOrder', 'pCFork', 'pYToMain', 'pYToCoop'}];
png.set_of_Ts = [main, coop, hall_name({'tYRoom'}, H), {'tYOrder', 'tYOrderCoop', 'tYForkToCoop', 'tYForkToMain'}];
png.set_of_Ts = unique(png.set_of_Ts, 'stable');
into = { ...                            % unloaded or handed over
  'tYInLong',        'pYLong',          1, ...
  'tYInShort',       'pYShort',         1, ...
  'tYInBypass',      'pYReady',         1, ...
  'tYInOk',          'pYReady',         1, ...
  'tYInScrap',       'pYScrap',         1, ...
  'tYInRepaired',    'pYReady',         1, ...
  'tYInCHall',       'pCHall',          1, ...
  'tYInCBypass',     'pCReady',         1};
lorry = { ...                           % rig-ready to Coop, hall joints from Coop
  'tYInOkCoop',      'pYToCoop',        1, ...
  'pYToCoop',        'tYStoreCoop',     1, ...
  'tYStoreCoop',     'pCReady',         1, ...
  'pCHall',          'tYFetch',         1, ...
  'tYFetch',         'pYToMain',        1, ...
  'pYToMain',        'tYFromCoopLong',  1, ...
  'tYFromCoopLong',  'pYLong',          1, ...
  'pYToMain',        'tYFromCoopShort', 1, ...
  'tYFromCoopShort', 'pYShort',         1};
ship = { ...                            % joints asked for, and shipped
  'tYOrder',         'pYOrder',         1, ...
  'tYOrderCoop',     'pCOrder',         1, ...
  'pYOrder',         'tYShip',          1, ...
  'pYReady',         'tYShip',          1, ...
  'pCOrder',         'tYShipCoop',      1, ...
  'pCReady',         'tYShipCoop',      1};
drive = { ...                           % a forklift driven between the yards
  'pYFork',          'tYForkToCoop',    1, ...
  'tYForkToCoop',    'pCFork',          1, ...
  'pCFork',          'tYForkToMain',    1, ...
  'tYForkToMain',    'pYFork',          1};
As = [into, lorry, ship, drive];
for h = H                               % per hall: its credits, and its feeds spend one
    n = @(name) hall_name(name, h);
    As = [As, {n('tYRoom'), n('pYRoom'), 1, 'pYLong', n('tYLong'), 1, n('pYRoom'), n('tYLong'), 1, ...
               'pYShort', n('tYShort'), 1, n('pYRoom'), n('tYShort'), 1}];
end
for t = main                            % forklift work at Main: take one, give it back
    As = [As, {'pYFork', t{1}, 1, t{1}, 'pYFork', 1}];
end
for t = coop                            % ... and at Coop
    As = [As, {'pCFork', t{1}, 1, t{1}, 'pCFork', 1}];
end
png.set_of_As = As;
png.set_of_Ports = setdiff(png.set_of_Ts, inner, 'stable');
