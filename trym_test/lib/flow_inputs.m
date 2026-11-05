function [pipes, orders] = flow_inputs(P, C)
% Reuse the original project's order generator, without changing its draws.
pipes = struct('order', {}, 'arrival', {}, 'len', {}, 'finding', {}, ...
    'scrap_step', {}, 'scrapped', {}, 'reinspect', {});
orders = struct('ids', {}, 'arrival', {}, 'repair', {});
finding_steps = find([P.steps{:, 4}]);
incoming_order = 0;
for group = 1:2
    count = C.initial;
    if group == 2, count = C.total - C.initial; end
    while count > 0
        o = numel(orders) + 1;
        t = C.start;
        if group == 2
            t = C.first_arrival + incoming_order*C.arrival_gap;
            incoming_order = incoming_order + 1;
        end
        [joints, repair] = new_order(P, t, o);
        n = min(count, numel(joints));
        ids = numel(pipes) + (1:n);
        orders(o) = struct('ids', ids, 'arrival', t, 'repair', repair);
        for j = 1:n
            detection = 0;
            if strcmp(joints(j).find, 'scrap')
                detection = finding_steps(randi(numel(finding_steps)));
            end
            w = 1 + strcmp(joints(j).find, 'hb');
            again = rand < P.p_reinspect(w);
            pipes(end+1) = struct('order', o, 'arrival', t, 'len', joints(j).len, ...
                'finding', joints(j).find, 'scrap_step', detection, ...
                'scrapped', false, 'reinspect', again);
        end
        count = count - n;
    end
end
end
