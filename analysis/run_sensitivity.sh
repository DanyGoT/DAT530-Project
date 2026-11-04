#!/usr/bin/env bash
# Runs for the sensitivity analysis: the baseline and one parameter changed
# at a time, each for every seed, JOBS at a time, one MATLAB each
# (run_jobs.sh). A week takes ~45-70 min. Runs whose result file exists are
# skipped, so it can be stopped and started again. Results:
# results/sensitivity/; then run sensitivity.m in MATLAB. Run from the course
# folder's dev shell:
#   nix develop -c DAT530-Project/analysis/run_sensitivity.sh
set -euo pipefail
cd "$(dirname "$0")"

SEEDS=${SEEDS:-"1 2 3"}

# tag  field (- for none)  value (a MATLAB expression); about +20%, crew +1 person
RUNS=(
  "base        -                []"
  "pace        pace             0.62*1.1"
  "hall_space  hall_space       84"
  "hall_buffer hall_buffer      24"
  "wash_min    wash_min         2.2*1.2"
  "receipts    receipts_per_day 6.7*1.2"
  "crew_L0     crew             [6 5 1 1]"
  "crew_L1     crew             [5 6 1 1]"
  "certified   certified        [4 1 0 0]"
  "bundle      bundle           6*1.2"
)

for seed in $SEEDS; do
  for run in "${RUNS[@]}"; do
    read -r tag field value <<< "$run"
    [ "$field" = - ] && field=""
    echo "results/sensitivity/${tag}_s${seed}.mat sens_run('$tag', $seed, '$field', $value)"
  done
done | ./run_jobs.sh
