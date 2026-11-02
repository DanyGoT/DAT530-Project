# Model data sheet — pipe yard

Concrete numbers for building the Petri net. Everything is in one place, and each number names where it came from.

- **Our data**: the masked exports in `masked/` (exported 2026-10-23). Unless stated otherwise, the **window is 2025-01-01 → 2026-10-22**: 472 weekdays, 95 weeks. That is the recent steady state. Volumes and routing have shifted since 2020, so `Old data/reference_stats.md` (all years) gives different numbers in places.
- **2021 report**: `../litterature/pipe_simulators-1.pdf` (Afzali et al., DAT530 2021, same company). It is the **only** source of task-level times inside the hall. It was written in 2021 and has not been checked against our data.
- Weekday shares run Mon → Sun. "pN" means the Nth percentile. Days are calendar days.

---

## 0. Parameter card

| Parameter | Value | Source | Confidence |
|---|---|---|---|
| Receipts (arrival batches) per weekday | mean 6.9, var 27 (NB r≈2.4, p≈0.26); 4% of weekdays have none | §2 | high |
| Joints per receipt | median 9, p75 40, p90 110, max 899 | §2 | high |
| Joints received per week | median 1191, p25 779, p90 1997 | §2 | high |
| Share of received joints that need the hall | ≈ 77% (Mobilization, RFID Pairing, Sandblasting, Misc skip it) | §3 | medium |
| Rig Return wait, receive → hall | median 35 d, p25 14, p75 76, p90 141 | §4 | high |
| RtoR / Re Inspection wait | 0 d (same day) | §4 | high |
| Hall batches (≈ orders) per weekday | mean 4.9, var 22 (NB r≈1.4) | §5 | high |
| Joints per hall batch | median 6, p75 30, p90 90, max 874; 25% are single joints | §5 | high |
| Hall throughput | median 803 joints/week (p10 323, p90 1107); 143 joints/weekday | §5 | high |
| Hall time per joint (abstracted) | 25 min end to end; 182.5 s per joint at the bottleneck (≈ 20 joints/h) | §5.2, report | medium |
| Hall setup + teardown | ≈ 3.6 h summed over all tasks, of which 66 min is UT/EMI calibration | §5.2, report | low |
| Hall batch time, first scan → report signed | median 0.2 d (≈ 5 h), p75 0.6 d, p90 2.1 d | §5 | high |
| Rig Return outcome (per joint) | machining 54%, hardbanding 9%, scrap 5.6%; untouched → Rig_Ready 36–42% | §6 | high |
| Drill pipe Rig Return outcome | machining 59%, hardbanding 12%, scrap 6.6% | §6 | high |
| Workshop next hop | Norse/Wepco → Rig_Ready ≈ 52%, → back to Inspection ≈ 11%, → another workshop 12–15% | §7 | low |
| Workshop turnaround (inspection → machining done) | median 31 d (n=152) / time in Norse median 60 d | §7 | low |
| Delivery tickets per weekday | mean 4.9, var 14 (NB r≈2.6); weighted to Thu–Fri | §8 | high |
| Joints per delivery ticket | median 13, p75 48, p90 98 | §8 | high |
| Yard capacity | 250 racks, 17,291 joints in stock (snapshot); Rig_Ready 219 racks / 11,945 joints | §9 | high |

---

## 1. Flow and locations

```
 Rig ──receive──▶ Yard queue ("Inspection") ──▶ HALL (abstracted) ──▶ outcome
                                                                      ├─▶ Rig_Ready ─────────────▶ ship ──▶ Rig
                                                                      ├─▶ Machining  (Norse, Wepco, Stamas) ─┐
                                                                      ├─▶ Hardbanding (Hardbanding, Wepco)  ─┼─▶ Rig_Ready / back to Inspection / other workshop
                                                                      └─▶ Scrap ──▶ ship (scrap)
 Mobilization / RFID Pairing / Sandblasting: receive ──▶ (no hall) ──▶ Rig_Ready / ship
 RtoR / Re Inspection: receive ──▶ hall the same day ──▶ ship
```

