"""The report's figures, from saved results only. One command remakes all:

    cd DAT530-Project
    uv run --with matplotlib --with scipy --with pandas python -I analysis/figures.py

Reads results/experiments/*.mat (exp_run.m), results/reference/*.csv
(reference_data.py, export_inputs.m). Writes vector PDFs to
../report/images/. A figure whose runs aren't there yet is skipped.
"""
import glob
import os

import matplotlib
matplotlib.use("pdf")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy import stats
from scipy.io import loadmat

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXP = os.path.join(ROOT, "results", "experiments")
REF = os.path.join(ROOT, "results", "reference")
OUT = os.path.join(ROOT, "..", "report", "images")

# One style for every figure: 16 cm wide, small type, recessive axes. Colours
# are the first slots of a validated categorical palette; every series also
# has its own marker or line style, so the figures read in black and white.
BLUE, ORANGE, AQUA = "#2a78d6", "#eb6834", "#1baf7a"
INK, MUTED, GRID = "#0b0b0b", "#52514e", "#d9d8d4"
REFC = "#8a8984"                       # data references
W = 16 / 2.54
plt.rcParams.update({
    "font.size": 8, "axes.titlesize": 8.5, "axes.labelsize": 8, "legend.fontsize": 7.5,
    "xtick.labelsize": 7.5, "ytick.labelsize": 7.5, "axes.edgecolor": MUTED,
    "axes.labelcolor": INK, "xtick.color": MUTED, "ytick.color": MUTED, "text.color": INK,
    "axes.spines.top": False, "axes.spines.right": False, "axes.grid": True,
    "grid.color": GRID, "grid.linewidth": 0.5, "axes.axisbelow": True,
    "lines.linewidth": 1.5, "legend.frameon": False, "pdf.fonttype": 42,
    "axes.titlelocation": "left", "axes.titleweight": "bold",
})
LEVELS = ["L0", "L1", "L2", "L3"]


def load(tag):
    """Every run of an experiment, by seed."""
    runs = {}
    for f in sorted(glob.glob(os.path.join(EXP, f"{tag}_s*.mat"))):
        m = loadmat(f, squeeze_me=True, struct_as_record=False)
        runs[int(m["seed"])] = m
    return runs


def base_runs():
    """The baseline runs: the week runs if there, else the short ones (base2)."""
    for tag in ("base", "base2"):
        runs = load(tag)
        if runs:
            return tag, runs
    return None, {}


def ci95(x):
    """Mean and half-width of the 95% t-interval."""
    x = np.asarray(x, float)
    if len(x) < 2:
        return x.mean(), np.nan
    return x.mean(), stats.t.ppf(0.975, len(x) - 1) * x.std(ddof=1) / np.sqrt(len(x))


def save(fig, name):
    os.makedirs(OUT, exist_ok=True)
    fig.savefig(os.path.join(OUT, name), bbox_inches="tight")
    plt.close(fig)
    print("wrote", name)


def shade_shifts(ax, days, shift=(7, 15)):
    """Grey bands for the working hours, Mon-Fri."""
    for d in range(days):
        if d % 7 < 5:
            ax.axvspan(d + shift[0] / 24, d + shift[1] / 24, color="#efeeea", lw=0, zorder=0)


# ---------------------------------------------------------------------------
def f1_inputs():
    """F1: the model's arrivals against the data."""
    mr, ms = os.path.join(REF, "model_receipts.csv"), os.path.join(REF, "model_receipt_sizes.csv")
    if not (os.path.exists(mr) and os.path.exists(ms)):
        return print("skip F1: run export_inputs.m")
    model = pd.read_csv(mr)
    data = pd.read_csv(os.path.join(REF, "receipts_per_weekday.csv"))
    data = data[data.weekday < 5]
    sizes_m = pd.read_csv(ms).joints.values
    sizes_d = pd.read_csv(os.path.join(REF, "joints_per_receipt.csv")).joints.values

    fig, (a, b) = plt.subplots(1, 2, figsize=(W, 2.4))
    bins = np.arange(0, 31) - 0.5
    a.hist(data.receipts, bins, density=True, histtype="stepfilled", color=REFC, alpha=0.45,
           label=f"Data 2025–26 ({len(data)} weekdays)")
    a.hist(model.receipts, bins, density=True, histtype="step", color=BLUE, lw=1.5,
           label=f"Model ({len(model)} weekdays, 5 seeds)")
    a.set(xlabel="Receipts per weekday", ylabel="Share of weekdays", title="a  Receipts per weekday")
    a.set_ylim(0, a.get_ylim()[1] * 1.35)       # room for the legend above the bars
    a.legend(loc="upper right")
    for x, c, ls, label in [(sizes_d, REFC, "-", f"Data ({len(sizes_d):,} receipts)"),
                          (sizes_m, BLUE, "--", f"Model ({len(sizes_m):,} receipts)")]:
        x = np.sort(x)
        b.step(x, np.arange(1, len(x) + 1) / len(x), where="post", color=c, ls=ls, lw=1.5, label=label)
    b.set_xscale("log")
    b.set(xlabel="Joints per receipt (log scale)", ylabel="Share of receipts ≤ x", title="b  Joints per receipt")
    b.legend(loc="lower right")
    fig.tight_layout()
    save(fig, "f1_inputs.pdf")


