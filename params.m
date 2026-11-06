function P = params()
% All model parameters. Time in minutes, t = 0 is Monday 00:00.
% Values are derived from the company's records unless marked (assumed);
% the task times in the hall are the 2021 study's.

P.seed = 1;                       % same seed, same run
P.days = 7;                       % simulated days
P.delta = 0.5;                    % time step (DELTA_TIME), minutes: firing times are
                                  % rounded to it (model_dyn), hand-offs take one step
P.shift = [7 15]*60;              % yard and hall work Mon-Fri 07-15
P.open = [7 15]*60;               % lorries arrive and tickets come in Mon-Fri 07-15,
                                  % also when the shift is longer (overtime)

% Arrivals. Receipts per weekday are negative binomial: busy and quiet days.
P.receipts_per_day = 6.7;         % mean per weekday, not counting joints back from
                                  % repair (the Repair module sends those)
P.receipts_r = 2.4;               % shape: smaller is burstier
P.receipts_weekday = [21.0 21.6 20.4 17.8 16.7];   % share of receipts Mon-Fri, %
P.p_long = 0.51;                  % share of receipts of long joints (13-14 m, short 9.5 m)
P.mean_joints = [66 8];           % mean joints per receipt [long short]
P.p_bypass = 0.23;                % share of receipts for storage only, no hall
P.backlog = 650;                  % hall joints queued in the yard at the start
P.N_in = inf;                     % drain test: arrivals stop after this many hall joints
P.in_at_zero = false;             % drain test: they all arrive at t = 0

% What inspection will find. Outcomes cluster by order: an order has
% machining, hardbanding or scrap with p_order, and then that share of its
% joints gets it (new_order); per joint 35%, 6% and 4%.
%           mach  hb    scrap
P.p_order = [0.45 0.13  0.15];
P.share   = [0.78 0.46  0.26];

% Deliveries: customer tickets only. Moves between sites and workshops are
% not demand on the stock.
P.tickets_per_day = 4.1;          % mean per weekday, negative binomial
P.tickets_r = 2.2;                % shape
P.tickets_weekday = [16.5 18.6 19.2 20.9 23.9];    % share of tickets Mon-Fri, %
P.mean_ticket = 35;               % mean joints per ticket
P.stock = 300;                    % rig-ready joints at the start
P.ship_ready = false;             % drain test: ship every rig-ready joint at once, no tickets
P.stop_clear = false;             % drain test: stop once every joint has arrived and the
                                  % hall, the wash and the yard's hall queue are empty

% Washing: one unit with two pumps (lanes), manned by one of the crew. One
% step per lane, its time the manned minutes per joint, set-up and
% changeovers included.
P.wash_lanes = 2;
P.wash_min = 2.2;                 % minutes per joint, one worker
P.wash_crew = {'L0', 'L1'};       % who may man the unit, lowest first (assumed): the L2
                                  % and the L3 stay in the hall for the steps only they do

% Inspection hall: an open floor that joints roll through in order. Whoever is
% free and qualified does the next step on a joint, wherever it lies.
P.hall_space = 70;                % joints on the hall floor at once
P.hall_buffer = 20;               % joints out of the yard and not yet on the floor:
                                  % at the wash or washed, waiting for room (assumed)
P.floor_start = 15;               % joints on the floor at the start
P.halls = 1;                      % 2: a second hall at Main, a copy of the first with its
                                  % own wash, floor and credits, starting empty. Both
                                  % share the crew, the yard and its forklifts; the next
                                  % order goes to the hall with the most room (next_joint)
P.crew = [5 5 1 1];               % people per level L0-L3, one pool for hall, wash and yard
P.certified = [2 1 0 0];          % of those, how many drive a forklift
P.pace = 0.92;                    % task time = 2021 time x pace, calibrated to the
                                  % median week of 803 joints inspected
% Steps: the 25 hall tasks grouped by level into 5 steps in hall order; a
% higher level can do lower work. L0 work comes before and after the
% inspection, so it is two steps. Set-up per order is left out.
%  name       s/joint  level  finds scrap  skipped if scrap    tasks
P.steps = {
  'Clean',    185,     0,     false,       false   % clean and blow dry connections, grind tong marks
  'Inspect',  870,     1,     true,        false   % gauge, UT wall, coating, MPI, heat check, RFID,
                                                   %   measurements, laser marking, restamp
  'Check',    151,     2,     true,        false   % thread visual, report, report check
  'UT',       96.2,    3,     true,        true    % UT/EMI scan
  'Finish',   198,     0,     false,       false   % field repair, paint, dope, cap
};
P.auto = {};                      % scenario: steps a machine does with no one at it, by
                                  % name ('Clean', 'UT', ...), and 'Wash' for the wash
                                  % unit; one machine per step, the same time

% Yard and logistics. Two yards: Main, by the hall, and Coop, about 8 min
% away. Every move of a joint in a yard is forklift work: a certified worker
% and a forklift at that yard. Loading or unloading a lorry needs
% P.lorry_helpers more people. The lorries between the yards are hired and
% booked ahead, so one is always there: only the drive takes time. Forklift
% work goes before hall work. Times are per bundle of P.bundle joints; the
% model works per joint. The records say nothing about the yards, so all
% values below are assumed.
P.forklifts = 2;                  % they start at Main
P.lorry_helpers = 2;              % people besides the forklift driver at a lorry
P.bundle = 6;                     % joints per forklift lift
P.t_unload  = 5;                  % lorry -> ground, per bundle
P.t_load    = 5;                  % ground -> lorry, per bundle
P.t_store   = 4;                  % rig-ready into a rack, per bundle
P.t_unstore = 4;                  % out of a rack, per bundle
P.t_feed    = 3;                  % yard -> wash rack, per bundle
P.lorry_drive = 10;               % Main <-> Coop by lorry
P.fork_drive  = 15;               % a forklift driven between the yards, one way
P.coop_in    = 0.2;               % share of receipts unloaded at Coop, per order;
                                  % their hall joints are fetched to Main by lorry
P.coop_ready = 0.15;              % share of hall orders whose rig-ready joints go to Coop
P.fetch_ahead = 150;              % a Coop bundle is fetched when it is within this many
                                  % joints of the front of the hall queue (about a day)
P.coop_batch = 20;                % joints of work waiting at Coop before a forklift goes
P.coop_wait  = 60;                % ... or minutes the first of them has waited

% Repair at outside workshops. The repair time is drawn per order, lognormal.
P.repair_median = [31 54];        % days [machining hardbanding]
P.repair_sigma  = [0.69 1.14];
P.p_reinspect   = [0.11 0.26];    % back through the hall; the rest go straight to stock

% The workshops start with the joints the hall sent them before the run:
% 143 hall joints a weekday over the last two years, kept if their repair
% is not done at t = 0.
P.inspected_per_day = 143;
P.workshop_history  = 730;        % days
