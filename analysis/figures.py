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
            "busy_cert", "fork_busy", "yard_hours", "gate", "yard_queue", "unmet", "unmet_end", "waiting",
            "free_floor", "shipped", "minutes"]
    rows = []
    for k in keys:
        x = np.array([getattr(r["Y"], k, np.nan) for r in runs.values()], float)
        m, h = ci95(x)
        rows.append((k, m, x.std(ddof=1) if len(x) > 1 else np.nan, m - h, m + h, len(x)))
    t = pd.DataFrame(rows, columns=["output", "mean", "sd", "ci_low", "ci_high", "n"])
    t.to_csv(os.path.join(EXP, f"{tag}_summary.csv"), index=False)
    print(tag)
    print(t.round(3).to_string(index=False))


MOD = os.path.join(ROOT, "results", "modules")


def ys(tag, key, folder=EXP):
    """One output of every run of an experiment, by seed (from the .csv rows)."""
    out = {}
    for f in sorted(glob.glob(os.path.join(folder, f"{tag}_s*.csv"))):
        r = pd.read_csv(f).iloc[0]
        out[int(r["seed"])] = float(r[key])
    return pd.Series(out, dtype=float)


def paired(tag, ref, key="inspected"):
    """Per seed, the change from ref with the same seed (%): mean and 95% CI."""
    a, b = ys(tag, key), ys(ref, key)
    seeds = a.index.intersection(b.index)
    return ci95(100 * (a[seeds] / b[seeds] - 1)) if len(seeds) else (np.nan, np.nan)


def f5_modules():
    """F5: each module on its own (mod_run.m), against its closed-form bound."""
    if not glob.glob(os.path.join(MOD, "*.csv")):
        return print("skip F5: no module runs")
    fig, (a, b, c) = plt.subplots(1, 3, figsize=(W, 2.6), gridspec_kw={"wspace": 0.55})
    # a: the yard unloads what arrives until its forklifts can't keep up
    top = 0
    for f, col, mk, ls in [(1, ORANGE, "s", "--"), (2, BLUE, "D", "-"), (3, AQUA, "o", ":")]:
        pts = [(ys(f"yard_r{r}_f{f}", "arrived", MOD).mean(), ys(f"yard_r{r}_f{f}", "unloaded", MOD).mean())
               for r in ["1", "1.5", "2", "3"]]
        x, y = np.array(pts).T
        a.plot(x, y, color=col, marker=mk, ls=ls, ms=4, label=f"{f} forklift{'s' if f > 1 else ''}")
        top = max(top, np.nanmax(x))
    a.plot([0, top], [0, top], color=REFC, lw=0.8, ls="-", zorder=0)
    a.text(top, top, "all unloaded", ha="right", va="bottom", fontsize=7, color=MUTED)
    a.set(xlabel="Arriving per shift hour", ylabel="Unloaded per shift hour", title="a  Yard (joints)")
    a.legend(loc="lower right")
    # b: a wash lane washes at its (rounded) time per joint, lanes add up
    lanes = [1, 2, 3, 4]
    m = [ys(f"wash_l{l}", "washed", MOD).mean() for l in lanes]
    bound = ys("wash_l1", "bound", MOD).mean()
    b.plot(lanes, [bound * l for l in lanes], color=REFC, lw=0.8, label="Closed form")
    b.plot(lanes, m, color=BLUE, marker="D", ls="none", ms=5, label="Simulated")
    auto = ys("wash_auto", "washed", MOD).mean()
    b.plot([2], [auto], color=ORANGE, marker="s", ls="none", ms=5, label="2 lanes, automatic")
    b.set(xlabel="Wash lanes", ylabel="Washed per shift hour", title="b  Wash (joints)", xticks=lanes)
    b.legend(loc="upper left")
    # c: the hall reaches most of its crew bound; the top levels set it
    for top_, col, mk, ls in [("11", BLUE, "D", "-"), ("21", ORANGE, "s", "--"), ("22", AQUA, "o", ":")]:
        n = [3, 4, 5, 6, 7]
        tags = [f"hall_{k}{k}{top_}" for k in n]
        x = [2 * k + int(top_[0]) + int(top_[1]) for k in n]
        c.plot(x, [ys(t, "inspected", MOD).mean() for t in tags], color=col, marker=mk, ms=4, ls=ls,
               label=f"L2, L3: {top_[0]}, {top_[1]}")
        c.plot(x, [ys(t, "bound", MOD).mean() for t in tags], color=col, lw=0.8, alpha=0.6, ls=ls)
    c.set(xlabel="People (L0 = L1, + L2, L3)", ylabel="Inspected per week",
          title="c  Hall (thin: crew bound)")
    c.legend(loc="upper left")
    save(fig, "f5_modules.pdf")


