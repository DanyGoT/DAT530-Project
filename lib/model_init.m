function [] = model_init(P)
% Fill global_info for a run with parameters P. Call before pnstruct:
% inspection_pdf and the IMCs read the hall steps from it.

global global_info
rng(P.seed);

[pipes, repair] = gen_pipes(P);
[S, step_of] = step_list(P);
global_info.P = P;
global_info.S = S;
global_info.step_of = step_of;
global_info.pipes = pipes;
global_info.hall = pipes(strcmp({pipes.route}, 'hall'));   % in arrival order
global_info.repair = repair;                % days per order [machining hardbanding]
global_info.workshop = {zeros(0, 2), zeros(0, 2)};  % [done again] per joint at each workshop
global_info.demand = gen_demand(P);
global_info.next_pipe = 1;
global_info.next_hall = 1;
global_info.next_demand = 1;
global_info.STOP_AT = P.days*1440;
global_info.DELTA_TIME = 0.25;  % 15 s
