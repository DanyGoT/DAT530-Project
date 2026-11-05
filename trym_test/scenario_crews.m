% Scenario: the same batch through the hall with different crews, followed
% until every joint is rig-ready (repairs included) or scrap. Each crew gets
% the same joints, findings and repair times (same seed), so only the crew
% differs. Steps are done in the order of P.steps for each joint, while the
% crew works on different joints at different steps at the same time; a
% step needs a worker of its level or higher (params.m).
%
% Run:  scenario_crews          (after adding the project and GPenSIM to the path)
% Takes a while: one run per crew. To run only some of them, set e.g.
% only = [1 3]; before calling the script.

clearvars -except only; clc;
trym_test_setup(true);

%% ---------------- Scenario settings ----------------
B.batch       = 800;        % joints (pipes) in the delivery
B.arrive_day  = 0;          % 0 = Monday
B.arrive_at   = 8*60;       % 08:00
B.order_size  = 30;         % joints per customer order
B.short_pct   = 10;         % % of the orders that are short joints
B.mach_pct    = 35;         % % of the joints that need machining
B.hb_pct      = 6;          % % of the joints that need hardbanding
B.scrap_pct   = 4;          % % of the joints that are scrapped
B.until       = 'ready';    % follow the repairs until every joint is rig-ready or scrap
B.max_days    = 1500;

%           L0 L1 L2 L3   name
crews = {  [2  3  1  1],  'One L3 (params.m crew)'
           [2  3  1  3],  'Three L3'
           [2  2  1  1],  '6 workers, balanced'
           [3  3  3  3],  '12 workers, balanced' };

if not(exist('only', 'var')), only = 1:size(crews, 1); end

%% ---------------- Run and report ----------------
for i = only
    P = params();
    P.crew = crews{i, 1};
    r = run_batch(P, B);
    print_batch(r, crews{i, 2});
    R(i) = rmfield(r, 'Sim_Results');           % keep the summaries only
end

fprintf('\n=== Comparison: %d joints, days after arrival ===\n', B.batch);
fprintf('%-26s %-11s %6s %12s %12s %10s %10s %10s\n', 'crew', 'L0-L3', 'people', ...
        'washed', '1st pass', '50% ready', '90% ready', 'all ready');
for i = only
    r = R(i);
    d = @(t) (t - r.t0)/1440;
    q = @(p) d(r.t_ready(min(numel(r.t_ready), ceil(p*B.batch))));
    fprintf('%-26s %-11s %6d %12.1f %12.1f %10.1f %10.1f %10.1f\n', crews{i, 2}, ...
            mat2str(r.P.crew), sum(r.P.crew), d(r.when.tWOut(2)), d(r.t_hall(end)), ...
            q(0.5), q(0.9), q(1));
end