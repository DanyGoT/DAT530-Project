function demand = gen_demand(P)
% The time of every joint asked for by a delivery ticket, sorted.
% Tickets come on weekdays in opening hours (P.open), most on Fridays.

demand = [];
for day = 0:P.days-1
    w = mod(day, 7) + 1;
    if w > 5, continue; end                       % weekend
    m = P.tickets_per_day * 5*P.tickets_weekday(w)/sum(P.tickets_weekday);
    for k = 1:negbin(m, P.tickets_r)
        t = day*1440 + P.open(1) + rand*diff(P.open);
        joints = ceil(-P.mean_ticket*log(rand));
        demand = [demand; repmat(t, joints, 1)];
    end
end
demand = sort(demand);
