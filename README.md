# DAT530-Project

A GPenSIM model of the Ocean IMR pipe yard, at the level of single joints:
joints arrive, wait in the yard, are washed, inspected on the hall floor by a
small team, and go to stock, a workshop or scrap. Stock is shipped on delivery
tickets.

```
Arrival ──▶ Yard ──▶ Washing ──▶ Inspection hall ──▶ Yard (stock / scrap) ──▶ Departure
             │ bypass ─▶ stock         ▲           │
             │                         └─ Repair ◀─┘ machining / hardbanding
```

## Layout

| | |
|---|---|
| `project_pn.m` | main simulation file |
| `params.m` | every parameter, with its source in `data/model_datasheet.md` |
| `modules/<module>/` | one Petri module each: its PDF, `MOD_<Name>_PRE.m` and `MOD_<Name>_POST.m` |
| `imc/` | the inter-modular connectors: the places between two modules, and arcs to their ports |
| `COMMON_PRE.m` | the interface: what each port takes and which colours it hands on |
| `trym_test/` | Trym's scenarios, event-driven modules/connectors, helpers, tests and saved results; see [its README](trym_test/README.md) |
| `lib/` | joint, demand and start-state generators, the hall step list, run setup, token helpers |
| `tests/` | one test per module or group of modules, and stub connectors for the ports a test leaves open |
| `analysis/` | `analysis_pn.m`: P-invariants of the whole net and an upper bound on what the crew can inspect; no simulation |

The course flake puts every folder on `MATLABPATH` when you enter `nix develop`.

## Modules

The net follows the lecture's rules for modular Petri nets (P4-L01, P4-L03).
Tokens enter a module only through its input ports and leave only through its
output ports; both are transitions, declared in `png.set_of_Ports`. An input
port takes from a connector and puts only into its own module; an output port
takes only from its own module and puts into a connector. A module's places
and other transitions have no arcs to anything outside it. The places between
modules belong to the connectors in `imc/`.

GPenSIM runs `COMMON_PRE` only for ports, and `MOD_<Name>_PRE` for every
transition of that module, so a module's inner workings live in its own files.
For a port both run and must both say yes: the MOD file decides *when* (shift,
order, timing), `COMMON_PRE` decides *what* (which joint, which colours).

| Module | Input ports | Output ports |
|---|---|---|
| Arrival | — | `tALong`, `tAShort`, `tABypass` |
| Yard | `tYInLong`, `tYInShort`, `tYInBypass`, `tYInOk`, `tYInScrap`, `tYInRepaired`, `tYRoom` (a credit), `tYOrder` (a joint asked for) | `tYLong`, `tYShort` (to the wash), `tYShip` (a joint) |
| Washing | `tWIn` (from `pYW` onto its rack) | `tWOut` (washed, to `pWI`) |
| Inspection | `tIIn` (washed), `tIInRepair` | `tIOk`, `tIScrap`, `tIMach`, `tIHb`, `tIRoom` (the credit back) |
| Repair | `tRInMach`, `tRInHb` | `tRMachHall`, `tRHbHall`, `tRMachReady`, `tRHbReady` |
| Departure | `tDShip` | `tDTicket` |

A connector's places are named by the two modules' letters: `pAYLong`
(Arrival → Yard), `pYW`, `pWI`, `pIYOk`, `pIYScrap`, `pIYRoom`, `pIRMach`,
`pIRHb`, `pRI`, `pRYReady`, `pDYOrder`, `pYDOut`.

## How it works

- **Arrivals and tickets are bursty**: the number per weekday is negative
  binomial (busy and quiet days), with more receipts on Mondays and more tickets
  on Fridays, as in the data. What inspection will find is drawn per order
  first, then per joint, because a bad order sends most of its joints to the
  workshop together. A joint gets one outcome (scrap before machining before
  hardbanding); the draw is corrected for that order, so the rates per joint
  stay at the data's 35% machining, 6% hardbanding and 4% scrap.
- **Nothing starts empty.** At Monday 00:00, all drawn as ordinary orders:
  `P.backlog` hall joints (650; the data says 500-800) wait in the yard,
  `P.floor_start` joints (15) lie on the hall floor, `P.stock` joints are in
  rig-ready stock, and the workshops hold the joints the hall sent them over
  the last two years whose repair isn't done yet (~1400 machining, ~900
  hardbanding at seed 4).
- **Token = one joint.** In the yard a joint's kind is the place it is in
  (`pYLong`, `pYShort`, `pYReady`). In the wash and the hall it carries colours:
  its length, what inspection will find (`ok`, `mach`, `hb`, `scrap`), its order,
  and `scrapped` once inspection has found the scrap. Joints for the workshops
  keep only their order. GPenSIM copies every coloured token after each firing,
  so colourless joints elsewhere keep runs fast.