Yard locations used in `serial_history`: Inspection, Rig_Ready, Booked, Scrap, ScrapOCTG, Limited_Service, On_Hold, Yard, Shipped.
Workshops: Norse (main machining/repair shop), Wepco and Stamas (machining and hardbanding), Hardbanding. ITM and IPC are unknown.

**"Inspection" is a status, not the hall.** In `serial_history` a joint stays "Inspection" from receiving until it is moved. That covers the queue, the hall and often storage afterwards: 75% of joints leave "Inspection" through a Shipping event. Use `workstation_items` and `Orders` for the hall itself.

---

## 2. Arrivals (`receive.csv`)

3335 receipts, 122,776 joints in the window. Use `Returned_Date`. Registration (`CreationTimestamp`) lags it by a median of 1.7 d (p90 18 d).

**Per weekday**: mean 6.89 receipts, variance 26.95. That is overdispersed: a negative binomial with r≈2.37, p≈0.256 fits the mean and variance. Joints per weekday: mean 253, median 163, p90 589, max 3793.
**Per week**: receipts median 34 (p25 25, p90 49); joints median 1191 (p25 779, p90 1997, max 4679).

| | Mon | Tue | Wed | Thu | Fri | Sat | Sun |
|---|---:|---:|---:|---:|---:|---:|---:|
| % receipts | 21.0 | 21.6 | 20.4 | 17.8 | 16.7 | 1.2 | 1.3 |
| % joints | 24.0 | 21.3 | 19.8 | 14.9 | 17.3 | 1.6 | 1.1 |

**Batch size (joints per receipt)**:

| 1 | 2–5 | 6–10 | 11–30 | 31–100 | 101–300 | >300 |
|---:|---:|---:|---:|---:|---:|---:|
| 20.6% | 22.5% | 10.2% | 17.9% | 17.5% | 10.2% | 1.1% |

**By equipment**:

| Equipment | receipts | joints | % receipts | % joints | median | mean | p75 | p90 | max |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Drill Pipe | 1262 | 83,711 | 37.8 | 68.2 | 36 | 66.3 | 87 | 173 | 899 |
| Tubing | 301 | 16,885 | 9.0 | 13.8 | 25 | 56.1 | 73 | 160 | 510 |
| Heavy Weight | 776 | 9,963 | 23.3 | 8.1 | 4 | 12.8 | 15 | 31 | 213 |
| Landing String | 133 | 7,759 | 4.0 | 6.3 | 40 | 58.3 | 91 | 152 | 285 |
| Drill Collar | 634 | 4,137 | 19.0 | 3.4 | 4 | 6.5 | 10 | 16 | 37 |
| NM Drill Collar | 169 | 236 | 5.1 | 0.2 | 1 | 1.4 | 2 | 2 | 5 |
| NM Flex Wate | 60 | 85 | 1.8 | 0.1 | 1 | 1.4 | 2 | 3 | 3 |

Two kinds of arrival stand out: **few, large drill-pipe, tubing and landing-string batches** carry most of the joints, and **many small HW, DC and NM batches** make up most of the receipts.

---

## 3. Orders and scopes (`Orders.csv`)

Orders whose receive date falls in the window. "Hall" means the order has at least one joint scanned in `workstation_items`.

| Scope | orders | joints | % joints | has inspection date | went through hall |
|---|---:|---:|---:|---:|---:|
| Rig Return | 1949 | 54,672 | 45.9 | 89% | 81% |
| Mobilization | 375 | 21,839 | 18.4 | 0.5% | 0.5% |
| Inspection | 205 | 16,979 | 14.3 | 94% | 66% |
| Re Inspection | 261 | 6,930 | 5.8 | 95% | 98% |
| VTI | 188 | 6,556 | 5.5 | 97% | 84% |
| RtoR + Reinsp | 91 | 4,261 | 3.6 | 98% | 99% |
| RFID Pairing | 94 | 2,582 | 2.2 | 2% | 4% |
| Misc | 34 | 1,788 | 1.5 | 50% | 6% |
| RtoR | 48 | 1,517 | 1.3 | 63% | 73% |
| Sandblasting | 12 | 773 | 0.6 | 100% | 0% |
| Redope | 13 | 404 | 0.3 | 85% | 69% |
| VTI + RtoR | 14 | 283 | 0.2 | 100% | 64% |

