function B = crew_bound(P)
% An upper bound on the joints the crew can inspect a week, from the crew
% minutes each joint needs (params.m). No simulation.
%
% Work per joint, by level:
%   - each hall step: its time x pace, at its level;
%   - scrapped joints skip the steps marked skip once scrap is found. Scrap
%     is found at each finding step with the same chance, so a skip step is
%     skipped with the share of finding steps before it;
%   - the wash: P.wash_min manned minutes per joint, one lane per joint. Only
%     P.wash_crew may man it.
%   - steps in P.auto (and the wash, if 'Wash' is in it) need no one.
% Every time is rounded to the time step first, as the simulated net does
% (model_dyn).
% Work at level L can be done by level L or higher. For each L, the people
% at L or higher must do the work only they can do:
%   joints/week <= (their minutes a week) / (minutes of work at level >= L).
% Everyone can do L0 work, so the L0 line is the whole crew's bound. The
% wash lanes and the machines of P.auto have their own limit.
%
%   B.work(L+1)  crew minutes per joint at level L (wash in L0)
%   B.wash       manned wash minutes per joint
%   B.level(L+1) the bound from the people at level L or higher (a week)
%   B.wash_cap   joints a week the wash lanes can wash
%   B.machine    joints a week the slowest machine can do (inf: none)
%   B.bound      the lowest of them all
%   B.minutes    crew minutes per joint, all levels

week = 5 * diff(P.shift);                       % shift minutes a week, per person
D = P.delta;
step = @(m) max(D, round(m / D) * D);           % as model_dyn rounds firing times
scrap = P.p_order(3) * P.share(3);              % scrap share per joint
finds = [P.steps{:, 4}];
before = cumsum([0, finds(1:end-1)]) / sum(finds);   % found at an earlier finding step

work = zeros(1, 4);
B.machine = inf;
for k = 1:size(P.steps, 1)
    [name, sec, level, ~, skip] = P.steps{k, :};
    m = step(sec * P.pace / 60);
    if skip, m = m * (1 - scrap * before(k)); end
    if ismember(name, P.auto)
        B.machine = min(B.machine, P.halls * week / m);   % one per hall
    else
        work(level+1) = work(level+1) + m;
    end
end
B.wash_cap = P.halls * week * P.wash_lanes / step(P.wash_min);
B.wash = step(P.wash_min) * not(ismember('Wash', P.auto));
work(1) = work(1) + B.wash;

B.work = work;
B.minutes = sum(work);
B.level = inf(1, 4);
for L = 0:3
    people = sum(P.crew(L+1:end));
    B.level(L+1) = people * week / sum(work(L+1:end));
end
B.bound = min([B.level, B.wash_cap, B.machine]);
