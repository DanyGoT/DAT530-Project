function [joints, repair] = new_order(P, t, order)
% The joints of one receipt that arrives at time t, and its repair time in
% days [machining hardbanding]. Outcomes are drawn per order first, then per
% joint, because they cluster by order.
lens = {'long', 'short'};
k = 1 + (rand >= P.p_long);               % 1 long, 2 short
n = ceil(-P.mean_joints(k)*log(rand));    % exponential, at least 1
route = 'hall';
if rand < P.p_bypass, route = 'bypass'; end
hit = rand(1, 3) < P.p_order;             % the order has [mach hb scrap]
repair = P.repair_median .* exp(P.repair_sigma .* randn(1, 2));
joints = struct('t', {}, 'route', {}, 'len', {}, 'find', {}, 'order', {});
for j = 1:n
    joints(end+1) = struct('t', t, 'route', route, 'len', lens{k}, ...
                           'find', finding(P, hit), 'order', order);
end

function c = finding(P, hit)
% One outcome per joint: scrap before machining before hardbanding. The
% shares are raised for the outcomes checked earlier, so that each outcome
% still comes out at p_order.*share per joint.
scrap = P.p_order(3)*P.share(3);
mach = P.share(1)/(1 - scrap);
hb = P.share(2)/((1 - scrap)*(1 - P.p_order(1)*mach));
r = hit & rand(1, 3) < [mach hb P.share(3)];
if r(3),     c = 'scrap';
elseif r(1), c = 'mach';
elseif r(2), c = 'hb';
else,        c = 'ok';
end