A model that keeps only three classes would cover about 99% of joints:
- **Full** (Rig Return, Inspection, VTI): ≈ 66% of joints. These queue, go through the hall and are then routed.
- **Quick** (Re Inspection, RtoR, RtoR + Reinsp, VTI + RtoR): ≈ 11%. They go through the hall the same day, then ship.
- **Bypass** (Mobilization, RFID Pairing, Sandblasting, Misc): ≈ 23%. No hall.

Of the Inspection-scope orders, 34% have no hall scan. The week study saw this for tubing.

---

## 4. Queue before the hall

**Receive → first hall scan** (days, hall batches whose first scan is in the window):

| Scope | n | p25 | median | p75 | p90 | mean |
|---|---:|---:|---:|---:|---:|---:|
| Rig Return | 1653 | 14 | 35 | 76 | 141 | 58 |
| Re Inspection | 252 | 0 | 0 | 0 | 0 | 2.5 |
| VTI | 156 | 0 | 0 | 1 | 5 | 11 |
| Inspection | 148 | 0 | 11 | 36 | 71 | 35 |
| RtoR + Reinsp | 90 | 0 | 0 | 0 | 7 | 2.9 |
| RtoR | 35 | 0 | 0 | 0 | 1 | 1.2 |

**Receive → inspection completed** (`Orders`) gives nearly the same numbers: Rig Return median 33 d (p25 13, p75 70, p90 135). In other words, **almost all of the receive → inspected time is queueing**, not hall work.

So the queue is effectively **priority-based**: quick scopes jump ahead, and Rig Return waits weeks. A plain FIFO queue will not reproduce this.

Note: the 2026-09-28 week study measured a median of 14 d. That week was faster than the 2025–26 average of 35 d.

---

## 5. Inspection hall

### 5.1 What our data shows

A **hall batch** is one `Workstation` record with its scanned joints, which in practice is one order. Window totals: 2376 batches, 73,157 joints.

**Joints per batch**: median 6, p25 2, p75 30, p90 90, mean 30.8, max 874.

| | 1 | 2–5 | 6–10 | 11–30 | 31–100 | 101–300 | >300 |
|---|---:|---:|---:|---:|---:|---:|---:|
| % of batches | 24.6 | 23.9 | 10.4 | 16.7 | 15.3 | 8.2 | 1.0 |
| % of joints | 0.8 | 2.3 | 2.7 | 9.9 | 27.5 | 43.0 | 13.8 |

Most batches are tiny, but most joints come in batches of more than 30.

| Joints per batch by equipment | n | median | p75 | p90 | max |
|---|---:|---:|---:|---:|---:|
| Drill Pipe | 912 | 35 | 81 | 160 | 874 |
| Heavy Weight | 639 | 3 | 12 | 24 | 180 |
| Drill Collar | 498 | 3 | 9 | 14 | 37 |
| NM Drill Collar | 171 | 1 | 2 | 2 | 5 |
| Landing String | 92 | 31 | 74 | 132 | 238 |
| NM Flex Wate | 60 | 1 | 2 | 3 | 3 |

**Rate**:
- Batches per weekday: mean 4.85, var 21.7, none on 9% of weekdays.
- Joints per weekday: mean 143, median 128, p90 302, max 852.
- Per week: batches median 21 (p10 13, p90 39); joints median 803 (p10 323, p90 1107, max 2211).

