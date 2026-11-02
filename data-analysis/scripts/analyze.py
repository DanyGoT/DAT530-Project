import sys, re, numpy as np; sys.path.insert(0, sys.argv[2]); from load import *
pd.set_option("display.width", 250); pd.set_option("display.max_columns", 40); pd.set_option("display.max_rows", 200)
W0, W1 = pd.Timestamp("2025-01-01"), pd.Timestamp("2026-10-23")
days = pd.bdate_range(W0, W1 - pd.Timedelta(days=1)); NWD = len(days)
print("window", W0.date(), W1.date(), "weekdays", NWD)
def ts(s):
    s = s.str.strip()
    out = pd.Series(pd.NaT, index=s.index)
    for f in ["%Y-%m-%d %H:%M:%S","%Y-%m-%d","%d.%m.%Y %H:%M:%S","%d.%m.%Y %H:%M","%d/%m/%Y %H:%M:%S","%d/%m/%Y %H:%M","%d.%m.%Y"]:
        m = out.isna(); out[m] = pd.to_datetime(s[m], format=f, errors="coerce")
    return out
def qs(x, ps=(.25,.5,.75,.9)):
    x = pd.Series(x).dropna(); return pd.Series({"n":len(x), **{f"p{int(p*100)}":round(x.quantile(p),1) for p in ps}, "mean":round(x.mean(),1), "max":round(x.max(),1)})
num = lambda s: pd.to_numeric(s.str.strip(), errors="coerce")
PIPES = ["Drill Pipe","Tubing","Heavy Weight","Landing String","Drill Collar","OCTG","NM Drill Collar","Pup Joint","NM Flex Wate"]
def H(t): print("\n#### "+t)

# ---------- receive
rc = u16("receive.csv"); rc["q"]=num(rc.Quantity); rc["d"]=ts(rc.Returned_Date); rc["c"]=ts(rc.CreationTimestamp)
rc = rc[rc.Equipment.isin(PIPES) & (rc.q>0) & rc.d.notna()]
r = rc[(rc.d>=W0)&(rc.d<W1)].copy()
H("ARRIVALS")
per = r.groupby(r.d.dt.normalize()).agg(n=("q","size"), j=("q","sum")).reindex(days, fill_value=0)
print("receipts/weekday mean %.2f var %.2f P0 %.2f | joints/weekday mean %.1f median %.0f p90 %.0f max %.0f" % (per.n.mean(), per.n.var(), (per.n==0).mean(), per.j.mean(), per.j.median(), per.j.quantile(.9), per.j.max()))
print("weekend share receipts %.1f%%" % (100*(r.d.dt.dayofweek>=5).mean()))
print("weekday share receipts:", (r.d.dt.dayofweek.value_counts(normalize=True).sort_index()*100).round(1).to_dict())
print("weekday share joints:", (r.groupby(r.d.dt.dayofweek).q.sum()/r.q.sum()*100).round(1).to_dict())
wk = r.groupby(r.d.dt.to_period("W")).q.agg(["size","sum"]); print("per week receipts/joints:", qs(wk["size"]).to_dict(), qs(wk["sum"]).to_dict())
t = r.groupby("Equipment").q.agg(receipts="size", joints="sum", median="median", mean="mean", p75=lambda x:x.quantile(.75), p90=lambda x:x.quantile(.9), max="max").sort_values("joints", ascending=False)
t["%rec"]=(t.receipts/t.receipts.sum()*100).round(1); t["%joints"]=(t.joints/t.joints.sum()*100).round(1); print(t.round(1))
print("ALL", qs(r.q, (.5,.75,.9)).to_dict())
bins=[0,1,5,10,30,100,300,10000]; print("batch size bins:", (pd.cut(r.q,bins).value_counts(normalize=True).sort_index()*100).round(1).to_dict())
print("registration lag days", qs((r.c-r.d).dt.total_seconds()/86400).to_dict())

# ---------- orders
o = u16("Orders.csv")
for c in ["QTY_Recived","calc_Qty_HB","calc_Qty_Machining","calc_Qty_Scrap"]: o[c]=num(o[c])
for c in ["Inspection_Completed_DATE","Machinig_Completed_Date","Hardbaning_Completed_Date","Pre_Invoice_Sent_Date"]: o[c]=ts(o[c])
o["Scope"]=o.Scope_Of_Work2.str.strip().replace({"Re_Inspection":"Re Inspection","R2R":"RtoR"})
o = o.merge(rc[["Receive_No","d"]].rename(columns={"d":"recv"}), on="Receive_No", how="left")
o["ref"]=o.recv.fillna(o.Inspection_Completed_DATE)
o = o[o.Equipment.isin(PIPES) & (o.QTY_Recived>0)]
o = o[~((o.calc_Qty_HB>o.QTY_Recived)|(o.calc_Qty_Machining>o.QTY_Recived)|(o.calc_Qty_Scrap>o.QTY_Recived))]
ow = o[(o.ref>=W0)&(o.ref<W1)].copy()

