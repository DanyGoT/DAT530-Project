function [fire, transition] = MOD_Washing_PRE(transition)
% Washing goes in arrival order, so the joints of an order stay together.
% tWIn and tWOut pass joints on as soon as they come (COMMON_PRE picks them).
% A free worker of P.wash_crew (lowest level first) mobilizes the unit once P.wash_start
% joints wait on the rack (pWRack), and stays with it: the changeovers need
% no one else. The unit is demobilized when the rack is empty, or when
% nothing more fits before the shift ends, and the worker goes back to the
% hall (MOD_Washing_POST).
% Nine joints in ten are long, so lanes stay long and one at a time goes
% over to short when a short order comes up.

global global_info
P = global_info.P;
t = transition.name;
lane = 0;
u = find(t == '_', 1, 'last');
if not(isempty(u))                  % lane transitions: tWLong_2
    lane = str2double(t(u+1:end));
    t = t(1:u-1);
end

switch t
    case {'tWIn', 'tWOut'}
        fire = 1;
    case 'tWMobilize'
        fire = ntokens('pWRack') >= P.wash_start && fits(P, P.mobilize + P.wash(1)) ...
               && requestAR(P.wash_crew, 1);
    case 'tWDemobilize'
        fire = ntokens('pWRack') == 0 || not(fits(P, max(P.wash)));
    case 'tWToLong'
        fire = fits(P, P.change) && next_is('pWRack', 'long');
    case 'tWToShort'
        fire = fits(P, P.change) && next_is('pWRack', 'short') && not(other_lane_short(lane));
    case 'tWLong'                   % the next joint, if the lane is set up for it
        fire = fits(P, P.wash(1)) && next_is('pWRack', 'long');
        if fire, [fire, transition] = next_joint(transition); end
    case 'tWShort'
        fire = fits(P, P.wash(2)) && next_is('pWRack', 'short');
        if fire, [fire, transition] = next_joint(transition); end
end


function [fire, transition] = next_joint(transition)
% The first joint on the rack, with its colours.
[id, c] = find_token('pWRack', @(tok) true);
[fire, transition] = pick(transition, id, c);


function yes = fits(P, minutes)
% Work of this length can start now and still leave time to demobilize.
now = mod(current_time(), 1440);
yes = in_shift(P) && now + minutes <= P.shift(2) - P.demobilize;


function yes = other_lane_short(lane)
% Another lane is set up for short joints, or changing over to them.
global global_info
yes = false;
for k = setdiff(1:global_info.P.wash_lanes, lane)
    yes = yes || ntokens(sprintf('pWShort_%d', k)) > 0 || is_firing(sprintf('tWToShort_%d', k));
end
