function flow_complete(S, event)
% Release shared resources and hand the completed event to its owning module.
job = S.log(event);
S.worker_busy(job.workers) = false;
if job.forklift > 0, S.fork_busy(job.forklift) = false; end
if job.lane > 0, S.lane_busy(job.lane) = false; end
if ~strcmp(job.task, 'wash_close'), S.queue_since(job.pipe) = S.now; end
switch job.task
    case 'unload'
        flow_arrival(S, 'complete', job);
    case {'wash', 'wash_close'}
        flow_wash(S, 'complete', job);
    case 'enter_hall'
        flow_inspection(S, 'enter', job);
    case 'inspect'
        flow_inspection(S, 'complete', job);
    case {'feed_wash', 'batch_move_out', 'move_out'}
        flow_yard(S, 'complete', job);
    case {'repair', 'return'}
        flow_repair(S, 'complete', job);
    case {'load', 'departure'}
        flow_departure(S, 'complete', job);
    otherwise
        error('flow:Task', 'Unknown completed event: %s', job.task);
end
end
