function flow_yard(S, phase, job)
switch phase
    case 'clear'
        if S.C.batch_clearance
            w = find(~S.worker_busy, 1);
            ids = S.group_ids;
            if ~isempty(ids) && all(strcmp(S.state(ids), 'hall_done')) && ...
                    ~isempty(w) && S.fits(S.C.batch_move_minutes)
                S.add(ids, 0, 'batch_move_out', 0, S.C.batch_move_minutes, w, 0, 0, 'hall', 'yard');
                S.state(ids) = {'moving_out'};
            end
        else
            for id = S.queued('hall_done')
                flow_logistics(S, id, 'move_out', 'hall_done', 'moving_out', 'hall', 'yard');
            end
        end
    case 'feed'
        for id = S.queued('dirty')
            if sum(S.in_wash) >= S.C.wash_space, break, end
            if flow_logistics(S, id, 'feed_wash', 'dirty', 'feeding', 'yard', 'wash')
                S.in_wash(id) = true;
            end
        end
    case 'complete'
        ids = job.pipe;
        id = ids(1);
        switch job.task
            case 'feed_wash'
                S.state{id} = 'wash_wait';
            case 'batch_move_out'
                S.on_floor(ids) = false;
                for cleared = ids, flow_classify(S, cleared); end
                S.group_start = S.group_start + numel(ids);
                S.group_ids = S.group_start:min(S.N, S.group_start + S.P.hall_space - 1);
            case 'move_out'
                S.on_floor(id) = false;
                if S.pipes(id).scrapped
                    S.state{id} = 'scrap';
                elseif ~S.second_pass(id) && ismember(S.pipes(id).finding, {'mach', 'hb'})
                    flow_repair(S, 'send', job);
                else
                    S.state{id} = 'ready';
                end
            otherwise
                error('flow:Task', 'Unknown yard task: %s', job.task);
        end
    otherwise
        error('flow:Phase', 'Unknown yard phase: %s', phase);
end
end
