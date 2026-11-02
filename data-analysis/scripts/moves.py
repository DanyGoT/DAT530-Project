import sys, numpy as np; sys.path.insert(0, sys.argv[2]); from load import *
pd.set_option("display.width", 250); pd.set_option("display.max_columns", 40)
W0, W1 = pd.Timestamp("2025-01-01"), pd.Timestamp("2026-10-23")
def ts(s):
    s=s.str.strip(); out=pd.Series(pd.NaT,index=s.index)
    for f in ["%d.%m.%Y %H:%M:%S","%d.%m.%Y %H:%M","%d/%m/%Y %H:%M:%S","%d/%m/%Y %H:%M"]:
        m=out.isna(); out[m]=pd.to_datetime(s[m],format=f,errors="coerce")
    return out
sh = q("serial_history.csv"); sh["t"]=ts(sh.CreationTimestamp)
def norm(s):
    s=s.str.strip().replace({"Rig Ready":"Rig_Ready","Rig_ready":"Rig_Ready","Rig_Ready|":"Rig_Ready","Hardbanding1":"Hardbanding","Shipped Scrap":"Shipped","ScrapOCTG":"Scrap"})
    return s.where(~s.str.match(r"^[RC]\d+$"),"EXT")
sh["cur"]=norm(sh["Current Location"]); sh["prev"]=norm(sh["Prev Location"]); sh["tt"]=sh["Transaction type"].str.strip().replace({"Receive":"Receiving"})
sh=sh.dropna(subset=["t"]).reset_index(drop=True); sh["i"]=sh.index
sh=sh.sort_values(["Serial Number","t","i"])
# location after each event = cur if non-blank; shipping -> Shipped
loc = sh.cur.where(sh.cur!="", np.nan)
loc = loc.where(~((sh.tt=="Shipping")&loc.isna()), "Shipped")
loc = loc.where(~((sh.tt=="Receiving")&loc.isna()), np.nan)
sh["loc"]=loc
ev = sh.dropna(subset=["loc"])[["Serial Number","t","loc","tt"]]
# collapse consecutive same location per joint
ev["chg"]=(ev["loc"]!=ev.groupby("Serial Number")["loc"].shift())
st = ev[ev.chg].copy()
st["next"]=st.groupby("Serial Number")["loc"].shift(-1); st["t_end"]=st.groupby("Serial Number")["t"].shift(-1)
st["dwell"]=(st.t_end-st.t).dt.total_seconds()/86400
w = st[(st.t>=W0)&(st.t<W1)]
print("joints with events in window", w["Serial Number"].nunique(), "stays", len(w))
main=["EXT","Inspection","Booked","Norse","Wepco","Stamas","Hardbanding","Rig_Ready","Scrap","Limited_Service","On_Hold","Other","ITM","IPC","Shipped"]
m = w.dropna(subset=["next"])
ct = pd.crosstab(m["loc"], m["next"]).reindex(index=[x for x in main if x in m["loc"].values], columns=[x for x in main if x in m["next"].values]).fillna(0).astype(int)
print("COUNTS from->to"); print(ct.to_string())
print("ROW %"); print((ct.div(ct.sum(1),axis=0)*100).round(1).to_string())
def qs(x):
    x=pd.Series(x).dropna(); return pd.Series({"n":len(x),"p25":x.quantile(.25),"p50":x.quantile(.5),"p75":x.quantile(.75),"p90":x.quantile(.9),"mean":x.mean()}).round(1)
print("DWELL days by location (stays starting in window, ended)"); print(m.groupby("loc").dwell.apply(qs).unstack().reindex([x for x in main if x in m["loc"].values]).to_string())
print("DWELL Rig_Ready by next"); print(m[m["loc"]=="Rig_Ready"].groupby("next").dwell.apply(qs).unstack().to_string())
print("DWELL Inspection by next"); print(m[m["loc"]=="Inspection"].groupby("next").dwell.apply(qs).unstack().to_string())
print("DWELL Norse by next"); print(m[m["loc"]=="Norse"].groupby("next").dwell.apply(qs).unstack().to_string())
# open stays at end
op = st[st.next.isna() & (st["loc"]!="Shipped")]; print("open stays (joints currently at) by loc:", op["loc"].value_counts().head(12).to_dict())
# per-joint visit paths: received in window
first = st[st["loc"]=="Inspection"].groupby("Serial Number").t.min()
js = first[(first>=W0)&(first<W1)].index
p = st[st["Serial Number"].isin(js)]
visits = p.groupby("Serial Number")["loc"].apply(lambda s: s.tolist())
def frac(f): return round(visits.apply(f).mean()*100,1)
print("joints first seen at Inspection in window:", len(visits))
for name,f in [("ever Norse",lambda v:"Norse" in v),("ever Wepco",lambda v:"Wepco" in v),("ever Hardbanding",lambda v:"Hardbanding" in v),("ever Stamas",lambda v:"Stamas" in v),("ever Scrap",lambda v:"Scrap" in v),("ever Rig_Ready",lambda v:"Rig_Ready" in v),("shipped",lambda v:"Shipped" in v),
   ("any repair shop",lambda v:any(x in v for x in ["Norse","Wepco","Stamas","Hardbanding"])),("Inspection visited >1",lambda v:v.count("Inspection")>1),
   ("repair then back to Inspection",lambda v:any(v[k] in ["Norse","Wepco","Stamas","Hardbanding"] and "Inspection" in v[k+1:] for k in range(len(v))))]:
    print(f"  {name}: {frac(f)}%")
print("most common paths:"); print(visits.apply(lambda v:" > ".join(v)).value_counts().head(15).to_string())
# round trip: first Inspection -> Shipped
sp = p.groupby("Serial Number").apply(lambda d: (d.loc[d["loc"]=="Shipped","t"].min()-d.loc[d["loc"]=="Inspection","t"].min()).total_seconds()/86400)
print("Inspection arrival -> shipped (days)", qs(sp[sp>=0]).to_dict())