- **One shared crew.** Workers L0-L3 are GPenSIM resources (`P.crew`, now
  7 people). A higher level can do lower-level work (`requestAR`, lowest level
  asked first), but not while a joint waits at a step of their own level: the
  one L3 stays free for UT, the one L2 for threads and reports. The same
  people inspect and man the wash, and joints per man-hour counts them all.
- **Short runs.** The yard sends hall joints in arrival order, whole orders at
  a time, except that short orders go in runs: when a short order is done and
  the run is under `P.short_run` joints (23), the next short order already in
  the yard goes next. The hall data shows ~1 long/short switch a day and short
  runs of ~3 orders, ~23 joints; strict arrival order switches several times
  as often, and each switch costs the wash a 23-min changeover.
- **Washing** is one unit with two lanes (two pumps). It takes joints from the
  yard onto its rack (`pWRack`) and washes them in the order they came. A free
  L0 or L1 worker (`P.wash_crew`, lowest first) mobilizes it once
  `P.wash_start` joints wait and stays with it until it is demobilized: when
  the queue is empty, or when nothing more fits before the shift ends. L2 and
  L3 never man it: otherwise the one L3 can stand at the wash for hours while
  joints pile up at UT. Each lane
  is set up for long or short joints; changing over takes 23 min. Lanes stay
  set up for long joints (nine in ten), and one at a time goes over to short.
- **The hall buffer.** The yard sends a joint to the wash only with a credit
  (`pYRoom`), and the hall hands the credit back (`pIRoom` → `pIYRoom` →
  `pYRoom`) when the joint comes onto the floor. So at most `P.hall_buffer` joints are between the yard and the floor:
  at the wash, or washed and waiting for room.
- **The hall** is an open floor joints roll through in order, with room for
  `P.hall_space` joints. The 25 tasks of the 2021 report are grouped by level
  into 9 steps (`P.steps`). Task times are the report's times x `P.pace`,
  calibrated to the data's ~800 inspected a week with this crew (~2.9 joints
  per man-hour; the company's KPI says ~3.3). Whoever in the
  crew is free and has the level does the next step on a joint; each step has
  one transition per qualified person, so several joints can be at the same
  step at once.
- **Scrap** is found at one of the steps that can find it, each equally likely.
  Found scrap skips the steps it doesn't need.
- **Repair** time is drawn per order (lognormal, median 31 d machining, 54 d
  hardbanding), and covers the whole round trip. Then 11% (machining) or 26%
  (hardbanding) of the joints go through the hall again; the rest go to
  rig-ready stock. Joints at the workshops are colourless;
  `global_info.workshop` keeps when each is done. Routing the round trip
  through the yard (waiting for transport out, received back) is not modelled
  yet.
- Yard and halls work Mon-Fri 07-15; arrivals, tickets and workshops don't stop.
- Runs are repeatable: `P.seed` fixes the random numbers.

## Running

```matlab
project_pn                      % one week; prints a summary, worker use and plots
test_yard; test_wash; test_repair; test_hall; test_model
analysis_pn                     % invariants and crew bound, in seconds
```

