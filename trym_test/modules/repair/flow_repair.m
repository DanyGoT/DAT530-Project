function flow_repair(S, phase, job)
switch phase
    case 'return'
        for id = S.queued('return_wait')
            flow_logistics(S, id, 'return', 'return_wait', 'returning', 'repair', 'yard');
        end
    case 'send'
        id = job.pipe(1);
        workshop = 1 + strcmp(S.pipes(id).finding, 'hb');
        S.state{id} = 'repair';
        duration = S.orders(S.pipes(id).order).repair(workshop)*1440 + 2*S.C.repair_transport;
        S.add(id, S.pipes(id).order, 'repair', 0, duration, [], 0, 0, 'yard', 'repair-return');
    case 'complete'
        id = job.pipe(1);
        if strcmp(job.task, 'repair')
            S.state{id} = 'return_wait';
        elseif S.pipes(id).reinspect
            S.second_pass(id) = true;
            S.step(id) = 1;
            S.state{id} = 'recheck';
        else
            S.state{id} = 'ready';
        end
    otherwise
        error('flow:Phase', 'Unknown repair phase: %s', phase);
end
end