def f6_factorial():
    """F6: effects of the 2^4 expansion factorial on joints inspected a week."""
    f = os.path.join(EXP, "factorial_inspected.csv")
    if not os.path.exists(f):
        return print("skip F6: run factorial.py")
    T = pd.read_csv(f, keep_default_na=False)
    T = T.reindex(T["mean"].abs().sort_values().index)
    names = {"C": "Crew 12 → 17", "F": "Forklifts 2 → 3", "H": "Halls 1 → 2", "L": "Lorry helpers 2 → 1"}
    labels = [names.get(e, " × ".join(e)) for e in T.effect]
    fig, ax = plt.subplots(figsize=(W, 3.2))
    main = T.effect.str.len() == 1
    y = np.arange(len(T))
    ax.barh(y, T["mean"], height=0.55, color=np.where(main, BLUE, REFC))
    ax.errorbar(T["mean"], y, xerr=T["ci95"], fmt="none", ecolor=INK, lw=0.9, capsize=2)
    ax.axvline(0, color=MUTED, lw=0.8)
    ax.set_yticks(y, labels)
    ax.set_xlabel("Effect on joints inspected per week (95% CI over seeds)")
    ax.grid(axis="y", visible=False)
    from matplotlib.patches import Patch
    ax.legend(handles=[Patch(color=BLUE, label="Main effect"), Patch(color=REFC, label="Interaction")],
              loc="lower right")
    save(fig, "f6_factorial.pdf")


def f7_scenarios():
    """F7: the scenarios against the baseline with the same seeds (paired), and stock."""
    rows = [("crew2021", "2021 crew [6 4 0 2]"), ("fewer", "One L1 fewer"), ("promote", "One L0 → L1"),
            ("auto_both", "Clean, Finish automated"), ("auto_wash", "… and the wash"),
            ("overtime", "Shift 07–17"), ("floor50", "Floor 50"), ("floor90", "Floor 90"),
            ("buffer10", "Credits 10"), ("buffer30", "Credits 30")]
    rows = [(t, l) for t, l in rows if len(ys(t, "inspected"))]
    if not rows or not len(ys("base3", "inspected")):
        return print("skip F7: no scenario runs")
    stock = [("stock0", 0), ("stock100", 100), ("base3", 300), ("stock1000", 1000)]
    st = [(s, ys(t, "unmet")) for t, s in stock if len(ys(t, "unmet"))]
    if len(st) > 1:
        fig, (a, b) = plt.subplots(1, 2, figsize=(W, 2.9), gridspec_kw={"width_ratios": [2.2, 1], "wspace": 0.5})
    else:                                             # no stock runs: the scenarios only
        fig, a = plt.subplots(figsize=(W * 0.62, 0.35 * len(rows) + 0.8))
    for i, (t, lab) in enumerate(rows[::-1]):
        m, h = paired(t, "base3")
        a.errorbar(m, i, xerr=h, fmt="D", color=BLUE, ms=4, capsize=2, lw=1.2)
        a.text(m, i + 0.25, f"{m:+.0f}%", ha="center", va="bottom", fontsize=6.5, color=MUTED)
    a.axvline(0, color=MUTED, lw=0.8)
    a.set_yticks(range(len(rows)), [l for _, l in rows[::-1]])
    a.set(xlabel="Joints inspected, change from baseline (%)",
          title=("a  " if len(st) > 1 else "") + "Scenarios (paired seeds, 95% CI)")
    a.set_ylim(-0.5, len(rows) - 0.1)
    a.grid(axis="y", visible=False)
    if len(st) < 2:
        return save(fig, "f7_scenarios.pdf")
    for i, (s, x) in enumerate(st):
        m, h = ci95(x.values)
        b.errorbar(i, m, yerr=h, fmt="D", color=BLUE, ms=4, capsize=2, lw=1.2)
    b.set_xticks(range(len(st)), [str(s) for s, _ in st])
    b.set(xlabel="Rig-ready stock at the start", ylabel="Joints asked for, not loaded (mean)",
          title="b  Stock and unmet demand")
    b.grid(axis="x", visible=False)
    save(fig, "f7_scenarios.pdf")


def f8_growth():
    """F8: more receipts and tickets, the yard as it is against the expansion."""
    if not len(ys("grow150", "inspected")):
        return print("skip F8: no growth runs")
    g = [1, 1.25, 1.5, 2]
    sets = [("Today: 1 hall, 12 people", ["base", "grow125", "grow150", "grow200"], BLUE, "D", "-"),
            ("2 halls, 20 people", ["x20", None, "x20_grow150", "x20_grow200"], ORANGE, "s", "--")]
    fig, (a, b) = plt.subplots(1, 2, figsize=(W, 2.5), gridspec_kw={"wspace": 0.35})
    for lab, tags, col, mk, ls in sets:
        for ax, key in [(a, "inspected"), (b, "yard_queue")]:
            pts = [(x, ys(t, key)[ys(t, key).index <= 3]) for x, t in zip(g, tags) if t]
            pts = [(x, s) for x, s in pts if len(s)]
            ax.errorbar([x for x, _ in pts], [s.mean() for _, s in pts], yerr=[ci95(s.values)[1] for _, s in pts],
                        color=col, marker=mk, ms=4, ls=ls, capsize=2, label=lab)
    a.set(xlabel="Receipts and tickets (× today)", ylabel="Joints inspected per week", title="a  Throughput")
    b.set(xlabel="Receipts and tickets (× today)", ylabel="Hall joints in the yard at the end",
          title="b  Queue after a week")
    for ax in (a, b):
        ax.set_xticks(g, [f"×{x:g}" for x in g])
    a.legend(loc="upper left")
    save(fig, "f8_growth.pdf")


if __name__ == "__main__":
    for f in [f1_inputs, f2_throughput, f3_week, f4_crew, table_baseline,
              f5_modules, f6_factorial, f7_scenarios, f8_growth]:
        f()
