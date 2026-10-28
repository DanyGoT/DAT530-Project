function P = params()
% All model parameters. Time unit: minutes, t = 0 is Monday 00:00.
% § numbers refer to data/model_datasheet.md.

P.seed = 1;                       % same seed, same run
P.days = 7;                       % simulated days
P.shift = [7 15]*60;              % yard and halls work Mon-Fri 07-15

% Arrivals (§2, §3)
P.receipts_per_day = 6.9;         % per weekday
P.p_long = 0.51;                  % DP, TBG, LS are long (13-14 m); HW, DC, NM short (9.5 m)
P.mean_joints = [66 8];           % mean joints per receipt [long short]
P.p_bypass = 0.23;                % Mobilization, RFID pairing, ...: storage only, no hall
P.unload = 0.5;                   % per joint

% What inspection will find, per joint (§6, weighted over the scopes that use the hall)
P.p_mach  = 0.35;
P.p_hb    = 0.06;
P.p_scrap = 0.04;

% Deliveries (§8)
P.tickets_per_day = 4.9;          % per weekday
P.mean_ticket = 37;               % mean joints per ticket
P.stock = 300;                    % rig-ready joints at the start (the real yard holds ~12,000, §9)

% Washing (§5.3)
P.wash_buffer = 5;                % joints the yard keeps queued at the wash
P.mobilize   = 36.5;
P.demobilize = 9.8;
P.wash       = [200 90]/60;       % per joint [long short]
P.change     = 23.1;              % switch the machine between long and short

% Inspection hall: an open floor that joints roll through in order. Whoever is
% free and qualified does the next step on a joint, wherever it lies.
P.hall_space = 30;                % joints on the hall floor at once (gut)
P.crew = [2 2 1 1];               % people per certificate level L0-L3 (gut: ~6 in the hall)
% Steps: the 25 tasks of the 2021 report (Appendix A) in hall order, grouped.
% Level is the highest any task in the step needs; a higher level can do lower work.
% Per-order setup and UT/EMI calibration are left out: tools stay out between orders.
%  name       s/joint  level  finds scrap  skipped if scrap    tasks
P.steps = {
  'Gauge',    140.5,   1,     true,        false   % 1-3    OD gauge, UT wall, coating
  'Clean',    173.5,   0,     false,       true    % 4-5    clean connections, grind tong marks
  'NDT',      362.5,   1,     true,        true    % 6-7    MPI fluorescent, heat check
  'Threads',  148.5,   2,     true,        false   % 8-10   blow dry, RFID tags, thread visual
  'Measure',  158.5,   1,     true,        false   % 11-13  measurements, length, HB check
  'UT',       96.2,    3,     true,        true    % 25     UT/EMI scan
  'Finish',   215,     0,     false,       true    % 15-21  field repair, paint, laser mark, dope, cap
  'Report',   205.5,   2,     false,       false   % 14,22,23 report, restamp, report check
};

% Repair at external workshops (§7)
P.repair_days = [30 45];          % [machining hardbanding]
