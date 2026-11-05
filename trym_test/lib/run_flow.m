function R = run_flow(P, C)
% Event engine: module dispatch order deliberately matches the original runner.
if ~isfield(C, 'process_only'), C.process_only = false; end
if ~isfield(C, 'batch_clearance'), C.batch_clearance = false; end
if ~isfield(C, 'batch_move_minutes'), C.batch_move_minutes = 15; end
flow_validate(P, C);
S = flow_state(P, C);
while S.now <= S.limit
    due = S.active([S.log(S.active).finish] <= S.now + 1e-8);
    for e = due
        flow_complete(S, e);
    end
    S.active = setdiff(S.active, due, 'stable');
    flow_arrival(S, 'arrive');
    flow_departure(S, 'release');
    terminal = {'shipped', 'scrap'};
    if C.process_only, terminal = {'ready', 'ready_repair', 'scrap'}; end
    if all(ismember(S.state, terminal)) && isempty(S.active) && all(S.lane_day < 0)
        S.complete = true;
        S.record();
        break
    end
    if S.in_shift()
        flow_wash(S, 'close');
        flow_yard(S, 'clear');
        flow_repair(S, 'return');
        flow_wash_inspection(S);
        flow_inspection(S, 'schedule');
        flow_wash(S, 'schedule');
        flow_yard(S, 'feed');
        flow_arrival(S, 'unload');
        flow_departure(S, 'load');
    end
    S.record();
    S.now = S.next_event();
end
if ~S.complete
    S.now = S.limit;
    S.record();
end
R = S.results();
end
