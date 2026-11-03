"""Delivery tickets at joint level: datasheet §8 and §12.

    uv run --with pandas python -I deliveries.py ../masked "$PWD"

Joint -> ticket pairs come from DT_Items (to DT 12006, 2023-08) and, after
that, from the DT No on serial_history Shipping rows (checked against DT_Items).
"""
import sys, numpy as np; sys.path.insert(0, sys.argv[2]); from load import u16, q, pd
pd.set_option("display.width", 250)

W0, W1 = pd.Timestamp("2025-01-01"), pd.Timestamp("2026-10-23")
YARD = {"Yard", "Rig_Ready", "Rig Ready", "Inspection"}
SHOP = {"Norse", "Wepco", "Stamas", "Hardbanding"}
def H(t): print("\n#### " + t)
def qs(v, ps=(.1, .25, .5, .75, .9)):
    v = pd.Series(v).dropna(); return f"n={len(v)} " + " ".join(f"p{int(p*100)}={v.quantile(p):.0f}" for p in ps)
def ts(x): return pd.to_datetime(x.str.replace("/", ".", regex=False), format="mixed", dayfirst=True, errors="coerce")
def strip(df):
    df.columns = [c.strip() for c in df.columns]
    for c in df.columns: df[c] = df[c].str.strip()
    return df

d = strip(u16("DTs.csv")); d = d[d.DT_No.str.fullmatch(r"\d+")]
d["DT_No"] = d.DT_No.astype(int); d["DT_Date"] = pd.to_datetime(d.DT_Date, errors="coerce")
d["q"] = pd.to_numeric(d.Quantity, errors="coerce")
it = strip(u16("DT_Items.csv")); it = it[(it.Serial_No != "") & it.DT_no.str.fullmatch(r"\d+")]
it["DT_no"] = it.DT_no.astype(int)
s = q("serial_history.csv"); s.columns = ["sn","item","t","prev","cur","pos","rack","tt","order","dt","rig","site","date"]
s["t"] = ts(s.t); s = s.sort_values(["sn", "t"])
s["nxt_tt"] = s.groupby("sn").tt.shift(-1); s["nxt_t"] = s.groupby("sn").t.shift(-1)
wi = q("workstation_items.csv"); wi["t"] = ts(wi.CreationTimestamp); wi = wi[wi["Serial No"] != ""].rename(columns={"Serial No": "sn"})
o = strip(u16("Orders.csv"))

H("Shipping rows: written at return (to 2024) or at dispatch (2025-)")
sh = s[s.tt == "Shipping"].copy(); sh["y"] = sh.t.dt.year; sh["day"] = sh.t.dt.normalize()
sh["back5"] = sh.nxt_tt.isin(["Receiving", "Receive"]) & ((sh.nxt_t - sh.t).dt.days <= 5)
dd = d.dropna(subset=["DT_Date"])[["Item_No", "DT_Date"]].rename(columns={"Item_No": "item"}).sort_values("DT_Date")
z = pd.merge_asof(sh.dropna(subset=["day"]).sort_values("day"), dd, left_on="day", right_on="DT_Date", by="item",
                  direction="nearest", tolerance=pd.Timedelta(days=3))
print(z.groupby("y").agg(rows=("back5", "size"), received_within_5d=("back5", "mean"),
                         ticket_same_item_3d=("DT_Date", lambda v: v.notna().mean()),
                         dt_blank=("dt", lambda v: (v == "").mean())).round(2))
sh["dtn"] = pd.to_numeric(sh.dt, errors="coerce")
pairs_it = set(zip(it.Serial_No, it.DT_no))
c = sh[sh.dtn.between(10023, 12006) & sh.sn.isin(set(it.Serial_No))]
print(f"DT No on a Shipping row is a ticket DT_Items has that joint on: {np.mean([(a, int(b)) in pairs_it for a, b in zip(c.sn, c.dtn)]):.3f} (n={len(c)})")

H("§8 Tickets in the window: customer (Repair_YN = No) vs internal (Yes)")
w = d[(d.DT_Date >= W0) & (d.DT_Date < W1) & (d.q > 0)]
days = pd.bdate_range(W0, W1 - pd.Timedelta(days=1))
for r, g in w.groupby("Repair_YN"):
    n = g[g.DT_Date.dt.weekday < 5].groupby("DT_Date").size().reindex(days, fill_value=0)
    m, v = n.mean(), n.var()
    wd = (g.DT_Date.dt.weekday.value_counts(normalize=True).sort_index() * 100).round(1).tolist()
    print(f"Repair_YN={r!r}: tickets {len(g)}, joints {g.q.sum():.0f}; per weekday mean {m:.2f} var {v:.2f} "
          f"NB r {m*m/(v-m) if v > m else np.inf:.2f}; joints/ticket mean {g.q.mean():.1f} {qs(g.q)}; weekday % Mon-Sun {wd}")

