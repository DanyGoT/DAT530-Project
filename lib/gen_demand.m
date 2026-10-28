function demand = gen_demand(P)
% The time of every joint asked for by a delivery ticket, sorted.
% Tickets come on weekdays during the shift.

demand = [];
for day = 0:P.days-1
    if mod(day, 7) >= 5, continue; end            % weekend
    for k = 1:poisson(P.tickets_per_day)
        t = day*1440 + P.shift(1) + rand*diff(P.shift);
        joints = ceil(-P.mean_ticket*log(rand));
        demand = [demand; repmat(t, joints, 1)];
    end
end
demand = sort(demand);
