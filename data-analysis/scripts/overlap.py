import sys; sys.path.insert(0, sys.argv[2]); from load import *
o=u16("Orders.csv"); n=lambda c: pd.to_numeric(o[c].str.strip(),errors="coerce")
q,m,h,s=n("QTY_Recived"),n("calc_Qty_Machining"),n("calc_Qty_HB"),n("calc_Qty_Scrap")
d=pd.to_datetime(o.Inspection_Completed_DATE.str.strip(),errors="coerce"); k=(d>="2025-01-01")&(o.Scope_Of_Work2.str.strip()=="Rig Return")&(q>0)
print("RR orders", k.sum(), "sum(m+h+s)>q:", ((m+h+s)>q)[k].sum(), "m+h>q:", ((m+h)>q)[k].sum(), "m+s>q:", ((m+s)>q)[k].sum())
print("joint share OK (q - max(m+h+s... )) lower bound %.1f%%" % (100*(q-(m+h+s)).clip(lower=0)[k].sum()/q[k].sum()))
print("joint share untouched upper (q-max(m,h,s)) %.1f%%" % (100*(q-pd.concat([m,h,s],axis=1).max(1))[k].sum()/q[k].sum()))