| | Mon | Tue | Wed | Thu | Fri | Sat | Sun |
|---|---:|---:|---:|---:|---:|---:|---:|
| % batches started | 19.4 | 21.3 | 20.7 | 20.0 | 15.0 | 2.5 | 1.1 |

**Hours**: 85% of batches start between 07:00 and 16:59, with a peak at 08:00 (16%). 10% start between 18:00 and 23:59, so the hall sometimes runs a late shift.

**Timing of a batch**:
- Scans within a batch: median spread 0 min. Joints are bulk-registered, so **no per-joint time can be measured**.
- Last scan → report transferred: median 0.2 d, p25 0.1, p75 0.6, p90 2.1 (99% have a transfer). Transfers peak at 13:00.
- First scan → `Inspection_Completed_DATE`: median 0 d, p75 1, p90 3.
- Reports are signed in sessions (a gap of more than 30 min starts a new one): a median of 1 report per session, p90 4, max 27.

### 5.2 Numbers for an abstracted hall (from the 2021 report)

The report lists 25 tasks in sequence (full table in Appendix A). The aggregates below are what you need to collapse that sequence into one or a few transitions:

| Quantity | Value |
|---|---|
| Time per joint through all 24 per-joint tasks | **1500 s ≈ 25 min** |
| Slowest task (bottleneck) | MPI fluorescent, **182.5 s** → ≈ 19.7 joints/h for each line; heat check (180 s) is nearly as slow |
| Per joint, if marked scrap from the start (skippable tasks skipped) | 655 s ≈ 11 min (skippable: 846 s) |
| Setup (mobilize) summed over tasks | 5790 s ≈ 1.6 h |
| Teardown (demobilize) summed | 3367 s ≈ 0.9 h |
| UT/EMI calibration | 3980 s ≈ 66 min (per batch, L3) |
| All overhead | ≈ 3.6 h, if run one after another |
| Largest single overhead | UT/EMI scan: 1675 s to set up + 1675 s to tear down |

If the batch is pipelined through one line, it takes `25 min + (n−1) × 182.5 s`:

| n joints | 1 | 2 | 6 | 30 | 90 | 300 |
|---|---:|---:|---:|---:|---:|---:|
| hours (no setup) | 0.42 | 0.47 | 0.67 | 1.9 | 4.9 | 15.6 |

**Labour per joint by certificate level** (wall time = sum of task times; operator time = task time × number of operators):

| Level | tasks | wall s | operator s | max operators on one task |
|---|---:|---:|---:|---:|
| L0 (trainee) | 9 | 383 | 383 | 1 |
| L1 | 11 | 870 | 1062 | 3 (length measurement) |
| L2 | 3 | 151 | 170 | 2 (report check) |
| L3 | 2 | 96 (+3980 calibration per batch) | 96 | 1 |

A higher level can do any task at a lower level.

Tasks that can identify scrap: 1, 2, 3, 6, 7, 10, 11 and 25. Tasks skipped for scrap: 4, 5, 6, 7, 15, 22, 24 and 25.

**Consistency check against our data**:
- Bottleneck capacity is ≈ 158 joints per 8-hour shift, or ≈ 790 per week. We observe a median of 803 per week. ✔
- At p90 (1107) and max (2211) the hall exceeds one shift on one line, which fits the evening scans in §5.1.
- Pipelined time for a median batch (6 joints) is 0.67 h, and for a p90 batch (90) it is 4.9 h. Observed scan → report: median 0.2 d (4.8 h), p90 2.1 d. That fits, and sign-off adds a delay.
- Setup and teardown **cannot** happen in full for every order: ~21 batches/week × 3.6 h would be > 75 h/week. Treat them as per-shift or per-day overhead, or leave them out.

### 5.3 Washing (report only, nothing in our data)

| | Value |
|---|---|
| Mobilize / demobilize per batch | 2190 s (36.5 min) / 590 s (9.8 min) |
| Wash, short pipe ≈ 9.5 m | 90 s |
| Wash, long pipe 13–14 m | 200 s |
| Extra concrete wash | 291 s (rare; only known per order) |
| Change machine between short and long | 1385 s (23 min) |
| Unloading at arrival | ≈ 5 min per bundle, 3 workers |

