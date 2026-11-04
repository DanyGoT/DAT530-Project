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
global_info.pipes = pipes;
global_info.backlog = backlog;              % hall joints in the yard at t = 0
global_info.hall = [backlog, pipes(strcmp({pipes.route}, 'hall'))];   % in arrival order
global_info.floor = floor;                  % joints on the hall floor at t = 0
global_info.repair = repair;                % days per order [machining hardbanding]
global_info.workshop = workshop;            % [done again] per joint at each workshop
global_info.demand = gen_demand(P);
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
