function flow_inspection(S, phase, job)
switch phase
    case 'schedule'
        % Later steps first, with the lowest qualified free worker.
        for k = S.K:-1:1
            if S.C.batch_clearance && ~all(S.on_floor(S.group_ids)), break, end
            ids = S.queued('inspection');
            for id = ids(S.step(ids) == k)
                if S.machines(k) >= S.C.step_machines(k), break, end
                w = find(~S.worker_busy & S.level >= S.P.steps{k, 3}, 1);
                duration = S.P.steps{k, 2}*S.P.pace/60;
                if ~isempty(w) && S.fits(duration)
                    S.machines(k) = S.machines(k) + 1;
                    S.add(id, S.pipes(id).order, 'inspect', k, duration, w, 0, 0, 'hall', 'hall');
                    S.state{id} = 'inspecting';
                end
            end
        end
    case 'complete'
        id = job.pipe(1);
        S.machines(job.step) = S.machines(job.step) - 1;
        if ~S.second_pass(id) && strcmp(S.pipes(id).finding, 'scrap') && ...
                job.step == S.pipes(id).scrap_step
            S.pipes(id).scrapped = true;
        end
        S.step(id) = S.step(id) + 1;
        S.state{id} = 'inspection';
        skip_scrap(S, id);
    case 'enter'
        id = job.pipe(1);
        S.in_wash(id) = false;
        S.state{id} = 'inspection';
        skip_scrap(S, id);
    otherwise
        error('flow:Phase', 'Unknown inspection phase: %s', phase);
end
end

function skip_scrap(S, id)
while S.step(id) <= S.K && S.pipes(id).scrapped && S.P.steps{S.step(id), 5}
    S.step(id) = S.step(id) + 1;
end
if S.step(id) > S.K
    S.state{id} = 'hall_done';
    if S.C.process_only && ~S.C.batch_clearance
        S.on_floor(id) = false;
        flow_classify(S, id);
    end
end
end
