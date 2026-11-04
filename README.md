# DAT530-Project

A GPenSIM model of the Ocean IMR pipe yard, at the level of single joints:
joints arrive, wait in one of two yards, are washed, inspected on the hall
floor, and go to stock, a workshop or scrap. Stock is shipped on delivery
tickets. One pool of workers does the hall, the wash and the forklift work in
the yards.

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
| Arrival | — | `tALong`, `tAShort`, `tABypass` (to Main), `tACHall`, `tACBypass` (to Coop) |
| Yard (Main and Coop) | `tYInLong`, `tYInShort`, `tYInBypass`, `tYInCHall`, `tYInCBypass`, `tYInOk`, `tYInOkCoop`, `tYInScrap`, `tYInRepaired`, `tYRoom` (a credit), `tYOrder`, `tYOrderCoop` (a joint asked for) | `tYLong`, `tYShort` (to the wash), `tYShip`, `tYShipCoop` (a joint) |
| Washing | `tWIn` (from `pYW` onto its rack) | `tWOut` (washed, to `pWI`) |
| Inspection | `tIIn` (washed), `tIInRepair` | `tIOk`, `tIScrap`, `tIMach`, `tIHb`, `tIRoom` (the credit back) |
| Repair | `tRInMach`, `tRInHb` | `tRMachHall`, `tRHbHall`, `tRMachReady`, `tRHbReady` |
| Departure | `tDShip` | `tDTicket` |

A connector's places are named by the two modules' letters: `pAYLong`
(Arrival → Yard; `pAYCHall` for Coop), `pYW`, `pWI`, `pIYOk`, `pIYScrap`, `pIYRoom`, `pIRMach`,
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
- **Token = one joint.** In the yards a joint's kind is the place it is in
  (`pYLong`, `pYShort`, `pYReady`, `pCHall`, `pCReady`). In the wash and the hall it carries colours:
  its length, what inspection will find (`ok`, `mach`, `hb`, `scrap`), its order,
  and `scrapped` once inspection has found the scrap. Joints for the workshops
  keep only their order. GPenSIM copies every coloured token after each firing,
  so colourless joints elsewhere keep runs fast.
- **One pool of workers.** Workers L0-L3 are GPenSIM resources (`P.crew`,
  now 12 people); `P.certified` of them hold a forklift certificate (resources
  `L0T`-`L3T`, the others `L0`-`L3`). Hall work takes those without a
  certificate first, so the drivers stay free. A higher level can do lower-level work (`requestAR`, lowest level
  asked first), but not while a joint waits at a step of their own level: the
  one L3 stays free for UT, the one L2 for threads and reports. The same
  people inspect and man the wash, and joints per man-hour counts them all.
- **Two yards and their forklifts.** Main lies by the hall; Coop is ~8 min
  away. A receipt is unloaded at Coop with `P.coop_in` (per order), and a
  hall order's rig-ready joints are stored there with `P.coop_ready`. Every
  move of a joint in a yard is forklift work: a forklift at that yard
  (`P.forklifts`, tokens in `pYFork`/`pCFork`) and a certified driver, plus
  `P.lorry_helpers` people whenever a lorry is loaded or unloaded (2021
  report: three people at a lorry). Times are per bundle (`P.t_unload`, ...,
  `P.bundle` joints). Forklift work goes before hall work: when it finds no
  driver free, the hall and the wash leave the certified workers alone for
  the next step, and when a lorry lacks helpers, L0 and L1 too, so the lorry
  crew gathers as people come free. At Main, feeding the wash goes before unloading and
  storing; other forklift jobs take turns. Helpers at a lorry are L0/L1
  without a certificate first. (No GPenSIM priorities: setting any makes GPenSIM try every
  transition in a fixed order, and the hall's dispatch would change.)
  - Hall bundles at Coop are fetched to Main by lorry when they are within
    `P.fetch_ahead` joints (per hall) of the front of the hall queue; the
    hall waits if one isn't there in time.
  - Ok joints for Coop go from the hall straight onto a lorry, not into a
    rack at Main first.
  - A joint asked for comes from Coop with Coop's share of the stock.
  - Lorries between the yards are rented: never waited for, only the drive
    (`P.lorry_drive`). A forklift drives over (`P.fork_drive`, with its
    driver) when `P.coop_batch` joints of work wait at Coop, or the first
    has waited `P.coop_wait` min, and comes back when Coop has none. At most
    one forklift is at Coop.
  - Most times are guesses (marked "gut" in `params.m`): our data has
    nothing on the yards. Repair transport (to and from the workshops) is
    only counted on the way back (`tYInRepaired`).
- **Washing** is one unit with two lanes (two pumps). It takes joints from the
  yard onto its rack (`pWRack`) and washes them in the order they came, one
  per lane at a time, each with a free L0 or L1 worker (`P.wash_crew`)
  for `P.wash_min` = 2.2 min. That is the manned time per joint of the
  detailed wash it replaced (mobilizing, long/short changeovers, waiting;
  tag `pre-simplify`). The wash is not a bottleneck, so its details are left
  out; the yard sends hall joints in plain list order.
- **The hall buffer.** The yard sends a joint to the wash only with a credit
  (`pYRoom`), and the hall hands the credit back (`pIRoom` → `pIYRoom` →
  `pYRoom`) when the joint comes onto the floor. So at most `P.hall_buffer` joints are between the yard and the floor:
  at the wash, or washed and waiting for room.
- **The hall** is an open floor joints roll through in order, with room for
  `P.hall_space` joints. The 25 tasks of the 2021 report are grouped by level
  into 5 steps (`P.steps`): Clean (L0), Inspect (L1), Check (L2), UT (L3),
  Finish (L0). Task times are the report's times x `P.pace`, calibrated
  before the yards were added (~800 inspected a week by 7 people). Whoever in the
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
- **A second hall** (`P.halls = 2`, made up for expansion experiments) stands
  at Main: the same hall with its own wash, floor and credits, starting
  empty. Both share the crew, the yard queue and the forklifts. Each hall
  takes whole orders: once it has all of its order out of the yard, it takes
  the next order no hall has, and if both are free, the one with the most
  room (free floor and credits) gets it (`lib/next_joint.m`). Joints back
  from repair go to whichever hall has room first. Hall 2's places and
  transitions are hall 1's with `H2_` after the first letter (`pH2_ISpace`,
  `tH2_Wash_1`; `hall_name`, `hall_of`); `inspection2_pdf` and `wash2_pdf`
  build them, and both halls run the same hooks. With `P.halls = 1` the net
  and the results are exactly the model without it.
- Yard and halls work Mon-Fri 07-15; arrivals, tickets and workshops don't stop.
- Runs are repeatable: `P.seed` fixes the random numbers.
- **Time step.** GPenSIM steps a fixed clock, `P.delta` = 0.5 min, and ends a
  firing at the first step at or after its end; firing times are rounded to
  the nearest step (`model_dyn`) so they aren't all rounded up. Hand-offs
  between modules take one step. `P.delta = 0.25` runs half as fast and
  inspects 1.5-5% more.

## Running

```matlab
project_pn                      % one week; prints a summary, worker use and plots
test_yard; test_wash; test_repair; test_hall; test_model; test_halls
analysis_pn                     % invariants and crew bound, in seconds
```

Change `params.m`, or set fields after `P = params();` in `project_pn.m`
(e.g. `P.crew = [3 2 0 2];` for the 2021 report's crew).
