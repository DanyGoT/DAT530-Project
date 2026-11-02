function crew = pipe_yard_pick_crew(workers, minLevel, available)
% Cheapest qualified crew: fill from the lowest allowed level upwards so
% seniors stay free for hard tasks. Returns [] if not enough workers.
crew = [0, 0, 0];
remaining = workers;
for level = minLevel:3
    crew(level) = min(available(level), remaining);
    remaining = remaining - crew(level);
end
if remaining > 0
    crew = [];
end
end
