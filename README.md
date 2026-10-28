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
| `COMMON_PRE.m`, `COMMON_POST.m` | all processor logic, one `switch` on the transition name |
| `modules/` | one PDF per module: arrival, yard, wash, inspection, repair, departure |
| `imc/` | connectors, one per pair of modules; only arcs |
| `lib/` | joint and demand generators, the hall step list, run setup |
| `tests/` | `test_yard`, `test_hall`, `test_model` |

The course flake puts every folder on `MATLABPATH` when you enter `nix develop`.

## How it works

- **Token = one joint.** In the yard a joint's kind is the place it is in
  (`pYLong`, `pYShort`, `pYReady`). In the wash and the hall it carries colours:
  its length, what inspection will find (`ok`, `mach`, `hb`, `scrap`), its order,
  and `scrapped` once inspection has found the scrap. The colours are taken off when
  it leaves the hall: GPenSIM copies every coloured token after each firing, so
  colourless joints elsewhere keep runs fast.
- **Washing** keeps the machine's state in places: mobilized or not, set up for
  long or short joints. Changing over takes 23 min, so washing in arrival order
  keeps orders together.
- **The hall** is an open floor joints roll through in order, with room for
  `P.hall_space` joints. The 25 tasks of the 2021 report are grouped into 8
  steps (`P.steps`). Whoever in the team is free and has the level does the next step
  on a joint; each step has one transition per qualified person, so several
  joints can be at the same step at once. Workers L0-L3 are GPenSIM resources,
  and a higher level can do lower-level work (`requestAR`).
- **Scrap** is found at one of the steps that can find it, each equally likely.
  Found scrap skips the steps it doesn't need.
- **Repair** releases each joint when its machining or hardbanding time is up,
  then sends it back to the hall.
- Yard and halls work Mon-Fri 07-15; arrivals, tickets and workshops don't stop.
- Runs are repeatable: `P.seed` fixes the random numbers.

## Running

```matlab
project_pn                      % one week; prints a summary, worker use and plots
```

Change `params.m`, or set fields after `P = params();` in `project_pn.m`
(e.g. `P.crew = [3 2 0 2];` for the 2021 report's crew).
