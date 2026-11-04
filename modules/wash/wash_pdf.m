% PDF: wash_pdf.m
%
% %%%%%%%   Washing (module)
% One unit with P.wash_lanes lanes (pumps). Joints wait on its rack in the
% order they came and are washed one per lane at a time:
%   pWRack  -> tWash_k -> pWDone
% Each wash takes P.wash_min and one worker of P.wash_crew (MOD_Washing_PRE),
% the manned minutes per joint the detailed wash used (mobilizing,
% changeovers and waiting included).
% Input port:  tWIn  - takes the next joint from the yard (pYW) onto the rack
% Output port: tWOut - hands the next washed joint to the hall (pWI)
% Both keep the joint's colours.
% wash_pdf(h) is hall h's wash (P.halls; for_hall).

function [png] = wash_pdf(h)

global global_info
if nargin < 1, h = 1; end

lanes = arrayfun(@(k) sprintf('tWash_%d', k), 1:global_info.P.wash_lanes, 'UniformOutput', false);
png.PN_name = 'Washing';
png.set_of_Ps = {'pWRack', 'pWDone'};
png.set_of_Ts = [{'tWIn', 'tWOut'}, lanes];
As = {'tWIn', 'pWRack', 1, 'pWDone', 'tWOut', 1};
for t = lanes
    As = [As, {'pWRack', t{1}, 1, t{1}, 'pWDone', 1}];
end
png.set_of_As = As;
png.set_of_Ports = {'tWIn', 'tWOut'};
png = for_hall(png, h);
