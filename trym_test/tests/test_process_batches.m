function test_process_batches()
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
trym_test_setup();
P = params();
P.crew = [2 2 1 2];
P.wash_crew = {'L0', 'L1', 'L2', 'L3'};
P.hall_space = 30;
C = flow_config(P);
C.process_only = true;
C.batch_clearance = true;
C.batch_move_minutes = 12;
C.total = 65;
C.initial = 65;
C.certified(:) = 0;
C.step_machines(:) = 65;
R = run_flow(P, C);
assert(R.complete && R.ok + R.ready_repair + R.scrap == 65);
L = R.log;
moves = L(strcmp(L.task, 'batch_move_out'), :);
assert(isequal(cellfun(@numel, moves.pipe)', [30 30 5]));
assert(all(abs(moves.finish-moves.start-12) < 1e-8));
assert(all(cellfun(@isscalar, moves.workers)) && all(moves.forklift == 0));
for g = 1:height(moves)
    ids = moves.pipe{g};
    inspect = L(strcmp(L.task, 'inspect') & cellfun(@(p) all(ismember(p, ids)), L.pipe), :);
    assert(moves.start(g) >= max(inspect.finish)-1e-8);
    if g > 1
        assert(min(inspect.start) >= moves.finish(g-1)-1e-8);
    end
    % The whole group remains on the floor during its movement.
    times = R.history.time;
    during = times >= moves.start(g) & times < moves.finish(g);
    assert(all(R.history.hall(during) == numel(ids)));
end
for worker = 1:sum(P.crew)
    jobs = L(cellfun(@(w) ismember(worker, w), L.workers), :);
    jobs = sortrows(jobs, 'start');
    assert(all(jobs.start(2:end) >= jobs.finish(1:end-1)-1e-8));
end
assert(max(R.history.hall) <= 30 && R.history.hall(end) == 0);
assert(~any(ismember(L.task, {'repair', 'load', 'departure', 'unload'})));
% Smaller-than-hall populations are cleared instead of waiting for 30 forever.
C.total = 5;
C.initial = 5;
small = run_flow(P, C);
assert(small.complete && sum(strcmp(small.log.task, 'batch_move_out')) == 1);
% One worker must not be used for inspection/washing while clearing a group.
P.crew = [0 0 0 1];
single = run_flow(P, C);
assert(single.complete);
jobs = sortrows(single.log, 'start');
assert(all(jobs.start(2:end) >= jobs.finish(1:end-1)-1e-8));
fprintf('test_process_batches: ok (30/30/5 groups, worker/time reservation, no early admission, partial group)\n');
end
