function test_process()
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
trym_test_setup();
P = params();
P.crew = [0 0 0 15];
P.wash_crew = {'L0', 'L1', 'L2', 'L3'};
P.p_long = 1;
P.p_order = [0 0 0];
P.wash_lanes = 15;
C = flow_config(P);
C.process_only = true;
C.total = 15;
C.initial = 15;
C.certified(:) = 0;
C.step_machines(:) = 15;
R = run_flow(P, C);
assert(R.complete && R.ok == 15 && R.remaining == 0);
L = R.log;
assert(all(ismember(L.task, {'wash', 'wash_close', 'inspect'})));
assert(all(L.forklift == 0) && sum(strcmp(L.task, 'wash')) == 15);
assert(max(R.history.hall) <= P.hall_space && max(R.history.wash) <= C.wash_space);
% Fifteen L3 workers really do the same step on fifteen different pipes at once.
for k = 1:size(P.steps, 1)
    jobs = L(strcmp(L.task, 'inspect') & L.step == k, :);
    assert(height(jobs) == 15);
    assert(max(jobs.start) - min(jobs.start) < 1e-8);
    assert(numel(unique([jobs.workers{:}])) == 15);
end
expected = P.mobilize + P.wash(1) + P.demobilize + sum([P.steps{:, 2}])*P.pace/60;
assert(abs(R.end_time - C.start - expected) < 1e-8);
for id = 1:C.total
    jobs = L(cellfun(@(ids) isequal(ids, id), L.pipe) & strcmp(L.task, 'inspect'), :);
    assert(isequal(jobs.step', 1:size(P.steps, 1)));
    assert(all(jobs.start(2:end) >= jobs.finish(1:end-1) - 1e-8));
end
% Single-person case: no fake certificate/unloading requirements or worker overlap.
P.crew = [0 0 0 1];
P.wash_lanes = 2;
single = run_flow(P, C);
assert(single.complete && single.ok == 15 && single.end_time > R.end_time);
jobs = sortrows(single.log, 'start');
assert(all(jobs.start(2:end) >= jobs.finish(1:end-1) - 1e-8));
% Competence and outcome routing on a mixed crew.
P.crew = [2 2 1 1];
P.p_order = [1 0 0];
P.share = [1 0 0];
repair = run_flow(P, C);
assert(repair.complete && repair.ready_repair == 15 && repair.remaining == 0);
assert(~any(strcmp(repair.log.task, 'repair')));
levels = repelem(0:3, P.crew);
for j = find(strcmp(repair.log.task, 'inspect'))'
    assert(levels(repair.log.workers{j}) >= P.steps{repair.log.step(j), 3});
end
P.p_order = [0 0 1];
P.share = [0 0 1];
scrap = run_flow(P, C);
assert(scrap.complete && scrap.scrap == 15 && scrap.remaining == 0);
fprintf('test_process: ok (15 simultaneous inspectors, exact duration, sequential steps, one worker, levels, outcomes)\n');
end
