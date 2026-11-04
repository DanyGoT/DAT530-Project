function P = params()
% All model parameters. Time unit: minutes, t = 0 is Monday 00:00.
% § numbers refer to data/model_datasheet.md.

P.seed = 1;                       % same seed, same run
P.days = 7;                       % simulated days
P.delta = 0.5;                    % GPenSIM's time step (DELTA_TIME), minutes. Firing times are
                                  % rounded to it (model_dyn); hand-offs take one step. 0.5 runs
                                  % twice as fast as 0.25 and inspects 1.5-5% less (2026-11-04)
P.shift = [7 15]*60;              % yard and halls work Mon-Fri 07-15
P.open = [7 15]*60;               % lorries arrive and tickets come in Mon-Fri 07-15;
                                  % stays put when the shift changes (overtime)

% Arrivals (§2, §3). Receipts per weekday are negative binomial: busy days and
% quiet days, as in the data (variance 27 against a mean of 6.9).
P.receipts_per_day = 6.7;         % mean per weekday: the data's 6.9 less the 3% that are
                                  % joints back from a workshop (§12), which the model
                                  % already sends back to the hall (p_reinspect)
P.receipts_r = 2.4;               % shape: smaller is burstier
P.receipts_weekday = [21.0 21.6 20.4 17.8 16.7];   % % of receipts Mon-Fri
P.p_long = 0.51;                  % DP, TBG, LS are long (13-14 m); HW, DC, NM short (9.5 m)
P.mean_joints = [66 8];           % mean joints per receipt [long short]
P.p_bypass = 0.23;                % Mobilization, RFID pairing, ...: storage only, no hall
P.backlog = 650;                  % hall joints already queued in the yard at the start
                                  % (week study §3: 500-800; the business runs a deep queue)
P.N_in = inf;                     % drain test: arrivals stop after this many hall joints
P.in_at_zero = false;             % drain test: they all arrive at t = 0

% What inspection will find (§6). Outcomes cluster by order: an order has
% machining, hardbanding or scrap with p_order, and then that share of its
% joints get it. p_order.*share = [0.35 0.06 0.04] per joint. The data counts
% some joints twice (machining and hardbanding); the model gives each joint
% one outcome and keeps these rates (new_order).
%           mach  hb    scrap
P.p_order = [0.45 0.13  0.15];
P.share   = [0.78 0.46  0.26];    % Rig Return: joint % / P(order has it)

% Deliveries (§8): customer tickets only. Internal tickets (Repair_YN = Yes,
% 0.74 a weekday, ~49 joints) move pipe between sites and repairers and aren't
% demand on the yard's stock, so they are left out.
P.tickets_per_day = 4.1;          % mean per weekday, negative binomial (variance 12)
P.tickets_r = 2.2;
P.tickets_weekday = [16.5 18.6 19.2 20.9 23.9];    % % of tickets Mon-Fri
P.mean_ticket = 35;               % mean joints per ticket (median 10, p90 100)
P.stock = 300;                    % rig-ready joints at the start (the real yard holds ~12,000, §9)
P.ship_ready = false;             % drain test: ship every rig-ready joint at once, no tickets
P.stop_clear = false;             % drain test: stop once every joint has arrived and the
                                  % hall, the wash and the yard's hall queue are empty

% Washing (§5.3). One automated unit with two pumps (lanes); someone from the
% crew mans it. Not a bottleneck (the company), so it is one step per lane.
% Its time is the manned minutes per joint of the detailed wash it replaces
% (mobilize 36.5 min, demobilize 9.8, 200/90 s per long/short joint per lane,
% 23-min long/short changeovers; tag pre-simplify): 2.0-2.5 in 3-day runs.
P.wash_lanes = 2;
P.wash_min = 2.2;                 % minutes per joint, one worker
P.wash_crew = {'L0', 'L1'};       % who may man the unit, lowest first (gut): the one L2 and
                                  % the one L3 stay in the hall for the steps only they can do

% Inspection hall: an open floor that joints roll through in order. Whoever is
% free and qualified does the next step on a joint, wherever it lies.
P.hall_space = 70;                % joints on the hall floor at once (company, 2026-11-03)
P.hall_buffer = 20;               % joints out of the yard and not yet on the floor:
                                  % at the wash or washed, waiting for room (gut)
P.floor_start = 15;               % joints on the floor at the start: never empty, usually not full
P.crew = [5 5 1 1];               % people per level L0-L3, one pool for hall, wash and yard
                                  % (4-7 seen at work in the hall, others elsewhere; the hall
                                  % work is ~26% L0, 58% L1, 16% L2/L3). 12 people: the 7 the
                                  % hall alone was calibrated with, plus ~5 people's worth of
                                  % forklift and lorry work at the gut yard times below
                                  % (3 people per lorry job). To be calibrated.