def f2_throughput():
    """F2: simulated weekly throughput against the hall's 95 weeks."""
    base, b28 = load("base"), load("base28")
    if not base:
        return print("skip F2: no base runs")
    data = pd.read_csv(os.path.join(REF, "hall_weekly.csv")).joints.values
    sim = [r["Y"].inspected for r in base.values()]
    sim28 = []
    for r in b28.values():                       # each full week of a long run
        out = r["R"].out
        t = np.atleast_2d(out)[:, 0] / 1440
        sim28 += list(np.histogram(t, bins=np.arange(0, r["P"].days + 1, 7))[0])

    fig, ax = plt.subplots(figsize=(W, 1.9))
    rng = np.random.default_rng(0)
    rows = [("Data, hall 2025–26\n(95 weeks)", data, REFC, "o"),
            (f"Model, one week\n({len(sim)} seeds)", np.array(sim), BLUE, "D")]
    if sim28:
        rows.append((f"Model, weeks of\n28-day runs ({len(sim28)})", np.array(sim28), ORANGE, "s"))
    for i, (lab, x, c, mk) in enumerate(rows[::-1]):
        y = i + rng.uniform(-0.18, 0.18, len(x))
        ax.scatter(x, y, s=14 if len(x) > 20 else 26, color=c, marker=mk, alpha=0.75, lw=0)
        ax.plot([np.median(x)] * 2, [i - 0.32, i + 0.32], color=INK, lw=1.5)
        ax.text(np.median(x), i + 0.36, f"median {np.median(x):.0f}", ha="center", va="bottom", fontsize=7, color=MUTED)
    ax.set_yticks(range(len(rows)), [r[0] for r in rows[::-1]])
    ax.set_ylim(-0.6, len(rows) - 0.2)
    ax.set_xlabel("Joints inspected per week")
    ax.grid(axis="y", visible=False)
    save(fig, "f2_throughput.pdf")


def f3_week(seed=1):
    """F3: one week of the baseline, hour by hour."""
    tag, runs = base_runs()
    if seed not in runs:
        return print("skip F3: no baseline run for seed", seed)
    r = runs[seed]
    R, P = r["R"], r["P"]
    d = R.hour / 24
    fig, axs = plt.subplots(3, 1, figsize=(W, 4.6), sharex=True, gridspec_kw={"hspace": 0.35})
    for ax in axs:
        shade_shifts(ax, int(P.days), tuple(np.atleast_1d(P.shift) / 60))
    a, b, c = axs
    a.plot(d, R.yard_long + R.yard_short, color=BLUE, label="Hall joints in the yard")
    a.set(ylabel="Joints", title="a  Queue in the yard")
    b.plot(d, R.floor, color=BLUE, label=f"On the hall floor (room for {P.hall_space})")
    b.plot(d, R.to_wash, color=ORANGE, ls="--", label="At the wash")
    b.plot(d, R.washed, color=AQUA, ls=":", lw=1.8, label="Washed, waiting for room")
    b.set(ylabel="Joints", title="b  Hall floor and the wash")
    b.set_ylim(0, P.hall_space * 1.45)          # room for the legend above the lines
    b.legend(loc="upper left", ncol=3)
    out = np.atleast_2d(R.out)
    per_day = np.histogram(out[:, 0] / 1440, bins=np.arange(0, P.days + 1))[0]
    c.bar(np.arange(P.days) + 0.5, per_day, width=0.6, color=BLUE)
    for i, n in enumerate(per_day):
        if n:
            c.text(i + 0.5, n, f"{n}", ha="center", va="bottom", fontsize=7, color=MUTED)
    c.set(ylabel="Joints", title="c  Joints inspected per day")
    c.set_ylim(0, per_day.max() * 1.2)
    c.set_xticks(np.arange(P.days) + 0.5, ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][: int(P.days)])
    c.set_xlim(0, P.days)
    c.grid(axis="x", visible=False)
    save(fig, "f3_week.pdf")


