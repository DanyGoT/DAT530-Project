import sys, csv, io, pandas as pd
D = sys.argv[1]
def u16(name, ncols=None):
    raw = open(f"{D}/{name}", "rb").read().decode("utf-16")
    lines = raw.replace("\r\n","\r").split("\r")
    hdr = [h.strip() for h in lines[0].split(",")]
    rows, buf = [], ""
    for l in lines[1:]:
        l = l.replace("\n"," ")
        buf = buf + l if buf else l
        parts = buf.split(",")
        if len(parts) < len(hdr): continue
        if len(parts) > len(hdr): parts = parts[:len(hdr)-1] + [",".join(parts[len(hdr)-1:])]
        rows.append(parts); buf = ""
    return pd.DataFrame(rows, columns=hdr)
def q(name):
    return pd.read_csv(f"{D}/{name}", lineterminator="\r", dtype=str, keep_default_na=False)