---

## 6. Inspection outcome (`Orders.calc_Qty_*`)

Orders with `Inspection_Completed_DATE` in the window. The figures are what the system **planned** from inspection criteria. One joint can be counted in more than one category: in 177 of 1842 Rig Return orders, machining + HB exceeds the order size. "Untouched" means joints that go straight to Rig_Ready: for Rig Return that is **36–42% of joints** (lower and upper bounds given the overlap).

| Scope | orders | joints | machining % | HB % | scrap % | P(order has machining) | P(HB) | P(scrap) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Rig Return | 1819 | 50,899 | 53.7 | 9.4 | 5.6 | 68.7 | 20.4 | 21.2 |
| Inspection | 203 | 16,585 | 18.7 | 1.8 | 2.0 | 51.2 | 8.4 | 18.7 |
| VTI | 182 | 6,462 | 12.6 | 0.2 | 0.3 | 22.5 | 0.5 | 4.4 |
| Re Inspection | 251 | 6,380 | 2.8 | 0.2 | 0.1 | 1.6 | 2.4 | 1.2 |
| RtoR + Reinsp | 89 | 4,131 | 0.0 | 0.1 | 0.0 | 0 | 3.4 | 1.1 |
| RtoR | 30 | 848 | 0.0 | 0.4 | 0.0 | 0 | 3.3 | 0 |

**Rig Return by equipment**:

| Equipment | orders | joints | machining % | HB % | scrap % | P(mach) | P(HB) | P(scrap) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Drill Pipe | 628 | 36,141 | 59.3 | 12.4 | 6.6 | 85.5 | 40.9 | 37.1 |
| Tubing | 160 | 6,433 | 21.5 | 0.0 | 2.5 | 61.9 | 0 | 18.1 |
| Heavy Weight | 449 | 3,765 | 62.2 | 7.3 | 4.3 | 64.8 | 22.5 | 12.0 |
| Landing String | 51 | 2,404 | 55.3 | 1.4 | 0.8 | 88.2 | 23.5 | 17.6 |
| Drill Collar | 357 | 1,929 | 38.8 | 0.0 | 5.5 | 58.8 | 0 | 15.4 |
| NM Drill Collar | 131 | 171 | 36.8 | 0.0 | 2.9 | 38.9 | 0 | 3.8 |
| NM Flex Wate | 43 | 56 | 35.7 | 1.8 | 1.8 | 39.5 | 2.3 | 2.3 |

**Inside an affected Rig Return order**:
- Orders with machining send a median of 70% of their joints to machining (p25 37%, p75 100%).
- Orders with scrap scrap a median of 14% of their joints (p25 5%, p75 38%).

So outcomes cluster by order: a per-order draw fits better than independent per-joint coin flips.

**Over time** (Rig Return, per quarter): machining 46–64%, HB 5–14%, scrap 2.5–9%. There is no clear trend, but there is a lot of quarter-to-quarter noise.

Compared with all years (`reference_stats.md`: machining 35%, HB 8%, scrap 3.5%), 2025–26 sends more to machining.

---

## 7. Workshops and the rework loop (`serial_history`, low confidence)

`serial_history` is noisy:
- The current location is blank on 37% of rows.
- Shipping is used both for **rig deliveries and for transfers to workshops**.
- "Inspection" is a status (see §1).

These numbers show the **shape** of the flow. Don't treat them as exact rates.

**Next location after a stay** (row %, moves that start in the window):