# ---------- hall
ws = u16("Workstation.csv"); ws["setup"]=ts(ws.CreationTimestamp)
ws["xfer"]=ts(ws.Transfer.str.replace("Report Transfered","").str.strip())
wi = q("workstation_items.csv"); wi["t"]=ts(wi.CreationTimestamp); wi=wi[wi["Serial No"].str.strip()!=""]
b = wi.groupby("ForeignKey").agg(joints=("Serial No","size"), first=("t","min"), last=("t","max")).reset_index()
b = b.merge(ws[["PrimaryKey","Order_No","xfer"]], left_on="ForeignKey", right_on="PrimaryKey", how="left")
b = b[b.Order_No!="1"].merge(o[["Order_No","Scope","Equipment","recv","QTY_Recived","Inspection_Completed_DATE"]], on="Order_No", how="left")
bw = b[(b["first"]>=W0)&(b["first"]<W1)].copy()
H("ORDERS BY SCOPE (receive date in window)")
hall_orders = set(b.Order_No)
g = ow.groupby("Scope").agg(orders=("Order_No","size"), joints=("QTY_Recived","sum"), insp_date=("Inspection_Completed_DATE", lambda x: x.notna().mean()*100), hall=("Order_No", lambda x: x.isin(hall_orders).mean()*100))
g["%joints"]=g.joints/g.joints.sum()*100; print(g.sort_values("joints",ascending=False).round(1))
H("RECEIVE -> FIRST HALL SCAN (days), hall batches in window")
bw["wait"]=(bw["first"].dt.normalize()-bw.recv).dt.days
print(bw.groupby("Scope").wait.apply(qs).unstack().sort_values("n",ascending=False).head(8))
print("ALL", qs(bw.wait).to_dict())
H("RECEIVE -> INSPECTION COMPLETED (days)")
ow["ri"]=(ow.Inspection_Completed_DATE-ow.recv).dt.days
print(ow[ow.ri>=0].groupby("Scope").ri.apply(qs).unstack().sort_values("n",ascending=False).head(8))
H("HALL BATCHES")
print("batches", len(bw), "joints", bw.joints.sum())
print("joints/batch", qs(bw.joints,(.25,.5,.75,.9)).to_dict())
print("joints/batch bins:", (pd.cut(bw.joints,bins).value_counts(normalize=True).sort_index()*100).round(1).to_dict())
print("joint-weighted bins:", (bw.groupby(pd.cut(bw.joints,bins),observed=False).joints.sum()/bw.joints.sum()*100).round(1).to_dict())
print(bw.groupby("Scope").joints.apply(qs).unstack().sort_values("n",ascending=False).head(8))
print(bw.groupby("Equipment").joints.apply(qs).unstack().sort_values("n",ascending=False).head(8))
hd = bw.groupby(bw["first"].dt.normalize()).agg(n=("joints","size"), j=("joints","sum")).reindex(days, fill_value=0)
print("hall batches/weekday mean %.2f var %.2f P0 %.2f | joints/weekday mean %.1f median %.0f p90 %.0f max %.0f" % (hd.n.mean(), hd.n.var(), (hd.n==0).mean(), hd.j.mean(), hd.j.median(), hd.j.quantile(.9), hd.j.max()))
hw = bw.groupby(bw["first"].dt.to_period("W")).joints.agg(["size","sum"]); print("per week batches", qs(hw["size"],(.1,.5,.9)).to_dict(), "joints", qs(hw["sum"],(.1,.5,.9)).to_dict())
print("batch first-scan hour share %:", (bw["first"].dt.hour.value_counts(normalize=True).sort_index()*100).round(1).to_dict())
print("weekday share batches:", (bw["first"].dt.dayofweek.value_counts(normalize=True).sort_index()*100).round(1).to_dict())
bw["span_min"]=(bw["last"]-bw["first"]).dt.total_seconds()/60; print("scan span within batch (min)", qs(bw.span_min,(.5,.9,.99)).to_dict())
bw["sign"]=(bw.xfer-bw["last"]).dt.total_seconds()/86400; print("last scan -> report transfer (days)", qs(bw.sign[bw.sign>=0]).to_dict(), "has transfer %.0f%%"%(bw.xfer.notna().mean()*100))
print("transfer hour share %:", (bw.xfer.dt.hour.value_counts(normalize=True).sort_index()*100).round(1).to_dict())
bw["si"]=(bw.Inspection_Completed_DATE-bw["first"].dt.normalize()).dt.days; print("first scan -> inspection completed (days)", qs(bw.si[bw.si>=0]).to_dict())
xf = bw.dropna(subset=["xfer"]).sort_values("xfer"); gap=xf.xfer.diff().dt.total_seconds()/60
print("transfer sessions (gap>30min splits): n", (gap>30).sum()+1, "orders/session", qs(((gap>30).cumsum()).value_counts(),(.5,.9)).to_dict())

