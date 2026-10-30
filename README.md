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