| From ↓ / to → | Inspection | Norse | Wepco | Stamas | Hardbanding | Rig_Ready | Scrap | Shipped |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Inspection | – | 0.6 | 1.9 | 0.0 | 0.1 | 21.0 | 0.7 | 75.1 |
| Norse | 11.7 | – | 7.3 | 0.5 | 5.4 | 51.1 | 0.4 | 23.6 |
| Wepco | 10.5 | 4.6 | – | 0.0 | 7.1 | 52.7 | 0.3 | 24.7 |
| Stamas | 7.4 | 0.6 | 0.3 | – | 1.5 | 30.7 | 0.0 | 59.2 |
| Hardbanding | 25.6 | 8.3 | 5.9 | 0.0 | – | 21.3 | 0.1 | 38.9 |
| Rig_Ready | 23.6 | 0.7 | 0.7 | 0.0 | 0.2 | – | 0.1 | 74.6 |

Where joints go after "Inspection → Shipped", and the median gap until the next location:

| Next | Inspection | Norse | Rig_Ready | Wepco | Hardbanding | Scrap |
|---|---:|---:|---:|---:|---:|---:|
| % | 29.0 | 25.5 | 25.3 | 13.2 | 4.4 | 2.1 |
| median gap (d) | 25 | 9 | 56 | 6 | 13 | 12 |

So a joint that leaves inspection for **machining usually goes "Shipped" to Norse or Wepco** and is registered there 6–9 days later. A gap of 25 d before "Inspection" again is a real round trip to a rig and back.

**Time spent at a location** (days, finished stays):

| Location | n | p25 | median | p75 | p90 |
|---|---:|---:|---:|---:|---:|
| Norse | 6912 | 14 | 60 | 112 | 163 |
| Norse, then Rig_Ready | 3529 | 44 | 85 | 127 | 188 |
| Norse, then Inspection | 808 | 0.2 | 16 | 44 | 117 |
| Norse, then Wepco | 505 | 4 | 6 | 8 | 11 |
| Wepco | 5564 | 27 | 69 | 144 | 211 |
| Stamas | 326 | 19 | 43 | 94 | 146 |
| Hardbanding | 1937 | 1 | 35 | 85 | 151 |
| Rig_Ready, then shipped | 15,853 | 0.7 | 27 | 124 | 236 |
| Rig_Ready, then Inspection | 5009 | 0.1 | 0.4 | 1.9 | 8.7 |

Other turnaround measures from `Orders`, for orders inspected in the window:
- Inspection → machining completed: median 31 d (p25 20, p75 51, p90 71), but n is only 152. The date is rarely filled in after mid-2025.
- Inspection → HB completed: median 54 d (p25 25, p75 116), n = 76.
- Inspection → pre-invoice sent: median 2 d (p90 13), n = 2193.

The machining figures don't agree: 31 d from `Orders` against 60 d in Norse. Norse also holds joints after the work is done; Norse → Rig_Ready dwells are long. A reasonable split is **≈ 30 d to machine and the rest as storage**. HB at ≈ 35–55 d is consistent across sources.

**Rework**: after a workshop, ≈ 11% (Norse/Wepco) to 26% (Hardbanding) of joints go back to Inspection. Rig_Ready → Inspection (24%, median 0.4 d) is mostly re-checking or picking right before shipping, not rework.

Joints sitting at each location at the end of the data (open stays): Inspection 13,432, Rig_Ready 8,994, Norse 4,331, Wepco 1,898, Scrap 1,635, Hardbanding 426. These are useful as an **initial marking** if the model starts "now". Expect them to be inflated by joints that left without a recorded move.

---

## 8. Deliveries (`DTs.csv`)

2343 tickets, 87,953 joints in the window. (Received in the same window: 122,776. Deliveries are under-recorded, see `reference_stats.md` §4.)

- Tickets per weekday: mean 4.93, var 14.45 (NB r≈2.55, p≈0.34); none on 7% of weekdays. Joints per weekday: mean 186, p90 456.
- Joints per ticket: median 13, p25 2, p75 48, p90 98, max 632.

| | Mon | Tue | Wed | Thu | Fri | Sat | Sun |
|---|---:|---:|---:|---:|---:|---:|---:|
| % tickets | 16.3 | 18.4 | 19.5 | 21.3 | 23.8 | 0.4 | 0.3 |

