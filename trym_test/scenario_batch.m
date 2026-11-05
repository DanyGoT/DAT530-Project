% Scenario: one batch of pipes arrives, is washed and inspected, and every
% joint ends up in the yard (ok -> rig-ready stock, scrap -> scrap rack) or
% at a repair workshop (machining / hardbanding), and from there back to
% rig-ready stock (some through the hall again).
% The yard, wash and hall start empty, nothing else arrives and nobody
% collects stock. The run stops when every joint is done (B.until), or after
% B.max_days at the latest. Idle time (nights, weekends, weeks of waiting for
% repairs) is skipped, so following the repairs costs little run time.
% Crew, wash and step times, shift and repair times come from params.m.
% The report shows when each stage was done and the time spent at each
% inspection step. scenario_crews.m compares several crews.
%
% Run:  scenario_batch          (after adding the project and GPenSIM to the path)

clear all; clc;
trym_test_setup(true);

%% ---------------- Scenario settings ----------------
B.batch       = 300;        % joints (pipes) in the delivery
B.arrive_day  = 0;          % 0 = Monday, 1 = Tuesday, ...
B.arrive_at   = 8*60;       % minutes after midnight (08:00)
B.order_size  = 30;         % joints per customer order (300 -> 10 orders)
B.short_pct   = 10;         % % of the orders that are short joints (the rest are long)
B.mach_pct    = 35;         % % of the joints that need machining      (params.m: ~35)
B.hb_pct      = 6;          % % of the joints that need hardbanding    (params.m: ~6)
B.scrap_pct   = 4;          % % of the joints that are scrapped        (params.m: ~4)
B.until       = 'ready';    % 'ready': until every joint is rig-ready or scrap (repairs included)
                            % 'hall':  until every joint is out of the hall (faster)
B.max_days    = 1500;       % stop after this many days even if not done (repairs have a long tail)

P = params();
% P.crew = [2 3 1 1];      % people per level L0-L3; change to try another crew

%% ---------------- Run and report ----------------
R = run_batch(P, B);
print_batch(R, sprintf('Batch of %d joints', B.batch));

% prnschedule(R.Sim_Results);                                     % every worker's tasks (very long)
plotp(R.Sim_Results, {'pYLong', 'pYShort', 'pWRack', 'pWI'});     % waiting for wash / hall
plotp(R.Sim_Results, {'pISpace'});                                % free room on the hall floor
plotp(R.Sim_Results, {'pYReady', 'pYScrap', 'pRMach', 'pRHb'});   % where joints end up