P.certified = [3 1 0 0];          % of those, how many hold a forklift certificate (gut)
% The 2021 task times add up to 25 min of work per joint; the real work goes
% faster. Calibrated to the data's median of ~800 inspected a week with this
% crew (2-day probe at pace 0.73: ~690 a week, crew ~95% busy). That is ~2.9
% joints per man-hour, wash included; the company's KPI of ~3.3 would need
% fewer people for the same output.
P.pace = 0.62;                    % task time = 2021 time x pace
% Steps: the 25 tasks of the 2021 report (Appendix A), grouped by level into
% 5 steps in hall order, so each step needs the level its tasks need (a higher
% level can do lower work). L0 work comes before and after the inspection, so
% it stays two steps. Per-order setup and UT/EMI calibration are left out:
% tools stay out between orders. (Before simplifying: 9 steps, tag
% pre-simplify; the minutes per level are the same.)
%  name       s/joint  level  finds scrap  skipped if scrap    tasks
P.steps = {
  'Clean',    185,     0,     false,       false   % 4,5,8    clean and blow dry connections, grind tong marks
  'Inspect',  870,     1,     true,        false   % 1-3,6-7,9,11-13,19,22  gauge, UT wall, coating, MPI,
                                                   %   heat check, RFID, measurements, laser marking, restamp
  'Check',    151,     2,     true,        false   % 10,14,23 thread visual, report, report check
  'UT',       96.2,    3,     true,        true    % 25       UT/EMI scan
  'Finish',   198,     0,     false,       false   % 15-18,20,21 field repair, paint, dope, cap
};
P.auto = {};                      % scenario: steps a machine does with no one at it, by
                                  % name ('Clean', 'UT', ...), and 'Wash' for the wash
                                  % unit; one machine per step, the same time

% Yard and logistics. Two yards: Main (by the hall) and Coop (~8 min walk
% away, not in the system). Ogna and the named places are left out. Every
% move of a joint in a yard is forklift work: a certified worker from the pool
% and a forklift at that yard. Loading or unloading a lorry also needs
% P.lorry_helpers more people (2021 report: "two on the truck, one on the
% electric truck"). Lorries between the yards are rented: no waiting for one,
% no limit, only the drive. Forklift work goes before hall work.
% Times are per bundle of P.bundle joints; the model works per joint.
P.forklifts = 2;                  % they start at Main
P.lorry_helpers = 2;              % people besides the driver at a lorry (2021 report)
P.bundle = 6;                     % joints per forklift lift (gut; the 2021 report: "it varies")
P.t_unload  = 5;                  % lorry -> ground, per bundle (2021 report: ~5 min)
P.t_load    = 5;                  % ground -> lorry, per bundle (gut: as unloading)
P.t_store   = 4;                  % rig-ready into a rack, per bundle (gut)
P.t_unstore = 4;                  % out of a rack, per bundle (gut)
P.t_feed    = 3;                  % yard -> wash rack, per bundle (gut)
P.lorry_drive = 10;               % Main <-> Coop by lorry (gut; 8 min on foot)
P.fork_drive  = 15;               % a forklift driven between the yards, one way (gut: slow)
P.coop_in    = 0.2;               % share of receipts unloaded at Coop, per order (gut);
                                  % hall bundles there are fetched to Main by lorry
P.coop_ready = 0.15;              % share of hall orders whose rig-ready joints go to Coop
                                  % (gut; the 'Temp' racks hold ~12% of rig-ready stock)
P.fetch_ahead = 150;              % a Coop bundle is fetched when it is within this many
                                  % joints of the front of the hall queue (gut: ~a day)
P.coop_batch = 20;                % joints of work waiting at Coop before a forklift goes
P.coop_wait  = 60;                % ... or minutes the first of them has waited (gut)

% Repair at external workshops (§7). The repair time is drawn per order,
% lognormal, fitted to inspection -> completed in Orders (median, p25-p75).
P.repair_median = [31 54];        % days [machining hardbanding]
P.repair_sigma  = [0.69 1.14];
P.p_reinspect   = [0.11 0.26];    % back through the hall; the rest go straight to rig-ready

% The workshops start with the joints the hall sent them before the run:
% 143 hall joints a weekday (§5, mean) over the last two years, kept if their
% repair is not done yet at t = 0.
P.inspected_per_day = 143;
P.workshop_history  = 730;        % days