| Equipment | tickets | joints | median/ticket |
|---|---:|---:|---:|
| Drill Pipe | 829 | 53,747 | 46 |
| (blank) | 215 | 12,409 | 45 |
| Tubing | 195 | 9,104 | 21 |
| Heavy Weight | 482 | 5,912 | 5 |
| Landing String | 75 | 4,055 | 40 |
| Drill Collar | 398 | 2,499 | 4 |
| NM Drill Collar | 107 | 165 | 1 |
| NM Flex Wate | 42 | 62 | 1 |

---

## 9. Yard capacity (`Location.csv`, snapshot 2026-10-23)

| Area | racks | joints | empty racks | median rows per floor |
|---|---:|---:|---:|---:|
| Rig_Ready | 219 | 11,945 | 84 | 15 |
| Wepco | 1 | 1,494 | 0 | 20 |
| Scrap | 12 | 1,445 | 1 | 15 |
| Norse | 3 | 1,243 | 0 | 15 |
| Hardbanding | 1 | 306 | 0 | 20 |
| Limited_Service | 3 | 296 | 0 | 15 |
| IPC | 2 | 238 | 0 | 15 |
| On_Hold | 2 | 171 | 0 | 17.5 |
| ScrapOCTG | 1 | 105 | 0 | 25 |
| Stamas | 1 | 48 | 0 | 20 |
| Total | 250 | 17,291 | 90 | |

Non-empty racks hold a median of 90 joints (p90 169). A rack's physical maximum isn't recorded; `Maxrowcount` is rows per floor, not joints.

---

## 10. 2021 report vs our data

| Topic | 2021 report | Our data (2025–26) |
|---|---|---|
| Hall time per joint | 25 min end to end, bottleneck 182.5 s | Not measurable, but the implied capacity (~790/week) matches the median of 803/week ✔ |
| Order size | 1–300 | Hall batches median 6, p90 90, max 874; receipts max 899 |
| Setup per batch | ≈ 3.6 h (one task after another) | Impossible with ~21 batches/week, so it must be per shift or shared |
| Scrap | 2 of 12 in the sample (17%), uniform over tasks | Rig Return 5.6% of joints, concentrated in 21% of orders |
| Repair | 1 of 12 (8%) | Machining 54%, HB 9% (Rig Return) |
| Machining time | 2 weeks | ≈ 31 d to complete, 60 d median in Norse |
| Hardbanding time | Up to 6 weeks | Median 35–54 d ✔ |
| After repair | Back to washing + inspection | Mostly → Rig_Ready; 11–26% back to Inspection |
| Queue before the hall | Not modelled | Rig Return median 35 d, the dominant delay |
| Scopes | Drill pipe, full treatment only | 3 behaviour classes (§3); 23% of joints never enter the hall |

---

## 11. Not in the data / caveats

- **Not available anywhere in our data**:
  - per-joint or per-task hall times
  - washing
  - pipe length
  - worker headcount, shifts and certificate levels
  - rack capacity in joints
  - time spent at the rig

  For hall, washing and worker levels the only source is the 2021 report.
- `calc_Qty_*` is the **planned** routing; what was actually done may differ.
- Machining and HB completion dates are almost never filled in after mid-2025.
- The share of Rig Return orders with an inspection date fell to 75% from July 2026, so recent queue numbers look worse than they are.
- `serial_history`: see §7. `DT No` on Shipping rows is the previous ticket.
- Window effects: dwell times near the end of the window are cut off (open stays are excluded from the dwell tables).
- Time scale: values run from 6 s (shortest task) to more than 100 d (workshop storage). The 2021 group had to rescale because simulating in seconds was too slow. In a yard-level model with an abstracted hall, a unit of **hours or minutes** is easier to work with.

---

## Appendix A — 2021 report: inspection tasks (in hall order)

