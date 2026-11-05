function flow_wash(S, phase, job)
P = S.P;
wash_levels = arrayfun(@(L) sprintf('L%d', L), S.level, 'UniformOutput', false);
allowed = ismember(wash_levels, P.wash_crew);
switch phase
    case 'close'
        no_more = ~any(ismember(S.state, ...
            {'incoming', 'unload', 'unloading', 'dirty', 'feeding', 'wash_wait', 'washing'}));
        for lane = find(~S.lane_busy & S.lane_day >= 0)
            close = S.lane_day(lane) < floor(S.now/1440) || no_more || ...
                mod(S.now, 1440) >= P.shift(2) - P.demobilize - 1e-8;
            w = find(~S.worker_busy & allowed, 1);
            if close && ~isempty(w) && S.fits(P.demobilize)
                S.lane_busy(lane) = true;
                id = S.lane_pipe(lane);
                S.add(id, S.pipes(id).order, 'wash_close', 0, P.demobilize, w, 0, lane, 'wash', 'wash');
            end
        end
    case 'schedule'
        if S.C.process_only
            for id = S.queued('dirty')
                if sum(S.in_wash) >= S.C.wash_space, break, end
                S.in_wash(id) = true;
                S.state{id} = 'wash_wait';
                S.queue_since(id) = S.now;
            end
        end
        for id = S.queued('wash_wait')
            lane = find(~S.lane_busy & (S.lane_day < 0 | S.lane_day == floor(S.now/1440)), 1);
            w = find(~S.worker_busy & allowed, 1);
            if isempty(lane) || isempty(w), break, end
            len = S.pipes(id).len;
            setup = 0;
            if S.lane_day(lane) ~= floor(S.now/1440), setup = P.mobilize; end
            if ~isempty(S.lane_length{lane}) && ~strcmp(S.lane_length{lane}, len)
                setup = setup + P.change;
            end
            duration = setup + P.wash(1 + strcmp(len, 'short'));
            if S.fits(duration + P.demobilize)
                S.lane_busy(lane) = true;
                S.lane_day(lane) = floor(S.now/1440);
                S.lane_length{lane} = len;
                S.lane_pipe(lane) = id;
                S.add(id, S.pipes(id).order, 'wash', 0, duration, w, 0, lane, 'wash', 'wash');
                S.state{id} = 'washing';
            end
        end
    case 'complete'
        if strcmp(job.task, 'wash_close')
            S.lane_day(job.lane) = -1;
        else
            S.state{job.pipe(1)} = 'washed';
        end
    otherwise
        error('flow:Phase', 'Unknown washing phase: %s', phase);
end
end
