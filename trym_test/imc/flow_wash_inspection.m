function flow_wash_inspection(S)
% Connector: admission to inspection, including batch gates and floor credits.
for id = [S.queued('recheck'), S.queued('washed')]
    if sum(S.on_floor) >= S.P.hall_space, break, end
    if S.C.batch_clearance && ~ismember(id, S.group_ids), continue, end
    if S.C.process_only
        S.on_floor(id) = true;
        S.in_wash(id) = false;
        S.state{id} = 'inspection';
        S.queue_since(id) = S.now;
    elseif flow_logistics(S, id, 'enter_hall', S.state{id}, 'entering', 'wash/yard', 'hall')
        S.on_floor(id) = true;
    end
end
end
