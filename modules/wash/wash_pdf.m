% PDF: wash_pdf.m
%
% %%%%%%%   Washing (module)
% One unit with P.wash_lanes lanes (pumps).
%   pWRack           - joints waiting at the unit, in arrival order
%   pWOff            - the unit is demobilized; tWMobilize readies every lane
%   pWReady_k        - lane k is mobilized and free
%   pWLong_k/Short_k - lane k is set up for long or short joints
%   pWDone           - washed joints, on their way out
% tWToLong_k / tWToShort_k switch lane k when the next joint has the other
% length; tWLong_k / tWShort_k wash one joint. A transition fires once at a
% time, so each lane needs its own. tWDemobilize takes every lane back.
% A worker from the shared crew mans the unit from tWMobilize until
% tWDemobilize ends (MOD_Washing_PRE/POST).
% Input port:  tWIn  - takes the next joint from the yard (pYW) onto the rack
% Output port: tWOut - hands the next washed joint to the hall (pWI)
% Both keep the joint's colours.

function [png] = wash_pdf()

global global_info

png.PN_name = 'Washing';
Ps = {'pWRack', 'pWDone', 'pWOff'};
Ts = {'tWIn', 'tWOut', 'tWMobilize', 'tWDemobilize'};
As = {'tWIn', 'pWRack', 1, 'pWDone', 'tWOut', 1, ...
      'pWOff', 'tWMobilize', 1, 'tWDemobilize', 'pWOff', 1};
for k = 1:global_info.P.wash_lanes
    n = @(name) sprintf('%s_%d', name, k);
    Ps = [Ps, {n('pWReady'), n('pWLong'), n('pWShort')}];
    Ts = [Ts, {n('tWToLong'), n('tWToShort'), n('tWLong'), n('tWShort')}];
    As = [As, { ...
      'tWMobilize', n('pWReady'), 1, n('pWReady'), 'tWDemobilize', 1 ...
      n('pWReady'), n('tWToLong'),  1, n('pWShort'), n('tWToLong'),  1 ...
      n('tWToLong'),  n('pWReady'), 1, n('tWToLong'),  n('pWLong'),  1 ...
      n('pWReady'), n('tWToShort'), 1, n('pWLong'),  n('tWToShort'), 1 ...
      n('tWToShort'), n('pWReady'), 1, n('tWToShort'), n('pWShort'), 1 ...
      'pWRack', n('tWLong'),  1, n('pWReady'), n('tWLong'),  1, n('pWLong'),  n('tWLong'),  1 ...
      n('tWLong'),  'pWDone', 1, n('tWLong'),  n('pWReady'), 1, n('tWLong'),  n('pWLong'),  1 ...
      'pWRack', n('tWShort'), 1, n('pWReady'), n('tWShort'), 1, n('pWShort'), n('tWShort'), 1 ...
      n('tWShort'), 'pWDone', 1, n('tWShort'), n('pWReady'), 1, n('tWShort'), n('pWShort'), 1 ...
     }];
end
png.set_of_Ps = Ps;
png.set_of_Ts = Ts;
png.set_of_As = As;
png.set_of_Ports = {'tWIn', 'tWOut'};
