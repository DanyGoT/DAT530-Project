classdef flow_state < handle
    % Shared state/resources for the event-driven modules, not Petri-net tokens.
    properties
        P
        C
        pipes
        orders
        N
        K
        level
        certified
        worker_busy
        fork_busy
        lane_busy
        lane_day
        lane_length
        lane_pipe
        machines
        state
        step
        on_floor
        in_wash
        second_pass
        queue_since
        released
        departing
        log
        active = []
        history = []
        now
        limit
        complete = false
        group_start = 1
        group_ids
    end
    methods
        function S = flow_state(P, C)
            S.P = P;
            S.C = C;
            rng(P.seed);
            [S.pipes, S.orders] = flow_inputs(P, C);
            S.N = C.total;
            S.K = size(P.steps, 1);
            S.level = repelem(0:3, P.crew);
            S.certified = false(size(S.level));
            for L = 0:3
                ids = find(S.level == L);
                S.certified(ids(1:C.certified(L+1))) = true;
            end
            S.worker_busy = false(size(S.level));
            S.fork_busy = false(1, C.forklifts);
            S.lane_busy = false(1, P.wash_lanes);
            S.lane_day = -ones(1, P.wash_lanes);
            S.lane_length = repmat({''}, 1, P.wash_lanes);
            S.lane_pipe = zeros(1, P.wash_lanes);
            S.machines = zeros(1, S.K);
            S.state = repmat({'incoming'}, 1, S.N);
            S.state(1:C.initial) = {'dirty'};
            S.step = ones(1, S.N);
            S.on_floor = false(1, S.N);
            S.in_wash = false(1, S.N);
            S.second_pass = false(1, S.N);
            S.queue_since = C.start*ones(1, S.N);
            S.released = false(1, numel(S.orders));
            S.departing = false(1, numel(S.orders));
            S.log = struct('pipe', {}, 'order', {}, 'task', {}, 'step', {}, ...
                'start', {}, 'finish', {}, 'workers', {}, 'forklift', {}, ...
                'lane', {}, 'source', {}, 'target', {}, 'wait', {}, 'pass', {});
            S.now = C.start;
            S.limit = C.start + C.max_days*1440;
            S.group_ids = 1:min(S.N, P.hall_space);
        end

        function ids = queued(S, name)
            ids = find(strcmp(S.state, name));
            [~, ix] = sort(S.queue_since(ids));
            ids = ids(ix);
        end

        function yes = in_shift(S)
            yes = mod(floor(S.now/1440), 7) < 5 && ...
                mod(S.now, 1440) >= S.P.shift(1) && mod(S.now, 1440) < S.P.shift(2);
        end

        function yes = fits(S, duration)
            yes = S.in_shift() && mod(S.now, 1440) + duration <= S.P.shift(2) + 1e-8;
        end

        function add(S, ids, o, task, k, duration, w, f, lane, source, target)
            S.worker_busy(w) = true;
            event_index = numel(S.log) + 1;
            S.log(event_index) = struct('pipe', ids, 'order', o, 'task', task, 'step', k, ...
                'start', S.now, 'finish', S.now + duration, 'workers', w, ...
                'forklift', f, 'lane', lane, 'source', source, 'target', target, ...
                'wait', max(0, S.now - min(S.queue_since(ids))), 'pass', 1 + S.second_pass(ids(1)));
            S.active(end+1) = event_index;
        end

        function record(S)
            S.history(end+1, :) = [S.now, sum(S.on_floor), sum(S.in_wash), sum(S.worker_busy), ...
                sum(ismember(S.state, {'incoming', 'unload', 'unloading'})), sum(strcmp(S.state, 'dirty')), ...
                sum(strcmp(S.state, 'ready')), sum(ismember(S.state, {'repair', 'return_wait', 'returning'})), ...
                sum(strcmp(S.state, 'shipped')), sum(strcmp(S.state, 'scrap'))];
        end

        function next = next_event(S)
            next = inf;
            if ~isempty(S.active), next = min([S.log(S.active).finish]); end
            future = [S.pipes(strcmp(S.state, 'incoming')).arrival];
            if ~isempty(future), next = min(next, min(future)); end
            close_time = floor(S.now/1440)*1440 + S.P.shift(2) - S.P.demobilize;
            if any(S.lane_day >= 0) && S.in_shift() && close_time > S.now + 1e-8
                next = min(next, close_time);
            end
            day = floor(S.now/1440);
            for d = day:day+7
                if mod(d, 7) >= 5, continue, end
                edges = d*1440 + S.P.shift;
                edges = edges(edges > S.now + 1e-8);
                if ~isempty(edges)
                    next = min(next, min(edges));
                    break
                end
            end
            if ~isfinite(next) || next <= S.now
                error('flow:Deadlock', 'No advancing event at minute %.2f; inspect the scenario configuration.', S.now);
            end
        end

        function R = results(S)
            R.P = S.P;
            R.C = S.C;
            R.pipes = struct2table(S.pipes);
            R.orders = S.orders;
            R.log = struct2table(rmfield(S.log, {'pipe', 'workers'}));
            R.log.pipe = {S.log.pipe}';
            R.log.workers = {S.log.workers}';
            R.log.completed = R.log.finish <= S.now + 1e-8;
            R.history = array2table(S.history, 'VariableNames', ...
                {'time', 'hall', 'wash', 'workers', 'incoming', 'dirty', 'ready', 'repair', 'shipped', 'scrap'});
            R.state = S.state;
            R.complete = S.complete;
            R.end_time = min(S.now, S.limit);
            R.shipped = sum(strcmp(S.state, 'shipped'));
            R.scrap = sum(strcmp(S.state, 'scrap'));
            R.ok = sum(strcmp(S.state, 'ready'));
            R.ready_repair = sum(strcmp(S.state, 'ready_repair'));
            R.remaining = S.N - R.shipped - R.scrap;
            if S.C.process_only, R.remaining = R.remaining - R.ok - R.ready_repair; end
            if ~S.complete
                warning('flow:Incomplete', '%d pipes unfinished after %g days. Increase C.max_days; inspect R.state and R.log.', ...
                    R.remaining, S.C.max_days);
            end
        end
    end
end
