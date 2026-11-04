#!/usr/bin/env bash
# Runs for the report's experiments (exp_run.m), JOBS at a time, one MATLAB
# each (run_jobs.sh). One run alone: ~3 min for a day, ~10 for two, ~45-70
# for a week; six at once take ~1.7x as long each. Runs whose result file
# exists are skipped, so it can be stopped and started again. Results:
# results/experiments/<tag>_s<seed>.mat and .csv. Pick runs by tag:
#   nix develop -c DAT530-Project/analysis/run_experiments.sh base base28
# With no tags, the overnight batch (DEFAULT). Run from the course folder.
set -euo pipefail
cd "$(dirname "$0")"

# tag | days | seeds | changes (name/value pairs for exp_run, MATLAB)
# Runs are listed longest first, so the long ones don't finish last.
RUNS=(
  # Baseline. Full weeks: the throughput check against the hall's weeks (F2).
  "base       | 7  | 1 2 3 4 5 |"
  "base2      | 2  | 1 2 3 4 5 |"      # short baseline: timing and first figures
  "base3      | 3  | 1 2 3     |"      # the reference for the 3-day runs below

  # The path to 4.0 joints per man-hour (jpmh_screen.m), one step at a time,
  # each step on top of the one before. 3 days (Mon-Wed); jpmh is a rate.
  "train          | 3 | 1 2 3 | 'crew', [1 4 1 1]"
  "train_auto     | 3 | 1 2 3 | 'crew', [1 4 1 1], 'auto', {'Clean', 'Finish'}"
  "six_auto       | 3 | 1 2 3 | 'crew', [0 4 1 1], 'auto', {'Clean', 'Finish'}"
  "six_auto_wash  | 3 | 1 2 3 | 'crew', [0 4 1 1], 'auto', {'Clean', 'Finish', 'Wash'}"

  # Single changes from the baseline, for comparison with the path.
  "auto_both  | 3 | 1 2 3 | 'auto', {'Clean', 'Finish'}"
  "crew8      | 3 | 1 2 3 | 'crew', [2 4 1 1]"
  "overtime   | 3 | 1 2 3 | 'shift', [7 17]*60"
  "noL3       | 3 | 1 2 3 | 'crew', [2 3 1 0]"
  "L2toL3     | 3 | 1 2 3 | 'crew', [2 3 0 2]"
  "floor50    | 3 | 1 2 3 | 'hall_space', 50"
  "floor90    | 3 | 1 2 3 | 'hall_space', 90"

  # Logistics and expansion (P.certified, P.forklifts, P.halls), 3 days. The
  # backlog keeps the halls fed, so throughput is capacity. 17/20 people:
  # one L2 and one L3 can't check and scan for two halls (crew_bound).
  "lbase      | 3 | 1 2 3 |"                                  # the baseline for these
  "cert2      | 3 | 1 2 3 | 'certified', [1 1 0 0]"
  "cert4      | 3 | 1 2 3 | 'certified', [3 1 0 0]"
  "fork3      | 3 | 1 2 3 | 'forklifts', 3"
  "hall2      | 3 | 1 2 3 | 'halls', 2"
  "crew17     | 3 | 1 2 3 | 'crew', [7 7 2 1]"
  "hall2_c17  | 3 | 1 2 3 | 'halls', 2, 'crew', [7 7 2 1]"
  "hall2_c20  | 3 | 1 2 3 | 'halls', 2, 'crew', [8 8 2 2], 'certified', [3 1 0 0]"
  "hall2_c20f3| 3 | 1 2 3 | 'halls', 2, 'crew', [8 8 2 2], 'certified', [3 1 0 0], 'forklifts', 3"

  # Not in the overnight batch (pick by tag).
  "base_again | 7  | 1         |"      # reproducibility: the same as base, seed 1
  "base28     | 28 | 1 2 3     |"
)
DEFAULT="base base3 train train_auto six_auto six_auto_wash auto_both crew8 overtime noL3 L2toL3 floor50 floor90"

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
