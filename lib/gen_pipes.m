function [pipes, repair] = gen_pipes(P)
% Every joint that arrives, in arrival order. Fields: t (arrival time),
% route ('hall' or 'bypass'), len ('long' or 'short'), find (what inspection
% will find: 'ok', 'mach', 'hb' or 'scrap') and order.
% repair(order, :) is the order's repair time in days [machining hardbanding].
% Receipts come on weekdays during the shift, most on Mondays; the joints of
% a receipt follow each other and share route and length. Outcomes are drawn
% per order first, then per joint, because they cluster by order.

pipes = struct('t', {}, 'route', {}, 'len', {}, 'find', {}, 'order', {});
repair = zeros(0, 2);
order = 0;
lens = {'long', 'short'};
for day = 0:P.days-1
    w = mod(day, 7) + 1;
    if w > 5, continue; end                       % weekend
    m = P.receipts_per_day * 5*P.receipts_weekday(w)/sum(P.receipts_weekday);
    times = sort(day*1440 + P.shift(1) + rand(negbin(m, P.receipts_r), 1)*diff(P.shift));
    for t = times'
        order = order + 1;
        k = 1 + (rand >= P.p_long);               % 1 long, 2 short
        n = ceil(-P.mean_joints(k)*log(rand));    % exponential, at least 1
        route = 'hall';
        if rand < P.p_bypass, route = 'bypass'; end
        hit = rand(1, 3) < P.p_order;             % the order has [mach hb scrap]
        repair(order, :) = P.repair_median .* exp(P.repair_sigma .* randn(1, 2));
        for j = 1:n
            pipes(end+1) = struct('t', t, 'route', route, 'len', lens{k}, ...
                                  'find', finding(P, hit), 'order', order);
        end
    end
end

function c = finding(P, hit)
% One outcome per joint: scrap before machining before hardbanding.
r = hit & rand(1, 3) < P.share;
if r(3),     c = 'scrap';
elseif r(1), c = 'mach';
elseif r(2), c = 'hb';
else,        c = 'ok';
end
