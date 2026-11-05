function yes = flow_logistics(S, id, task, expected, busy, source, target)
% Shared connector: reserve a driver/forklift for a timed transfer.
yes = false;
if ~strcmp(S.state{id}, expected), return, end
f = find(~S.fork_busy, 1);
driver = find(~S.worker_busy & S.certified, 1);
if isempty(f) || isempty(driver), return, end
w = driver;
duration = S.C.move_minutes;
if strcmp(task, 'unload')
    others = find(~S.worker_busy & (1:numel(S.level)) ~= driver);
    if numel(others) < S.C.unload_workers - 1, return, end
    w = [driver, others(1:S.C.unload_workers-1)];
    duration = S.P.unload;
elseif strcmp(task, 'load')
    duration = S.C.load_minutes;
end
if ~S.fits(duration), return, end
S.fork_busy(f) = true;
S.add(id, S.pipes(id).order, task, 0, duration, w, f, 0, source, target);
S.state{id} = busy;
yes = true;
end
