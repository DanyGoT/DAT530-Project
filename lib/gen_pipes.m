function [pipes, repair, backlog, floor] = gen_pipes(P)
% Every joint that arrives, in arrival order. Fields: t (arrival time),
% route ('hall' or 'bypass'), len ('long' or 'short'), find (what inspection
% will find: 'ok', 'mach', 'hb' or 'scrap') and order.
% repair(order, :) is the order's repair time in days [machining hardbanding].
% Receipts come on weekdays during the shift, most on Mondays; the joints of
% a receipt follow each other and share route and length.
% What is there at t = 0, drawn from ordinary orders (bypass orders are in
% storage, so dropped):
%   backlog - hall joints queued in the yard, whole orders, at least P.backlog
%   floor   - the first P.floor_start joints of more orders, on the hall floor

pipes = struct('t', {}, 'route', {}, 'len', {}, 'find', {}, 'order', {});
repair = zeros(0, 2);
for day = 0:P.days-1
    w = mod(day, 7) + 1;
    if w > 5, continue; end                       % weekend
    m = P.receipts_per_day * 5*P.receipts_weekday(w)/sum(P.receipts_weekday);
    times = sort(day*1440 + P.shift(1) + rand(negbin(m, P.receipts_r), 1)*diff(P.shift));
    for t = times'
        [joints, repair(end+1, :)] = new_order(P, t, size(repair, 1) + 1);
        pipes = [pipes, joints];
    end
end

[backlog, repair] = hall_orders(P, P.backlog, repair);
[floor, repair] = hall_orders(P, P.floor_start, repair);
floor = floor(1:P.floor_start);

function [joints, repair] = hall_orders(P, n, repair)
% Whole hall orders drawn at t = 0 until there are at least n joints.
joints = struct('t', {}, 'route', {}, 'len', {}, 'find', {}, 'order', {});
while numel(joints) < n
    [j, repair(end+1, :)] = new_order(P, 0, size(repair, 1) + 1);
    if strcmp(j(1).route, 'hall'), joints = [joints, j]; end
end
