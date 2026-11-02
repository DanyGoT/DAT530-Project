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
def qs(x):
    x=pd.Series(x).dropna(); return pd.Series({"n":len(x),"p25":x.quantile(.25),"p50":x.quantile(.5),"p75":x.quantile(.75),"p90":x.quantile(.9)}).round(1)
st["prevloc"]=st.groupby("Serial Number")["loc"].shift(1)
s = w[(w["loc"]=="Shipped")].copy()
s["prevloc"]=st.loc[s.index,"prevloc"]
for src in ["Inspection","Rig_Ready","Norse","Wepco","Hardbanding"]:
    x = s[s.prevloc==src]
    print(f"\n{src} -> Shipped -> next (n={len(x)}, open/no next {x.next.isna().mean()*100:.0f}%)")
    print(pd.concat([x.next.value_counts(normalize=True).mul(100).round(1).rename("%"), x.groupby("next").dwell.median().round(1).rename("median gap d")],axis=1).head(8).to_string())
