function flow_arrival(S, phase, job)
switch phase
    case 'arrive'
        ids = find(strcmp(S.state, 'incoming') & [S.pipes.arrival] <= S.now + 1e-8);
        S.state(ids) = {'unload'};
        S.queue_since(ids) = [S.pipes(ids).arrival];
    case 'unload'
        for id = S.queued('unload')
            flow_logistics(S, id, 'unload', 'unload', 'unloading', 'arrival', 'yard');
        end
    case 'complete'
        S.state{job.pipe(1)} = 'dirty';
    otherwise
        error('flow:Phase', 'Unknown arrival phase: %s', phase);
end
end
