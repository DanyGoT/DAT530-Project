function flow_departure(S, phase, job)
switch phase
    case 'release'
        if S.C.process_only, return, end
        for o = 1:numel(S.orders)
            ids = S.orders(o).ids;
            if all(ismember(S.state(ids), {'ready', 'loading', 'loaded', 'shipped', 'scrap'}))
                S.released(o) = true;
            end
            if S.released(o) && ~S.departing(o) && all(ismember(S.state(ids), {'loaded', 'shipped', 'scrap'}))
                S.departing(o) = true;
                goods = ids(~strcmp(S.state(ids), 'scrap'));
                if ~isempty(goods)
                    S.add(goods, o, 'departure', 0, S.C.depart_minutes, [], 0, 0, 'truck', 'shipped');
                end
            end
        end
    case 'load'
        for id = S.queued('ready')
            if ~S.C.process_only && S.released(S.pipes(id).order)
                flow_logistics(S, id, 'load', 'ready', 'loading', 'yard', 'truck');
            end
        end
    case 'complete'
        if strcmp(job.task, 'load')
            S.state{job.pipe(1)} = 'loaded';
        else
            S.state(job.pipe) = {'shipped'};
        end
    otherwise
        error('flow:Phase', 'Unknown departure phase: %s', phase);
end
end
