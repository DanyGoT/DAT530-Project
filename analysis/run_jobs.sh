#!/usr/bin/env bash
# Runs MATLAB jobs, JOBS at a time, one fresh MATLAB each. Reads one job a
# line from stdin:
#   <result file, relative to the project> <MATLAB statement>
# A job whose result file exists is skipped, so a batch can be stopped and
# started again. The log goes next to the result file (.log). Used by
# run_sensitivity.sh and run_experiments.sh. Keep the MATLABs on the
# machine at 6 or fewer: check pgrep -af MATLAB first and lower JOBS.
set -euo pipefail
cd "$(dirname "$0")/.."

JOBS=${JOBS:-6}

run_one() {
  local out=${1%% *} cmd=${1#* }
  local log="${out%.*}.log"
  mkdir -p "$(dirname "$out")"
  echo "start $out"
  if matlab -batch "$cmd" > "$log" 2>&1; then
    echo "done  $out"
  else
    echo "FAIL  $out (see $log)"
  fi
}
export -f run_one

while read -r out cmd; do
  [ -z "$out" ] && continue
  [ -e "$out" ] || echo "$out $cmd"
done | xargs -d '\n' -P "$JOBS" -I{} bash -c 'run_one "$1"' _ {}
