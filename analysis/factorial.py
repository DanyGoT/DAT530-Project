"""Main effects and interactions of the 2^4 expansion factorial (fx_CFHL runs
of run_experiments.sh): C crew 12 -> 17, F forklifts 2 -> 3, H halls 1 -> 2,
L lorry helpers 2 -> 1. An effect is the mean of the output with the factor
(or the product of the factors' signs) at +1, less the mean at -1, per seed;
the seeds share arrivals, so the spread over seeds is the noise. Prints a
table and writes results/experiments/factorial_<output>.csv.

    cd DAT530-Project
    uv run --with pandas --with scipy python -I analysis/factorial.py [output]
"""
import glob
import itertools
import os
import sys

import numpy as np
import pandas as pd
from scipy import stats

EXP = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "results", "experiments")
FACTORS = "CFHL"
out = sys.argv[1] if len(sys.argv) > 1 else "inspected"

rows = [pd.read_csv(f).iloc[0] for f in sorted(glob.glob(os.path.join(EXP, "fx_*_s*.csv")))]
df = pd.DataFrame(rows)
for i, f in enumerate(FACTORS):
    df[f] = df["tag"].str[3 + i].astype(int) * 2 - 1            # -1 / +1
factors = [f for f in FACTORS if df[f].nunique() == 2]          # a factor left out stays at -1
y = df.pivot_table(index="seed", columns="tag", values=out)
runs = df.drop_duplicates("tag").set_index("tag")[factors]
y = y[[t for t in runs.index if t in y.columns]].dropna()        # seeds with every run
n = 2 ** len(factors)
assert y.shape[1] == n, f"{y.shape[1]} of {n} runs complete"

print(f"{out}: factors {''.join(factors)}, grand mean {y.values.mean():.1f}, {len(y)} seeds\n")
table = []
for k in range(1, len(factors) + 1):
    for combo in itertools.combinations(factors, k):
        sign = runs.loc[y.columns, list(combo)].prod(axis=1).values
        e = (y.values * sign).sum(axis=1) / (n / 2)              # per seed: mean(+) - mean(-)
        h = stats.t.ppf(0.975, len(e) - 1) * e.std(ddof=1) / np.sqrt(len(e)) if len(e) > 1 else np.nan
        table.append({"effect": "".join(combo), "mean": e.mean(), "ci95": h,
                      "significant": abs(e.mean()) > h})
T = pd.DataFrame(table)
print(T.to_string(index=False, float_format=lambda v: f"{v:8.1f}"))
T.to_csv(os.path.join(EXP, f"factorial_{out}.csv"), index=False)