H("Joint -> ticket pairs")
a = it[["Serial_No", "DT_no"]].rename(columns={"Serial_No": "sn", "DT_no": "dt"}).assign(src="DT_Items")
b = sh[sh.dtn > 12006][["sn", "dtn"]].rename(columns={"dtn": "dt"}).assign(src="serial_history")
b["dt"] = b.dt.astype(int)
p = pd.concat([a, b]).drop_duplicates(["sn", "dt"]).merge(d[["DT_No", "DT_Date", "Repair_YN", "q"]], left_on="dt", right_on="DT_No")
p = p.dropna(subset=["DT_Date"])
rec = p.groupby("dt").size()
cov = d.set_index("DT_No").assign(rec=rec).query("q > 0")
cov = cov.assign(y=cov.DT_Date.dt.year).groupby(["y", "Repair_YN"]).apply(lambda g: g.rec.sum() / g.q.sum(), include_groups=False)
print("joints recovered / joints on tickets, by year:\n", cov.unstack().round(2))
# last hall scan before the ticket, next receiving after it, last receiving before it
p["k"] = p.DT_Date + pd.Timedelta(days=1)
p = pd.merge_asof(p.sort_values("k"), wi.dropna(subset=["t"]).sort_values("t")[["sn", "t"]].rename(columns={"t": "scan"}),
                  left_on="k", right_on="scan", by="sn", direction="backward")
rc = s[s.tt.isin(["Receiving", "Receive"])][["sn", "t", "prev"]].dropna(subset=["t"]).sort_values("t")
p = pd.merge_asof(p.sort_values("DT_Date"), rc.rename(columns={"t": "back", "prev": "back_from"}),
                  left_on="DT_Date", right_on="back", by="sn", direction="forward")
p = pd.merge_asof(p.sort_values("k"), rc.rename(columns={"t": "rcv", "prev": "rcv_from"}),
                  left_on="k", right_on="rcv", by="sn", direction="backward")
p["dwell"] = (p.DT_Date - p.scan.dt.normalize()).dt.days
p["src_in"] = np.select([p.rcv_from.isin(YARD), p.rcv_from.isin(SHOP)], ["own yard", "workshop"], "rig/other")

for era, g in [("2020-23, DT_Items", p[p.src == "DT_Items"]), ("2025-26, serial_history", p[(p.DT_Date >= W0) & (p.DT_Date < W1)])]:
    g = g[g.Repair_YN == "No"]
    H(f"§12 Customer tickets, {era}: {len(g)} joints on {g.dt.nunique()} tickets")
    print("inspection -> ticket (d):", qs(g.dwell), f"| no hall scan found {g.dwell.isna().mean():.2f}")
    print("  stock joints only (> 3 d):", qs(g.dwell[g.dwell > 3]))
    print(f"inspected <= 3 d before the ticket: {(g.dwell <= 3).mean():.2f} of joints")
    f = g.groupby("dt").dwell.apply(lambda v: (v <= 3).mean())
    print(f"per ticket: all joints fresh {(f == 1).mean():.2f}, none {(f == 0).mean():.2f}, mixed {((f > 0) & (f < 1)).mean():.2f}")
    print("last receive before the ticket came from:", g.src_in.value_counts(normalize=True).round(2).to_dict())
    print("ticket -> back in the yard (d):", qs((g.back - g.DT_Date).dt.days), f"| came back {g.back.notna().mean():.2f}")
g = p[(p.Repair_YN == "Yes") & (p.DT_Date >= W0) & (p.DT_Date < W1)]
print("\ninternal tickets 2025-26, received back from (top):", g.back_from.value_counts(normalize=True).head(6).round(2).to_dict())

H("§12 Where received joints come from, 2025-26 (Receiving rows)")
r = s[s.tt.isin(["Receiving", "Receive"]) & (s.t >= W0) & (s.t < W1)].copy()
r["src"] = np.select([r.prev.isin(YARD), r.prev.isin(SHOP)], ["own yard", "workshop"], "rig/other")
print(r.src.value_counts(normalize=True).round(3).to_dict(), "n", len(r))
r = r[r.order != ""].merge(o[["Order_No", "Scope_Of_Work2"]], left_on="order", right_on="Order_No")
t = pd.crosstab(r.Scope_Of_Work2, r.src, normalize="index").round(2)
print(t.assign(rows=r.Scope_Of_Work2.value_counts()).sort_values("rows", ascending=False).head(10))