Change `params.m`, or set fields after `P = params();` in `project_pn.m`
(e.g. `P.crew = [3 2 0 2];` for the 2021 report's crew).

### Finite lifecycle experiments (no GPenSIM required)

All new experiments now live in `trym_test/`. The original `modules/`, `imc/`,
`lib/`, `tests/`, `params.m` and `project_pn.m` remain in their original locations.
The new runner is split by process under `trym_test/modules/`; its connectors
are under `trym_test/imc/` and its event engine is under `trym_test/lib/`.
This matches the class folder layout, but remains event-driven MATLAB,
not GPenSIM PDFs. Shared parameters and order generation still come from
the original project. See [the structure and entry points](trym_test/README.md).

`scenario_flow` is a separate event-driven MATLAB runner, not a replacement
for the Petri net. It reads `params.m` and reuses `new_order` for order sizes,
lengths, clustered defects and per-order repair durations. No random traffic,
old workshop stock or customer demand is added beyond the specified population.
All these pipes require washing and inspection (the bypass probability is
deliberately ignored). The final order in each population is truncated to
keep the exact total.

From MATLAB (not PowerShell):

```matlab
cd('C:\Users\Trym\DAT_530\DAT530-Project\trym_test')
scenario_flow                         % 100 pipes: 50 waiting, 50 arriving
scenario_flow('baseline', 800)        % 800 pipes: 400 waiting, 400 arriving
scenario_flow('all', 100)             % seven one-change-at-a-time experiments
results = scenario_flow({'baseline','promote'}, 800);
test_flow                            % small automated lifecycle/resource tests
```

The entry point adds the project subfolders to MATLAB's path automatically.
Change `flow_config.m` for logistics/equipment assumptions; change `params.m`
for the default crew, step times/levels, shift and repairs. For arbitrary
combinations without plotting/saving:

```matlab
trym_test_setup()
P = params();
C = flow_config(P);
C.total = 800; C.initial = 400;
P.crew = [3 3 3 3];
C.certified = [1 1 2 2];             % counts within each level, separate from competence
C.forklifts = 2;
P.wash_lanes = 4;
C.step_machines(6) = 2;             % e.g. two simultaneous UT jobs
R = run_flow(P, C);
print_flow(R, 'My experiment');
```

**Flow and resource rules**

- Initial pipes are already unloaded in the dirty yard. Incoming orders arrive
  from Monday 08:00, one hour apart by default. Unloading is per pipe, with
  three shared workers including one certified forklift driver.
- Yard-to-wash, wash-to-hall, hall-to-yard and repair-return movements each
  need one certified worker and a forklift. These are the same individual
  workers who inspect and wash: a worker cannot do two jobs simultaneously.
- Washing uses one worker per active lane, unlike the Petri net's single
  attendant across lanes. Each lane needs mobilization at its first wash
  of a shift, changeover on a length change and staffed demobilization when
  finished or at shift end. Workers are released between lane jobs; they
  do not remain assigned while a lane is idle. No minimum ten-pipe startup
  threshold applies, so finite batches can always drain.
- Washed pipes retain wash-floor space until their transfer into the
  inspection hall finishes. A pipe reserves hall space when that transfer
  starts, and retains it **until its hall-to-yard movement finishes**.
  Inspection cannot start on new pipes if those positions remain occupied.
- Every pipe follows `P.steps` in order, with one qualified worker per
  step, subject to a configurable simultaneous-machine limit for each step.
  Higher levels may do lower-level work. Scrap detection/skipping follows
  the step table, and remaining non-skipped work is completed before removal.
- Repair pipes first move to the yard, then use an external workshop and
  transport (no shared crew/forklift during the external lead time).
  They require a staffed return movement. Fixed per-pipe decisions determine
  whether they must pass through inspection again, without washing again.
- An order is released for loading only when **all** its non-scrap pipes are
  ready in the yard. Each pipe needs a driver/forklift to load. After all
  are loaded, that order departs after the configured truck delay.
  Scrap stays in the scrap yard; scrap-only orders do not need a truck.
- Tasks requiring staff must fit entirely inside a weekday shift. Repairs,
  incoming trucks and customer departure delays may span nights/weekends.
  Priority is lane shutdown, hall clearance, repair returns, hall admission,
  later inspection steps, washing, yard feed, unloading, then loading.
  This is a fixed policy, not an optimal workforce scheduler.
- Random inputs (including scrap discovery and re-inspection) are drawn
  before scheduling, so changing only staffing/equipment preserves the input
  workload. Promotions keep headcount fixed. Default machine limits, movements,
  certificates and transport times are **experimental assumptions**, not
  calibrated site measurements. Wash lanes are independently staffed lanes,
  not complete duplicates of the old washing unit.

The seven experiments are baseline, more workers, one certified L1 promoted
to L3, an extra forklift, extra wash lanes, doubled inspection-machine counts,
and doubled hall floor capacity. Compare first-pass completion, inspection
queue waits and occupancy as well as total departure time: long external
repairs can dominate the latter and hide a hall bottleneck.

Reports include stage times, step work/queue time and final pipe conservation.
`flow_results/latest.mat` contains per-pipe inputs, order membership, individual
worker/pipe IDs in the event log, and queue histories. CSV summaries and plots
are also produced. Matching output filenames are overwritten on the next run;
the generated directory is ignored by git. Times are minutes internally and
elapsed calendar days in reports/plots. An unfinished run warns explicitly
and reports `Complete = false`, rather than treating a time limit as success.
Its event log also marks scheduled jobs beyond the horizon as `completed = false`;
the stage report counts completed jobs only.

### Isolating washing and inspection

```matlab
[results, summary] = scenario_process(15);   % small parallelism demonstration
[results, summary] = scenario_process(100);  % eight crew mixes, two wash capacities
test_process
```

This uses the same event engine but sets `C.process_only = true`. Every pipe
starts waiting for washing, and stops as OK, ready for repair, or scrap after
inspection. There are no arrivals, unloading, forklifts, movement delays,
actual repairs, re-inspections, order-release constraints or departures.
Hall and wash-floor space still limit work in progress. Finished inspection
pipes leave the floor immediately; this intentionally removes the movement
bottleneck to examine processing alone.

Inspection equipment limits are set to the number of pipes, allowing every
qualified available worker to perform the same step on different pipes at
once. Each pipe still follows `P.steps` in order, never has two simultaneous
inspectors, and can change workers at any step. Higher levels can do
lower-level inspection work. For this experiment all levels are also allowed
to wash, overriding the old L0/L1-only wash pool; otherwise an all-L3 crew
could not start washing.

Crews are 3/6/15 L3-only workers, 3/6/12 mixed workers, the default seven,
and seven with one L1 promoted to L3. Each is tested with the default washing
lane count and twice that count. These are independently staffed lanes, not
an unstaffed extra machine: setup, length changeovers and shutdown still take
time and people. Extra lanes cannot guarantee faster inspection when those
people are needed elsewhere. The existing later-step-first, lowest-qualified-
worker-first dispatch policy is retained; it is not an optimal scheduler.
All experiments use identical pre-generated pipes and outcomes.

`summary` reports last washing and inspection completion in elapsed calendar
hours, completion including lane shutdown, peak simultaneous inspectors and
the three outcome counts. `flow_results/process.mat` preserves all event logs
and `flow_results/process_summary.csv` stores the comparison; both are
overwritten on rerun. The bar chart compares inspection completion, not long
repair lead times. `P.pace` still scales the seconds in `P.steps`.

The automated 15-pipe demonstration gives every pipe the same wash duration,
15 wash lanes and 15 L3 workers, with no scrap. It verifies all 15 can work on
each inspection step simultaneously and checks the exact total duration.
The normal scenario retains the project's random lengths and outcomes, so
washing releases pipes at different times and not all inspectors need peak
at 15.

`scenario_process` also plots pipes versus elapsed calendar days: cumulative
completed inspections (all three outcomes) and pipes occupying the inspection
hall, with a separate column for each washing capacity. To plot a saved run
without simulating again:

```matlab
load(fullfile('flow_results', 'process.mat'), 'results')
plot_process(results)
```

### Inspect and clear groups of 30

```matlab
[results, summary] = scenario_process(100, true, 15);
[results, summary] = scenario_process(800, true, 15);
test_process_batches
```

The second argument enables batch clearance; the third is the **minutes to
move one entire group**, not minutes per pipe. The default assumption is 15
minutes, adjustable through `C.batch_move_minutes` in `flow_config.m` or this
argument. `C.batch_clearance` is otherwise false, preserving the original
continuous process-only experiments and the full-lifecycle runner.

Each group has `P.hall_space` pipes (30 by default). Washed pipes enter the
hall as they become available, but inspection starts only after the whole
group has entered. All pipes finish their required inspection steps before
clearance starts. One available worker of any level from the shared crew
moves the entire group; no forklift/certificate restriction applies in this
experiment. That worker is unavailable for washing during the move. Every
pipe retains its hall position until the movement finishes; no pipe from
the next group can enter early. Washing can continue into its separate buffer
while the hall is inspecting or clearing. The final smaller group is handled
normally: 800 pipes makes 26 groups of 30 and one group of 20.

This is deliberately a strict fill/inspect/clear policy, not a rolling
replacement of individually completed pipes. The report distinguishes
`InspectionDoneHours` from `YardReadyHours` and counts `GroupsMoved`.
The bar chart compares yard readiness; the time-series chart adds cumulative
pipes cleared to the yard alongside completed inspections and hall occupancy.
OK, ready-for-repair and scrap counts become terminal only after removal.
Actual repairs and customer shipping remain outside this experiment.

Batch comparisons save to `flow_results/process_batches.mat` and
`flow_results/process_batches_summary.csv`, leaving continuous-run results
untouched. Plot saved batch results without rerunning:

```matlab
load(fullfile('flow_results', 'process_batches.mat'), 'results')
plot_process(results)
```

The processing comparison continues until all pipes finish (subject to
`C.max_days`), rather than stopping at `P.days = 7`. It still uses `P.seed`
and the weekday `P.shift` from `params.m`. Summary columns `ElapsedDays` and
`FinishDayTime` include nights/weekends; day 1 is Monday. `WorkingShifts`
is elapsed available shift time divided by the daily shift length, while
`ShiftsStarted` counts working days entered. Neither measures worker labour
or utilization. Time-series graphs use elapsed calendar days; the bar chart
and original hour columns retain hours.
