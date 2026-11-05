# Trym's simulation experiments

The folder structure mirrors the class project. The `flow_*` functions are
event-driven MATLAB modules, **not GPenSIM Petri-net PDFs**. No original module
is copied or replaced. `../params.m` and `../lib/new_order.m` remain shared.

```text
trym_test/
  flow_config.m              logistics/equipment assumptions
  scenario_flow.m            finite full lifecycle
  scenario_process.m         washing/inspection and optional batch clearance
  scenario_batch.m           legacy GPenSIM batch scenario
  scenario_crews.m           legacy GPenSIM crew comparison
  trym_test_setup.m          project path setup
  run_tests.m                focused tests
  COMMON_POST.m              legacy GPenSIM batch timing/stop hook
  imc/
    flow_wash_inspection.m   hall admission, capacity and batch gates
    flow_logistics.m         timed transfer with worker/forklift reservation
    flow_complete.m          completion/resource-release dispatch
  lib/
    run_flow.m              main event loop and module scheduling order
    flow_state.m            shared state, resources, event log, clock, results
    flow_inputs.m           fixed population and pre-generated random inputs
    flow_validate.m         configuration validation
    plot_process.m          progress, hall occupancy and yard-clearance graphs
    print_flow.m            full-lifecycle report
    run_batch.m             legacy GPenSIM batch runner
    print_batch.m           legacy GPenSIM report
    fast_forward.m          legacy GPenSIM idle-time skip
  modules/
    arrival/                arrivals and unloading
    departure/              order release, loading and shipping
    inspection/             qualification, sequential steps and scrap discovery
    repair/                 external repair and re-inspection routing
    wash/                   staffed lanes, setup, changeover and shutdown
    yard/                   yard feed, hall clearance and outcome classification
  tests/
    test_flow.m             full lifecycle and resource invariants
    test_process.m          parallel inspection and processing outcomes
    test_process_batches.m  whole-group removal and hall admission gates
  flow_results/             saved MAT/CSV outputs (ignored by git)
```

## Run from MATLAB

```matlab
cd('C:\Users\Trym\DAT_530\DAT530-Project\trym_test')
[results, summary] = scenario_process(800, true, 15);
```

That is the latest 800-pipe experiment: weekday 07:00-15:00 work, groups of
30 inspected fully before one shared worker removes the whole group in 15
minutes. The last group has 20 pipes. Actual repair and shipping are excluded.
Workers may change between steps; qualified workers may inspect different
pipes at the same step concurrently. Inspection equipment is unlimited in
this experiment. Without batch clearance, finished pipes leave immediately:

```matlab
[results, summary] = scenario_process(100);
```

For 400 waiting pipes plus 400 arriving, with logistics, repairs and order
departures included:

```matlab
results = scenario_flow('baseline', 800);
results = scenario_flow('all', 100);
```

Scenario entry points set up paths automatically. For manual parameter
experiments, tests or loading old results, first call:

```matlab
trym_test_setup()
P = params();
C = flow_config(P);
```

Run tests without the long scenario comparisons:

```matlab
run_tests
```

Saved results moved here without rerunning or changing them. To replot:

```matlab
trym_test_setup()
load(fullfile('flow_results', 'process_batches.mat'), 'results')
plot_process(results)
```

`scenario_batch` and `scenario_crews` are the earlier GPenSIM experiments.
They still use the **original** modules and require GPenSIM on MATLAB's path.
They are not entry points for the new `flow_*` modules.

## Where to change behavior

- `../params.m`: shared crew, shift, task durations/competence, repair model.
- `flow_config.m`: movement durations, certificates, forklifts and capacities.
- `scenario_process.m` / `scenario_flow.m`: comparison definitions.
- `modules/`: individual operational rules; `imc/`: transfers between them.
- `lib/run_flow.m`: fixed priority order; `lib/flow_state.m`: common resources.

The split preserves the scheduling policy, exact event logs, random draws
and output shapes of the previous single-file runner. These remain model
experiments with assumed logistics/equipment values, not calibrated predictions.
See [the main README](../README.md) for all modelling rules and report columns.
