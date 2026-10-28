function pipes = gen_pipes(P)
% Every joint that arrives, in arrival order. Fields: t (arrival time),
% route ('hall' or 'bypass'), len ('long' or 'short'), find (what inspection
% will find: 'ok', 'mach', 'hb' or 'scrap') and order.
% Receipts come on weekdays during the shift; the joints of a receipt follow
% each other and share route and length.

pipes = struct('t', {}, 'route', {}, 'len', {}, 'find', {}, 'order', {});
order = 0;
lens = {'long', 'short'};
for day = 0:P.days-1
    if mod(day, 7) >= 5, continue; end            % weekend
    times = sort(day*1440 + P.shift(1) + rand(poisson(P.receipts_per_day), 1)*diff(P.shift));
    for t = times'
        order = order + 1;
        k = 1 + (rand >= P.p_long);               % 1 long, 2 short
        n = ceil(-P.mean_joints(k)*log(rand));    % exponential, at least 1
        route = 'hall';
        if rand < P.p_bypass, route = 'bypass'; end
        for j = 1:n
            pipes(end+1) = struct('t', t, 'route', route, 'len', lens{k}, ...
                                  'find', finding(P), 'order', order);
        end
    end
end

function c = finding(P)
r = rand;
if r < P.p_scrap,                     c = 'scrap';
elseif r < P.p_scrap+P.p_mach,        c = 'mach';
elseif r < P.p_scrap+P.p_mach+P.p_hb, c = 'hb';
else,                                 c = 'ok';
end
