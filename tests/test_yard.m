% Arrival and yard on their own, 2 days. Every joint is unloaded into the
% right place, and every hall joint that leaves for the wash leaves in order.

clear all; clc;
global global_info

P = params();
P.seed = 4;                     % a seed with arrivals from Monday
P.days = 2;
model_init(P);
pns = pnstruct({'arrival_pdf', 'yard_pdf', 'imc_arrival_yard'});
pni = initialdynamics(pns, model_dyn(P, pns));
Sim_Results = gpensim(pni);

pipes = global_info.pipes;
hall = strcmp({pipes.route}, 'hall');
long = strcmp({pipes.len}, 'long');
assert(numel(pipes) > 0, 'no joints arrived');
assert(global_info.next_pipe - 1 == numel(pipes), 'not every joint was unloaded');
assert(ntokens('pYReady') == P.stock + sum(not(hall)), 'bypass joints missing from stock');
assert(ntokens('pYLong')  + timesfired('tYLong')  == sum(hall & long),     'long joints lost');
assert(ntokens('pYShort') + timesfired('tYShort') == sum(hall & not(long)), 'short joints lost');
assert(global_info.next_hall - 1 == timesfired('tYLong') + timesfired('tYShort'), 'yard out of order');
disp(['test_yard: ok (', int2str(numel(pipes)), ' joints)']);