H("ROUTING (orders inspected in window, calc qty)")
oi = o[(o.Inspection_Completed_DATE>=W0)&(o.Inspection_Completed_DATE<W1)]
def rout(d):
    J=d.QTY_Recived.sum(); return pd.Series({"orders":len(d),"joints":J,"mach%":d.calc_Qty_Machining.sum()/J*100,"HB%":d.calc_Qty_HB.sum()/J*100,"scrap%":d.calc_Qty_Scrap.sum()/J*100,
      "P(o>mach)":(d.calc_Qty_Machining>0).mean()*100,"P(o>HB)":(d.calc_Qty_HB>0).mean()*100,"P(o>scrap)":(d.calc_Qty_Scrap>0).mean()*100})
print(oi.groupby("Scope").apply(rout).sort_values("joints",ascending=False).round(1).head(10))
rr = oi[oi.Scope=="Rig Return"]; print("RIG RETURN by equipment"); print(rr.groupby("Equipment").apply(rout).sort_values("joints",ascending=False).round(1)); print("ALL", rout(rr).round(1).to_dict())
f = rr[rr.calc_Qty_Machining>0]; print("RR orders with machining: fraction of order machined", qs(f.calc_Qty_Machining/f.QTY_Recived*100,(.25,.5,.75)).to_dict())
f = rr[rr.calc_Qty_Scrap>0]; print("RR orders with scrap: fraction scrapped", qs(f.calc_Qty_Scrap/f.QTY_Recived*100,(.25,.5,.75)).to_dict())
print("Rig Return routing by quarter:"); print(rr.groupby(rr.Inspection_Completed_DATE.dt.to_period("Q")).apply(rout)[["joints","mach%","HB%","scrap%"]].round(1))
oi2 = oi.copy(); oi2["im"]=(oi2.Machinig_Completed_Date-oi2.Inspection_Completed_DATE).dt.days; oi2["ih"]=(oi2.Hardbaning_Completed_Date-oi2.Inspection_Completed_DATE).dt.days
print("insp->mach completed", qs(oi2.im[oi2.im>=0]).to_dict()); print("insp->HB completed", qs(oi2.ih[oi2.ih>=0]).to_dict())
oi2["ip"]=(oi2.Pre_Invoice_Sent_Date-oi2.Inspection_Completed_DATE).dt.days; print("insp->pre-invoice", qs(oi2.ip[oi2.ip>=0]).to_dict())

# ---------- deliveries
dt = u16("DTs.csv"); dt["q"]=num(dt.Quantity); dt["d"]=ts(dt.DT_Date); dt=dt[(dt.q>0)&(dt.d>=W0)&(dt.d<W1)]
H("DELIVERIES")
dd = dt.groupby(dt.d.dt.normalize()).agg(n=("q","size"), j=("q","sum")).reindex(days, fill_value=0)
print("tickets/weekday mean %.2f var %.2f P0 %.2f | joints/weekday mean %.1f p90 %.0f" % (dd.n.mean(), dd.n.var(), (dd.n==0).mean(), dd.j.mean(), dd.j.quantile(.9)))
print("weekend share %.1f%%"%(100*(dt.d.dt.dayofweek>=5).mean()))
print("weekday share tickets:", (dt.d.dt.dayofweek.value_counts(normalize=True).sort_index()*100).round(1).to_dict())
print("joints/ticket", qs(dt.q,(.25,.5,.75,.9)).to_dict())
print("by equipment:"); e=dt.Equipment.str.strip().replace("", "(blank)"); print(dt.groupby(e).q.agg(["size","sum","median"]).sort_values("sum",ascending=False))
print("in vs out joints: received %d delivered %d" % (r.q.sum(), dt.q.sum()))

# ---------- yard snapshot
H("YARD SNAPSHOT")
lo = u16("Location.csv"); lo["a"]=num(lo.Amount); lo["m"]=num(lo.Maxrowcount)
print(lo.groupby(lo.Site_Location.str.strip()).agg(racks=("Rack_ID","size"), joints=("a","sum"), empty=("a", lambda x:(x==0).sum()), maxrow_med=("m","median")).sort_values("joints",ascending=False))
print("total racks", len(lo), "joints", lo.a.sum(), "joints/rack nonempty", qs(lo.a[lo.a>0],(.5,.9)).to_dict())
