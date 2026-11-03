"""Mask the 2026-11-03 delivery-ticket export into masked/.

    uv run python -I mask_dt_items.py <raw folder> <masked folder> <masking_key.csv>

- DT_Items.csv -> masked/DT_Items.csv, serials replaced by their J code.
  Serials the key doesn't know (they are in no other file) get new codes,
  appended to the key so they stay the same next time.
  The export stops at 2 MB, in DT 12006 (2023-08); the cut-off last row is dropped.
  Records split by a line break inside the serial are joined back together
  with \v, the cell line break the other exports and the key have there.
- DTs 1.csv -> its Repair_YN column is added to masked/DTs.csv, joined on
  DT_No (DT numbers aren't masked). DTs not in the new export get a blank.
Output is UTF-16 with a header row and rows ending in \r, like the other files.
"""
import sys, csv

raw, masked, keyfile = sys.argv[1:4]


def rows(path):
    t = open(path, "rb").read().decode("utf-16").rstrip("\n")
    return [l for l in t.split("\r")]


def write(path, lines):
    open(path, "wb").write(("\r".join(lines) + "\n").encode("utf-16"))


key = list(csv.reader(open(keyfile, newline="")))
serial = {r[1]: r[2] for r in key[1:] if r[0] == "serial"}
nxt = max(int(c[1:]) for c in serial.values()) + 1

# DT_Items
lines = rows(f"{raw}/DT_Items.csv")
out, new, buf = [lines[0]], [], ""
for l in lines[1:]:
    buf = buf + "\v" + l if buf else l    # a line break inside the serial splits a record in two
    p = buf.split(",")
    if len(p) < 5:
        continue
    buf = ""
    sn = p[2].strip()
    if sn:
        if sn not in serial:
            serial[sn] = f"J{nxt:06d}"; new.append(sn); nxt += 1
        p[2] = serial[sn]
    out.append(",".join(p))
if buf:
    print("dropped the cut-off last row:", repr(buf))
write(f"{masked}/DT_Items.csv", out)
print(f"DT_Items: {len(out)-1} rows, {len(new)} new serial codes")
if new:
    with open(keyfile, "a", newline="") as f:
        csv.writer(f, lineterminator="\r\n").writerows(["serial", s, serial[s]] for s in new)

# Repair_YN onto masked/DTs.csv
rep = {}
for l in rows(f"{raw}/DTs 1.csv")[1:]:
    p = l.split(",")
    rep[p[0].strip()] = p[-1].strip()
lines = rows(f"{masked}/DTs.csv")
if lines[0].rstrip().endswith("Repair_YN"):
    sys.exit("DTs: masked/DTs.csv already has Repair_YN, left as it is")
out =[lines[0] + ", Repair_YN"] + [l + "," + rep.get(l.split(",")[0].strip(), "") for l in lines[1:]]
write(f"{masked}/DTs.csv", out)
print(f"DTs: {len(out)-1} rows, Repair_YN found for {sum(l.split(',')[0].strip() in rep for l in lines[1:])}")
