# The data the report's figures compare the model with, as tidy CSVs.
# Same filters and window as analyze.py (model_datasheet.md §2, §4, §5).
#   cd data-analysis/scripts
#   uv run --with pandas python -I reference_data.py ../../../data/masked "$PWD" ../../results/reference
import sys, os; sys.path.insert(0, sys.argv[2]); from load import *
OUT = sys.argv[3]; os.makedirs(OUT, exist_ok=True)
W0, W1 = pd.Timestamp("2025-01-01"), pd.Timestamp("2026-10-23")
days = pd.bdate_range(W0, W1 - pd.Timedelta(days=1))
PIPES = ["Drill Pipe","Tubing","Heavy Weight","Landing String","Drill Collar","OCTG","NM Drill Collar","Pup Joint","NM Flex Wate"]
def ts(s):
    s = s.str.strip()
    out = pd.Series(pd.NaT, index=s.index)
    for f in ["%Y-%m-%d %H:%M:%S","%Y-%m-%d","%d.%m.%Y %H:%M:%S","%d.%m.%Y %H:%M","%d/%m/%Y %H:%M:%S","%d/%m/%Y %H:%M","%d.%m.%Y"]:
        m = out.isna(); out[m] = pd.to_datetime(s[m], format=f, errors="coerce")
    return out
num = lambda s: pd.to_numeric(s.str.strip(), errors="coerce")

# Receipts (§2): per weekday, and joints per receipt.
rc = u16("receive.csv"); rc["q"] = num(rc.Quantity); rc["d"] = ts(rc.Returned_Date)
rc = rc[rc.Equipment.isin(PIPES) & (rc.q > 0) & rc.d.notna()]
r = rc[(rc.d >= W0) & (rc.d < W1)]
per = r.groupby(r.d.dt.normalize()).agg(receipts=("q", "size"), joints=("q", "sum")).reindex(days, fill_value=0)
per.index.name = "date"; per["weekday"] = per.index.day_of_week
per.to_csv(f"{OUT}/receipts_per_weekday.csv")
r[["q"]].rename(columns={"q": "joints"}).to_csv(f"{OUT}/joints_per_receipt.csv", index=False)

# Hall batches (§5): joints inspected per week, and receive -> first hall scan (§4).
o = u16("Orders.csv"); o["QTY_Recived"] = num(o.QTY_Recived)
o["Scope"] = o.Scope_Of_Work2.str.strip().replace({"Re_Inspection": "Re Inspection", "R2R": "RtoR"})
o = o.merge(rc[["Receive_No", "d"]].rename(columns={"d": "recv"}), on="Receive_No", how="left")
o = o[o.Equipment.isin(PIPES) & (o.QTY_Recived > 0)]
wi = q("workstation_items.csv"); wi["t"] = ts(wi.CreationTimestamp); wi = wi[wi["Serial No"].str.strip() != ""]
ws = u16("Workstation.csv")
b = wi.groupby("ForeignKey").agg(joints=("Serial No", "size"), first=("t", "min")).reset_index()
b = b.merge(ws[["PrimaryKey", "Order_No"]], left_on="ForeignKey", right_on="PrimaryKey", how="left")
b = b[b.Order_No != "1"].merge(o[["Order_No", "Scope", "recv"]], on="Order_No", how="left")
bw = b[(b["first"] >= W0) & (b["first"] < W1)].copy()
hw = bw.groupby(bw["first"].dt.to_period("W")).joints.sum().rename("joints")
hw.index = hw.index.start_time.date; hw.index.name = "week"
hw.to_csv(f"{OUT}/hall_weekly.csv")
bw["wait_days"] = (bw["first"].dt.normalize() - bw.recv).dt.days
bw[["Scope", "joints", "wait_days"]].dropna().to_csv(f"{OUT}/receive_to_hall.csv", index=False)

print("weeks", len(hw), "median", hw.median(), "| receipts/weekday", round(per.receipts.mean(), 2),
      "| Rig Return wait median", bw[bw.Scope == "Rig Return"].wait_days.median())
