#!/usr/bin/env bash
# Runs for the module experiments (mod_run.m): each module on its own, with
# the test stubs in place of the others, JOBS at a time (run_jobs.sh). Runs
# whose result file exists are skipped. Results: results/modules/. Run from
# the course folder:
#   nix develop -c DAT530-Project/analysis/run_modules.sh
set -euo pipefail
cd "$(dirname "$0")"

{
# Yard: what it unloads, against arrivals (x the receipts of params.m) and
# forklifts. 3 days; the hall takes no more than its credits.
for s in 1 2 3; do for r in 1 1.5 2 3; do for f in 1 2 3; do
  echo "results/modules/yard_r${r}_f${f}_s$s.mat mod_run('yard_r${r}_f${f}', $s, 3, 'yard', 'receipts_per_day', 6.7*$r, 'forklifts', $f)"
done; done; done
# Wash: joints a lane washes an hour, against the closed form. Monday, fed
# from a backlog that outlasts the day, credits that never run out.
for s in 1 2 3; do
  for l in 1 2 3 4; do
    echo "results/modules/wash_l${l}_s$s.mat mod_run('wash_l$l', $s, 1, 'wash', 'wash_lanes', $l, 'backlog', 1500, 'hall_buffer', 2000)"
  done
  echo "results/modules/wash_auto_s$s.mat mod_run('wash_auto', $s, 1, 'wash', 'auto', {'Wash'}, 'backlog', 1500, 'hall_buffer', 2000)"
done
# Hall: the crew's capacity against the crew bound (crew_bound.m). L0 = L1 =
# n with 1 or 2 at L2 and L3. 3 days on a backlog that outlasts them.
for s in 1 2 3; do for n in 3 4 5 6 7; do for top in "1 1" "2 1" "2 2"; do
  c="$n $n $top"; t="hall_${c// /}"
  echo "results/modules/${t}_s$s.mat mod_run('$t', $s, 3, 'hall', 'crew', [$c], 'backlog', 1500)"
done; done; done
# Repair: what comes back a day from the workshops' joints at the start.
for s in 1 2 3; do
  echo "results/modules/repair_s$s.mat mod_run('repair', $s, 14, 'repair')"
done
} | ./run_jobs.sh
