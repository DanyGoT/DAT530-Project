% Paired seeds: does a scenario see the same inputs as the baseline with the
% same seed? model_init draws the arrivals, the starting backlog and floor,
% the open repairs and the delivery tickets from P.seed. A change that alters
% those draws (how many, or when) breaks the pairing. No simulation; seconds.
% The draws during the run (where scrap is found, re-inspection after
% repair) are not paired: they come from the same stream after model_init,
% in whatever order the run asks for them.

clear all; clc;
global global_info

changes = {
  'hall_space 45',   'hall_space',       45
  'crew [2 4 1 1]',  'crew',             [2 4 1 1]
  'crew [2 3 1 0]',  'crew',             [2 3 1 0]
  'shift 07-17',     'shift',            [7 17]*60
  'wash_lanes 3',    'wash_lanes',       3
  'pace x1.1',       'pace',             0.62*1.1
  'receipts x1.2',   'receipts_per_day', 6.7*1.2
  'backlog 2500',    'backlog',          2500
  'days 28',         'days',             28
};
inputs = {'pipes', 'backlog', 'floor', 'workshop', 'demand', 'repair'};

for seed = 1:3
    P = params();
    P.seed = seed;
    model_init(P);
    base = global_info;
    fprintf('seed %d (baseline: %d arrivals, %d in backlog, %d asked for)\n', ...
            seed, numel(base.pipes), numel(base.backlog), numel(base.demand));
    for k = 1:size(changes, 1)
        Q = P;
        Q.(changes{k, 2}) = changes{k, 3};
        model_init(Q);
        same = cellfun(@(f) isequaln(global_info.(f), base.(f)), inputs);
        fprintf('  %-16s %s\n', changes{k, 1}, verdict(same, inputs));
    end
end


function s = verdict(same, inputs)
if all(same)
    s = 'same inputs';
else
    s = ['differ: ', strjoin(inputs(not(same)), ', ')];
end
end
