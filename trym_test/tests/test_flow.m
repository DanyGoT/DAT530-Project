function test_flow()
% Small deterministic checks, not the long 800-pipe experiments.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
trym_test_setup();
P = params();
P.repair_median = [0.1 0.2];
P.repair_sigma = [0 0];
P.p_reinspect = [1 1];
P.p_order = [1 0 0];
P.share = [0.9 0 0];
P.hall_space = 1;
P.shift = [7 9]*60;               % exercise overnight pauses and lane shutdown
C = flow_config(P);
C.total = 12;
C.initial = 6;
C.wash_space = 1;
C.max_days = 30;
R = run_flow(P, C);
assert(R.complete && R.shipped + R.scrap == 12 && R.remaining == 0);
assert(height(R.pipes) == 12 && sum(strcmp(R.log.task, 'unload')) == 6);
assert(sum(strcmp(R.log.task, 'wash')) == 12);
assert(any(strcmp(R.log.task, 'repair')) && any(R.log.pass == 2));
assert(max(R.history.hall) <= P.hall_space && max(R.history.wash) <= C.wash_space);
L = R.log;
levels = repelem(0:3, P.crew);
cert = false(size(levels));
for k = 0:3
    ids = find(levels == k);
    cert(ids(1:C.certified(k+1))) = true;
end
for w = 1:sum(P.crew)
    rows = false(height(L), 1);
    for j = 1:height(L)
        rows(j) = ismember(w, L.workers{j});
    end
    nonoverlap(L(rows, :));
end
for f = 1:C.forklifts, nonoverlap(L(L.forklift == f, :)); end
for lane = 1:P.wash_lanes, nonoverlap(L(L.lane == lane, :)); end
for j = 1:height(L)
    w = L.workers{j};
    if strcmp(L.task{j}, 'inspect')
        assert(isscalar(w) && levels(w) >= P.steps{L.step(j), 3});
    end
    if L.forklift(j) > 0
        assert(any(cert(w)), 'Forklift task without a certified worker.');
        if strcmp(L.task{j}, 'unload'), assert(numel(w) == C.unload_workers); end
    end
    if ~isempty(w)
        assert(mod(floor(L.start(j)/1440), 7) < 5);
        assert(mod(L.start(j), 1440) >= P.shift(1) - 1e-8);
        assert(mod(L.start(j), 1440) + L.finish(j) - L.start(j) <= P.shift(2) + 1e-8);
    end
end
for k = 1:size(P.steps, 1)
    nonoverlap(L(strcmp(L.task, 'inspect') & L.step == k, :));
end
for id = 1:C.total
    rows = cellfun(@(ids) ismember(id, ids), L.pipe);
    pipe = L(rows, :);
    for pass = 1:2
        steps = pipe(strcmp(pipe.task, 'inspect') & pipe.pass == pass, :);
        if isempty(steps), continue, end
        assert(isequal(steps.step', 1:size(P.steps, 1)));
        assert(all(steps.start(2:end) >= steps.finish(1:end-1) - 1e-8));
        enter = pipe(strcmp(pipe.task, 'enter_hall') & pipe.pass == pass, :);
        leave = pipe(strcmp(pipe.task, 'move_out') & pipe.pass == pass, :);
        assert(enter.finish <= steps.start(1) && leave.start >= steps.finish(end));
    end
end
% The floor position is held during the exit movement, not just inspection.
floor_jobs = L(ismember(L.task, {'enter_hall', 'move_out'}), :);
for j = 1:height(R.history)
    t = R.history.time(j);
    occupied = sum(strcmp(floor_jobs.task, 'enter_hall') & floor_jobs.start <= t) - ...
        sum(strcmp(floor_jobs.task, 'move_out') & floor_jobs.finish <= t);
    assert(occupied == R.history.hall(j));
end
% An order cannot load until all its non-scrap pipes have returned to stock.
for o = 1:numel(R.orders)
    ids = R.orders(o).ids;
    load = L(strcmp(L.task, 'load') & L.order == o, :);
    ready = L(ismember(L.task, {'return', 'move_out'}) & L.order == o, :);
    for id = ids
        rows = cellfun(@(p) isequal(p, id), ready.pipe);
        assert(min(load.start) >= max(ready.finish(rows)) - 1e-8);
    end
    departure = L(strcmp(L.task, 'departure') & L.order == o, :);
    assert(departure.start >= max(load.finish) - 1e-8);
end
% Crew/equipment changes must not change any exogenous random inputs.
P.crew = [3 3 3 3];
C.certified = [1 1 1 1];
C.forklifts = 2;
C.step_machines(:) = 2;
other = run_flow(P, C);
assert(isequal(R.pipes, other.pipes) && isequal(R.orders, other.orders));
assert(other.complete && other.shipped == R.shipped);
% A horizon cutoff is explicitly incomplete, not a successful short run.
short = C;
short.max_days = 0.001;
lastwarn('');
limited = run_flow(P, short);
[~, warning_id] = lastwarn;
assert(strcmp(warning_id, 'flow:Incomplete'));
assert(~limited.complete && limited.remaining > 0);
assert(any(~limited.log.completed) && limited.history.time(end) == limited.end_time);
% Empty initial or incoming groups and a singleton remain valid populations.
C.total = 1;
for initial = 0:1
    C.initial = initial;
    singleton = run_flow(P, C);
    assert(singleton.complete && singleton.remaining == 0);
    assert(sum(strcmp(singleton.log.task, 'unload')) == 1 - initial);
end
C.total = 12;
C.initial = 6;
% Scrap-only orders terminate without a customer shipment or repair.
P.p_order = [0 0 1];
P.share = [0 0 1];
scrap = run_flow(P, C);
assert(scrap.complete && scrap.scrap == C.total && scrap.shipped == 0);
assert(~any(strcmp(scrap.log.task, 'repair')) && ~any(strcmp(scrap.log.task, 'departure')));
fprintf('test_flow: ok (finite population, full lifecycle, resources, sequence, batching, repeatability, scrap)\n');
end

function nonoverlap(T)
T = sortrows(T, 'start');
assert(all(T.start(2:end) >= T.finish(1:end-1) - 1e-8), 'Resource used by overlapping jobs.');
end
