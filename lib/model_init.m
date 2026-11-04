function [] = model_init(P)
% Fill global_info for a run with parameters P. Call before pnstruct:
% inspection_pdf reads the hall steps from it.

global global_info
rng(P.seed);

[pipes, repair, backlog, floor] = gen_pipes(P);
[workshop, repair] = gen_workshop(P, repair);
[S, step_of] = step_list(P);
global_info.P = P;
global_info.S = S;
global_info.step_of = step_of;
global_info.demand = gen_demand(P);

% Which yard, per order: where the receipt is unloaded (coop_in) and where its
% rig-ready joints are stored (to_coop). Drawn from a stream of their own, so
% arrivals, outcomes and demand stay the same as without the yards.
yards = RandStream('mt19937ar', 'Seed', P.seed + 1e6);
orders = size(repair, 1);
coop_in = rand(yards, 1, orders) < P.coop_in;
to_coop = rand(yards, 1, orders) < P.coop_ready;
pipes = with_yard(pipes, coop_in);
backlog = with_yard(backlog, coop_in);
hall = [backlog, pipes(strcmp({pipes.route}, 'hall'))];   % in arrival order
for k = 1:numel(hall), hall(k).id = k; end

global_info.pipes = pipes;
global_info.backlog = backlog;              % hall joints in the yards at t = 0
global_info.hall = hall;                    % hall joints, in the order the yard sends them
global_info.floor = floor;                  % joints on the hall floor at t = 0
global_info.repair = repair;                % days per order [machining hardbanding]
global_info.workshop = workshop;            % [done again] per joint at each workshop
global_info.to_coop = to_coop;              % per order: rig-ready joints go to Coop
% Hall joints unloaded at Coop, by id (their place in the first hall list):
% 0 not there yet, 1 at Coop, 2 on a lorry to Main, 3 at Main. The queue at the
% start is there already; the others arrive in this order (coop_ids).
global_info.cstate = zeros(1, numel(hall));
global_info.cstate([hall(1:numel(backlog)).coop]) = 1;
global_info.coop_ids = numel(backlog) + find([hall(numel(backlog)+1:end).coop]);
global_info.coop_next = 1;                  % the next of coop_ids to be unloaded
global_info.lorry = zeros(0, 3);            % on a lorry to Main: [id, time it left Coop, long]
global_info.coop_q = zeros(0, 1);           % on a lorry to Coop: time it left Main
global_info.forks_coop = 0;                 % forklifts at Coop or on their way there
global_info.ship_coop = nan;                % the next joint asked for comes from Coop (drawn once)
global_info.coop_since = nan;               % since when work has waited at Coop with no forklift
global_info.yard_wants = -inf;              % last time forklift work found no driver free
global_info.yard_helpers = -inf;            % ... or a lorry no helpers
W = yard_work(P);
global_info.lorry_job = containers.Map(W.name, W.lorry);   % loads or unloads a lorry
global_info.next_pipe = 1;
global_info.next_hall = 1;
global_info.run = 0;                        % short joints sent in the yard's current run
global_info.next_floor = 1;
global_info.next_demand = 1;
global_info.yard_out = zeros(0, 3);         % per hall joint the yard sends on: [time, received, order]
global_info.floor_in = zeros(0, 2);         % per joint onto the floor from the wash: [time, order]
global_info.hall_out = zeros(0, 3);         % per joint leaving the hall: [time, order, how 1-4]
                                            % (order 0: back from repair, its order not kept)
global_info.clear_at = nan;                 % drain test: when the hall was clear (P.stop_clear)
global_info.STOP_AT = P.days*1440;
global_info.DELTA_TIME = 0.25;  % 15 s
global_info.NO_COLORMAP = true; % no colour history: ~6x faster, same results (patch in
                                % gpensim/Firing-Transition/firing_complete_one.m)


function joints = with_yard(joints, coop_in)
% Each joint gets coop (unloaded at Coop) from its order, and an id (0 here;
% hall joints are numbered once they are in the hall list).
for k = 1:numel(joints)
    joints(k).coop = coop_in(joints(k).order);
    joints(k).id = 0;
end
if isempty(joints)
    joints = struct('t', {}, 'route', {}, 'len', {}, 'find', {}, 'order', {}, 'coop', {}, 'id', {});
end