Times are in seconds. "Scrap ID" means the task can find scrap. "Skip if scrap" means a joint already marked scrap skips it (a skip takes 1 s). Mobilize and demobilize happen once per batch; the task time is per joint.

| # | Task | per joint | mobilize | demobilize | scrap ID | skip if scrap | level | operators |
|---:|---|---:|---:|---:|:---:|:---:|:---:|---:|
| 1 | OD gauge & visual tube | 78.5 | 60 | 40 | ✔ | | 1 | 1 |
| 2 | UT wall thickness | 32 | 290 | 90 | ✔ | | 1 | 1 |
| 3 | Internal plastic coating | 30 | 55 | 30 | ✔ | | 1 | 1 |
| 4 | Clean connections | 74.5 | 330 | 152 | | ✔ | 0 | 1 |
| 5 | Grind tong marks | 99 | 205 | 170 | | ✔ | 0 | 1 |
| 6 | MPI fluorescent | 182.5 | 280 | 275 | ✔ | ✔ | 1 | 1 |
| 7 | Heat check | 180 | 55 | 120 | ✔ | ✔ | 1 | 2 |
| 8 | Blow dry connections | 11.5 | 90 | 60 | | | 0 | 1 |
| 9 | RFID tags | 53 | 210 | 70 | | | 1 | 1 |
| 10 | Threads visual inspection | 84 | 340 | 60 | ✔ | | 2 | 1 |
| 11 | Measurements | 124.5 | 250 | 120 | ✔ | | 1 | 1 |
| 12 | Length measurement | 6 | 120 | 50 | | | 1 | 3 |
| 13 | Hardbanding inspection | 28 | 105 | 30 | | | 1 | 1 |
| 14 | Inspection report | 48 | 60 | 0 | | | 2 | 1 |
| 15 | Field repair | 75 | 180 | 160 | | ✔ | 0 | 1 |
| 16 | Painting, connections | 20 | 170 | 40 | | | 0 | 1 |
| 17 | Painting, tubes | 21 | 70 | 20 | | | 0 | 1 |
| 18 | Painting, contrast tubes | 12 | 60 | 20 | | | 0 | 1 |
| 19 | Laser jet marking | 17 | 390 | 30 | | | 1 | 1 |
| 20 | Dope | 44 | 160 | 60 | | | 0 | 1 |
| 21 | Cap | 26 | 300 | 0 | | | 0 | 1 |
| 22 | Restamp | 138.5 | 110 | 75 | | ✔ | 1 | 1 |
| 23 | Report check | 19 | 225 | 20 | | | 2 | 2 |
| 24 | UT/EMI calibration | 3980 (per batch) | 0 | 0 | | ✔ | 3 | 1 |
| 25 | UT/EMI scan | 96.2 | 1675 | 1675 | ✔ | ✔ | 3 | 1 |

The report's sample configuration was 3 × L0, 2 × L1 and 2 × L3 workers, with no L2. Tasks 10, 14 and 23 need L2, so they must have run on L3.

## Appendix B — definitions

- Window filter: receipts by `Returned_Date`, hall batches by first scan, routing by `Inspection_Completed_DATE`, deliveries by `DT_Date`, moves by the start of the stay.
- Cleaning: rows are kept only if they are a pipe equipment type and have quantity > 0. Orders are dropped if machining, HB or scrap exceeds the joints received. `Order_No = 1` (a test record) is excluded from the hall data. Scope labels are merged: Re_Inspection → Re Inspection, R2R → RtoR.
- Slash dates in `serial_history` and `workstation_items` are dd/mm/yyyy (checked: the first field goes up to 31, the second never exceeds 12).
- Stays (§7): each joint's events are sorted by time. A Shipping row with a blank location counts as "Shipped". "Rig Ready" and similar spellings are merged into Rig_Ready. Rig and customer codes count as external. A stay ends when the next event has a different location.
- NB parameters come from the mean and variance: p = μ/σ², r = μ²/(σ² − μ).
