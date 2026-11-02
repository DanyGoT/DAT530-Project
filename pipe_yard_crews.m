function crews = pipe_yard_crews(workers, minLevel, counts)
% All [trainee junior senior] crews of size WORKERS where every member has at
% least MINLEVEL and no level exceeds the staffed COUNTS.
crews = zeros(0, 3);
for t = 0:workers
    for j = 0:workers - t
        crew = [t, j, workers - t - j];
        if all(crew(1:minLevel-1) == 0) && all(crew <= counts)
            crews(end+1, :) = crew; %#ok<AGROW>
        end
    end
end
end