def f4_crew(seed=1, day=1):
    """F4: busy share per level over seeds, and the crew over one shift."""
    tag, runs = base_runs()
    if not runs:
        return print("skip F4: no baseline runs")
    fig, (a, b) = plt.subplots(1, 2, figsize=(W, 2.6), gridspec_kw={"width_ratios": [1, 2.3], "wspace": 0.35})
    for i, L in enumerate(LEVELS):
        x = np.array([getattr(r["Y"], f"busy_{L}") for r in runs.values()]) * 100
        m, h = ci95(x)
        a.scatter(np.full(len(x), i) + np.linspace(-0.12, 0.12, len(x)), x, s=12, color=REFC, lw=0, zorder=2)
        a.errorbar(i + 0.3, m, yerr=h, fmt="D", color=BLUE, ms=4, capsize=2, lw=1.2, zorder=3)
    a.set_xticks(range(4), LEVELS)
    a.set(ylabel="Busy share of shift time (%)", title=f"a  Crew busy (n = {len(runs)} seeds)")
    a.set_ylim(min(70, a.get_ylim()[0]), 105)

    r = runs.get(seed, next(iter(runs.values())))
    R, P = r["R"], r["P"]
    log = np.atleast_2d(R.crew_log)          # [resource, transition, start, end, instance]
    names = list(R.transitions)
    t0, t1 = day * 1440 + P.shift[0], day * 1440 + P.shift[1]
    rows = [(L, k) for L in range(4) for k in range(1, int(P.crew[L]) + 1)]
    for y, (L, k) in enumerate(rows):
        sel = (log[:, 0] == L + 1) & (log[:, 4] == k) & (log[:, 3] > t0) & (log[:, 2] < t1)
        for _, tr, s, e, _ in log[sel]:
            wash = names[int(tr) - 1].startswith("tW")
            s, e = max(s, t0), min(e, t1)
            b.barh(y, (e - s) / 60, left=(s - t0) / 60 + P.shift[0] / 60, height=0.6,
                   color=ORANGE if wash else BLUE, hatch="////" if wash else None,
                   edgecolor="white" if wash else "none", lw=0)   # no edges: steps of ~1 min
    b.set_yticks(range(len(rows)), [f"{LEVELS[L]}-{k}" for L, k in rows])
    b.invert_yaxis()
    b.set(xlabel="Hour of day", title=f"b  Who works when, {['Mon','Tue','Wed','Thu','Fri'][day]} (seed {seed})")
    b.set_xlim(P.shift[0] / 60, P.shift[1] / 60 + 0.5)
    b.grid(axis="y", visible=False)
    from matplotlib.patches import Patch
    b.legend(handles=[Patch(color=BLUE, label="Hall step"),
                      Patch(facecolor=ORANGE, hatch="////", edgecolor="white", label="Manning the wash")],
             loc="upper center", bbox_to_anchor=(0.5, -0.2), ncol=2)
    save(fig, "f4_crew.pdf")


def table_baseline():
    """The baseline's main outputs: mean, sd and 95% CI over seeds."""
    tag, runs = base_runs()
    if not runs:
        return
    keys = ["inspected", "per_hour", "busy", "busy_L0", "busy_L1", "busy_L2", "busy_L3",
            "changes", "yard_queue", "unmet", "unmet_end", "waiting", "free_floor", "shipped", "minutes"]
    rows = []
    for k in keys:
        x = np.array([getattr(r["Y"], k) for r in runs.values()], float)
        m, h = ci95(x)
        rows.append((k, m, x.std(ddof=1) if len(x) > 1 else np.nan, m - h, m + h, len(x)))
    t = pd.DataFrame(rows, columns=["output", "mean", "sd", "ci_low", "ci_high", "n"])
    t.to_csv(os.path.join(EXP, f"{tag}_summary.csv"), index=False)
    print(tag)
    print(t.round(3).to_string(index=False))


if __name__ == "__main__":
    for f in [f1_inputs, f2_throughput, f3_week, f4_crew, table_baseline]:
        f()
