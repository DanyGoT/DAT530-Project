function [workshop, repair] = gen_workshop(P, repair)
% The joints at the workshops at t = 0. The hall sent them there before the
% run: P.inspected_per_day hall joints a weekday over the last
% P.workshop_history days, drawn as ordinary orders. A joint is still out if
% its order's repair is done after t = 0, so the workshops start in the
% steady state of the model's own repair times.
% workshop{w}: one row [done again] per joint at workshop w (1 machining,
% 2 hardbanding), the same rows MOD_Repair_PRE keeps during the run.

finds = {'mach', 'hb'};
workshop = {zeros(0, 2), zeros(0, 2)};
for day = -P.workshop_history:-1
    if mod(day, 7) >= 5, continue; end            % weekend (t = 0 is a Monday)
    n = 0;
    while n < P.inspected_per_day
        t = day*1440 + P.shift(1) + rand*diff(P.shift);
        [joints, repair(end+1, :)] = new_order(P, t, size(repair, 1) + 1);
        if strcmp(joints(1).route, 'bypass'), continue; end
        n = n + numel(joints);
        for w = 1:2
            k = sum(strcmp({joints.find}, finds{w}));
            done = t + repair(end, w)*1440;
            if k == 0 || done <= 0, continue; end
            workshop{w} = [workshop{w}; repmat(done, k, 1), rand(k, 1) < P.p_reinspect(w)];
        end
    end
end
