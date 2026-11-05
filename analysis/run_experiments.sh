#!/usr/bin/env bash
# Runs for the report's experiments (exp_run.m), JOBS at a time, one MATLAB
# each (run_jobs.sh). One run alone (2026-11-05): ~4 min for 3 days (~8 with
# two halls), ~10 for a week; six at once take ~1.5x as long each. Runs whose result file
# exists are skipped, so it can be stopped and started again. Results:
# results/experiments/<tag>_s<seed>.mat and .csv. Pick runs by tag:
#   nix develop -c DAT530-Project/analysis/run_experiments.sh base base28
# With no tags, the overnight batch (DEFAULT). Run from the course folder.
set -euo pipefail
cd "$(dirname "$0")"

# tag | days | seeds | changes (name/value pairs for exp_run, MATLAB)
# Runs are listed longest first, so the long ones don't finish last.
RUNS=(
  # Baseline. Full weeks: the throughput check against the hall's weeks (F2),
  # and four weeks for drift in the yard's queue.
  "base28     | 28 | 1         |"
  "base       | 7  | 1 2 3 4 5 |"

  # Crew mix and hall, 3 days (Mon-Wed), paired seeds. Crews are the hall
  # crews of the 2021 report plus the yard's people, [3 2 0 0] (P.crew).
  "base3      | 3 | 1 2 3 4 5 |"                             # the reference for these
  "crew2021   | 3 | 1 2 3 4 5 | 'crew', [6 4 0 2]"           # 2021: [3 2 0 2]
  "fewer      | 3 | 1 2 3 4 5 | 'crew', [5 4 1 1]"           # one L1 fewer
  "promote    | 3 | 1 2 3 4 5 | 'crew', [4 6 1 1]"           # one L0 trained to L1
  "auto_both  | 3 | 1 2 3 4 5 | 'auto', {'Clean', 'Finish'}"
  "auto_wash  | 3 | 1 2 3 4 5 | 'auto', {'Clean', 'Finish', 'Wash'}"
  "overtime   | 3 | 1 2 3 4 5 | 'shift', [7 17]*60"
  "floor50    | 3 | 1 2 3 4 5 | 'hall_space', 50"
  "floor90    | 3 | 1 2 3 4 5 | 'hall_space', 90"
  "buffer10   | 3 | 1 2 3 4 5 | 'hall_buffer', 10"
  "buffer30   | 3 | 1 2 3 4 5 | 'hall_buffer', 30"

  # Expansion and logistics: a 2^4 factorial, fx_CFHL, each factor 0 (as
  # params.m) or 1: C crew 12 -> 17 [7 7 2 1] (one L2 and one L3 can't check
  # and scan for two halls, crew_bound), F forklifts 2 -> 3, H halls 1 -> 2,
  # L lorry helpers 2 -> 1. 3 days; a backlog of 1500 keeps the halls fed, so
  # throughput is capacity. Main effects and interactions: factorial.py.
  "fx_0000 | 3 | 1 2 3 | 'backlog', 1500"
  "fx_1000 | 3 | 1 2 3 | 'backlog', 1500, 'crew', [7 7 2 1]"
  "fx_0100 | 3 | 1 2 3 | 'backlog', 1500, 'forklifts', 3"
  "fx_1100 | 3 | 1 2 3 | 'backlog', 1500, 'crew', [7 7 2 1], 'forklifts', 3"
  "fx_0010 | 3 | 1 2 3 | 'backlog', 1500, 'halls', 2"
  "fx_1010 | 3 | 1 2 3 | 'backlog', 1500, 'crew', [7 7 2 1], 'halls', 2"
  "fx_0110 | 3 | 1 2 3 | 'backlog', 1500, 'forklifts', 3, 'halls', 2"
  "fx_1110 | 3 | 1 2 3 | 'backlog', 1500, 'crew', [7 7 2 1], 'forklifts', 3, 'halls', 2"
  "fx_0001 | 3 | 1 2 3 | 'backlog', 1500, 'lorry_helpers', 1"
  "fx_1001 | 3 | 1 2 3 | 'backlog', 1500, 'crew', [7 7 2 1], 'lorry_helpers', 1"
  "fx_0101 | 3 | 1 2 3 | 'backlog', 1500, 'forklifts', 3, 'lorry_helpers', 1"
  "fx_1101 | 3 | 1 2 3 | 'backlog', 1500, 'crew', [7 7 2 1], 'forklifts', 3, 'lorry_helpers', 1"
  "fx_0011 | 3 | 1 2 3 | 'backlog', 1500, 'halls', 2, 'lorry_helpers', 1"
  "fx_1011 | 3 | 1 2 3 | 'backlog', 1500, 'crew', [7 7 2 1], 'halls', 2, 'lorry_helpers', 1"
  "fx_0111 | 3 | 1 2 3 | 'backlog', 1500, 'forklifts', 3, 'halls', 2, 'lorry_helpers', 1"
  "fx_1111 | 3 | 1 2 3 | 'backlog', 1500, 'crew', [7 7 2 1], 'forklifts', 3, 'halls', 2, 'lorry_helpers', 1"
  "cert2   | 3 | 1 2 3 | 'backlog', 1500, 'certified', [1 1 0 0]"   # 2 drivers instead of 3

  # Growth: receipts and tickets x1.25, x1.5, x2, a week each, for the yard as
  # it is and for the expansion (two halls, 20 people). Does the queue run away?
  "grow125    | 7 | 1 2 3 | 'receipts_per_day', 6.7*1.25, 'tickets_per_day', 4.1*1.25"
  "grow150    | 7 | 1 2 3 | 'receipts_per_day', 6.7*1.5, 'tickets_per_day', 4.1*1.5"
  "grow200    | 7 | 1 2 3 | 'receipts_per_day', 6.7*2, 'tickets_per_day', 4.1*2"
  "x20        | 7 | 1 2 3 | 'halls', 2, 'crew', [8 8 2 2], 'certified', [3 1 0 0]"
  "x20_grow150| 7 | 1 2 3 | 'halls', 2, 'crew', [8 8 2 2], 'certified', [3 1 0 0], 'receipts_per_day', 6.7*1.5, 'tickets_per_day', 4.1*1.5"
  "x20_grow200| 7 | 1 2 3 | 'halls', 2, 'crew', [8 8 2 2], 'certified', [3 1 0 0], 'receipts_per_day', 6.7*2, 'tickets_per_day', 4.1*2"

  # Departure: rig-ready stock at the start (300 in params.m) against unmet demand.
  "stock0     | 3 | 1 2 3 4 5 | 'stock', 0"
  "stock100   | 3 | 1 2 3 4 5 | 'stock', 100"
  "stock1000  | 3 | 1 2 3 4 5 | 'stock', 1000"

  # Not in the batch (pick by tag).
  "base_again | 7  | 1         |"      # reproducibility: the same as base, seed 1
)
DEFAULT="base28 base base3 crew2021 fewer promote auto_both auto_wash overtime floor50 floor90 buffer10 buffer30
fx_0000 fx_1000 fx_0100 fx_1100 fx_0010 fx_1010 fx_0110 fx_1110 fx_0001 fx_1001 fx_0101 fx_1101 fx_0011 fx_1011 fx_0111 fx_1111 cert2
grow125 grow150 grow200 x20 x20_grow150 x20_grow200 stock0 stock100 stock1000"
DEFAULT=${DEFAULT//$'\n'/ }

trim() { local x; read -r x <<< "$1"; printf '%s' "$x"; }   # no word splitting or globbing
want=" ${*:-$DEFAULT} "
for run in "${RUNS[@]}"; do
  IFS='|' read -r tag days seeds changes <<< "$run"
  tag=$(trim "$tag"); days=$(trim "$days"); changes=$(trim "$changes")
  [[ "$want" == *" $tag "* ]] || continue
  for seed in $seeds; do
    echo "results/experiments/${tag}_s${seed}.mat exp_run('$tag', $seed, $days${changes:+, $changes})"
  done
done | ./run_jobs.sh
