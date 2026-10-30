function P = params()
% All model parameters. Time unit: minutes, t = 0 is Monday 00:00.
% § numbers refer to data/model_datasheet.md.

P.seed = 1;                       % same seed, same run
P.days = 7;                       % simulated days
P.shift = [7 15]*60;              % yard and halls work Mon-Fri 07-15

% Arrivals (§2, §3). Receipts per weekday are negative binomial: busy days and
% quiet days, as in the data (variance 27 against a mean of 6.9).
P.receipts_per_day = 6.9;         % mean per weekday
P.receipts_r = 2.4;               % shape: smaller is burstier
P.receipts_weekday = [21.0 21.6 20.4 17.8 16.7];   % % of receipts Mon-Fri
P.p_long = 0.51;                  % DP, TBG, LS are long (13-14 m); HW, DC, NM short (9.5 m)
P.mean_joints = [66 8];           % mean joints per receipt [long short]
P.p_bypass = 0.23;                % Mobilization, RFID pairing, ...: storage only, no hall
P.unload = 0.5;                   % per joint
P.short_run = 23;                 % short joints the yard sends in one run, whole orders
                                  % (hall data: ~1 long/short switch a day, runs of 3 orders, 23 joints)
P.backlog = 650;                  % hall joints already queued in the yard at the start
                                  % (week study §3: 500-800; the business runs a deep queue)

% What inspection will find (§6). Outcomes cluster by order: an order has
% machining, hardbanding or scrap with p_order, and then that share of its
% joints get it. p_order.*share = [0.35 0.06 0.04] per joint. The data counts
% some joints twice (machining and hardbanding); the model gives each joint
% one outcome and keeps these rates (new_order).
%           mach  hb    scrap
P.p_order = [0.45 0.13  0.15];
P.share   = [0.78 0.46  0.26];    % Rig Return: joint % / P(order has it)

% Deliveries (§8)
P.tickets_per_day = 4.9;          % mean per weekday, negative binomial (variance 14)
P.tickets_r = 2.6;
P.tickets_weekday = [16.3 18.4 19.5 21.3 23.8];    % % of tickets Mon-Fri
P.mean_ticket = 37;               % mean joints per ticket
P.stock = 300;                    % rig-ready joints at the start (the real yard holds ~12,000, §9)

% Washing (§5.3). One automated unit with two pumps (two lanes), each lane set
% up for long or short joints. Someone from the crew mans the unit while it
% runs: mobilizes it once enough joints wait, does the changeovers, and
% demobilizes it when the queue is empty or the shift ends.
P.wash_lanes = 2;
P.wash_start = 10;                % joints waiting before the unit is mobilized (gut)
P.wash_crew = {'L0', 'L1'};       % who may man the unit, lowest first (gut): the one L2 and
                                  % the one L3 stay in the hall for the steps only they can do
P.mobilize   = 36.5;
P.demobilize = 9.8;
P.wash       = [200 90]/60;       % per joint [long short]
P.change     = 23.1;              % switch a lane between long and short

% Inspection hall: an open floor that joints roll through in order. Whoever is
% free and qualified does the next step on a joint, wherever it lies.
P.hall_space = 30;                % joints on the hall floor at once (gut)
P.hall_buffer = 20;               % joints out of the yard and not yet on the floor:
                                  % at the wash or washed, waiting for room (gut)
P.floor_start = 15;               % joints on the floor at the start: never empty, usually not full
P.crew = [2 3 1 1];               % people per level L0-L3, one shared crew for hall and wash
                                  % (4-7 seen at work in the hall; the work is ~26% L0,
                                  % 58% L1, 16% L2/L3)
% The 2021 task times add up to 25 min of work per joint; the real work goes
% faster. Calibrated to the data's median of ~800 inspected a week with this
% crew (2-day probe at pace 0.73: ~690 a week, crew ~95% busy). That is ~2.9
% joints per man-hour, wash included; the company's KPI of ~3.3 would need
% fewer people for the same output.
P.pace = 0.62;                    % task time = 2021 time x pace
% Steps: the 25 tasks of the 2021 report (Appendix A), grouped by level in
% roughly hall order, so each step needs the level its tasks need (a higher
% level can do lower work). Per-order setup and UT/EMI calibration are left
% out: tools stay out between orders.
%  name       s/joint  level  finds scrap  skipped if scrap    tasks
P.steps = {
  'Gauge',    140.5,   1,     true,        false   % 1-3      OD gauge, UT wall, coating
  'Clean',    185,     0,     false,       true    % 4,5,8    clean and blow dry connections, grind tong marks
  'NDT',      362.5,   1,     true,        true    % 6-7      MPI fluorescent, heat check
  'Threads',  84,      2,     true,        false   % 10       thread visual
  'Measure',  211.5,   1,     true,        false   % 9,11-13  RFID tags, measurements, length, HB check
  'UT',       96.2,    3,     true,        true    % 25       UT/EMI scan
  'Finish',   198,     0,     false,       false   % 15-18,20,21 field repair, paint, dope, cap
  'Mark',     155.5,   1,     false,       true    % 19,22    laser marking, restamp
  'Report',   67,      2,     false,       false   % 14,23    report, report check
};

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
