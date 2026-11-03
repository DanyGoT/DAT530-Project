# Pipe yard data (masked)

Exports from the pipe yard's tracking system, Feb 2020 – Oct 2026. The files in the top folder were exported on 2026-10-23, except `DT_Items.csv` and the `Repair_YN` column of `DTs.csv`, which come from a 2026-11-03 export (masked by `../scripts/mask_dt_items.py`). `Old data/` holds an earlier export (2026-10-22) that `Old data/reference_stats.md` is based on.

Customers, rigs and anything else that would identify a customer are replaced by codes. The codes are the same in every file, so joins still work.

## Masking codes

| Code | Replaces | Notes |
|---|---|---|
| `C01`–`C38` | Customer names | Numbered by joints received, `C01` the largest |
| `P01`–`P43` | Item-number prefixes | `P01-578DP.05` = prefix `P01`, then size and type (5 7/8" drill pipe), then set `.05`. Prefixes mostly follow the customer but not one to one. |
| `J000001`… | Joint serial numbers | Same joint, same code in `serial_history`, `workstation_items` and `DT_Items`. `J060478` and up are joints found only in `DT_Items`. |
| `R001`–`R184` | Rigs, fields, countries, other companies' sites | Used in location columns. Spelling variants of one place got separate codes, because the source has them as separate values. |

These names are left as they are, because they don't identify a customer. Yard locations: Inspection, Rig_Ready, Yard, Hardbanding, Scrap, ScrapOCTG, Limited_Service, On_Hold, Booked, Shipped. Workshops: Norse, the main machining and repair shop. Wepco and Stamas, which do machining and hardbanding. Not known: ITM and IPC. Bases and yards: Kverneland, Mongstad, Hammerfest, Ogna.

## File format

- `serial_history.csv` and `workstation_items.csv` are UTF-8, every field in quotes, rows ending in `\r`.
- All other CSVs are UTF-16 LE with a header row, rows ending in `\r`. **They are not real CSV quoting**: a value can contain a bare `"`, for example `4 1/2"`. Split on commas.
- A few records are broken across two lines by a line break inside a value, usually after the item number.

## Flow through the yard

1. **Receive.** Pipe arrives from a rig and gets a receive record.
2. **Order.** Created from the receive, with a scope of work.
3. **Inspection hall** (the "workstation"). Joints are scanned into the hall, inspected and signed off.
4. **Routing.** Joints go to machining or hardbanding (Norse, Wepco, Stamas), or are scrapped. The rest go to Rig_Ready.
5. **Delivery.** Shipped to a rig on a delivery ticket (DT).

## Files

### `receive.csv`: pipe in (one row per receive)

| Column | Meaning |
|---|---|
| `Receive_No` | Receive ID |
| `Quantity` | Joints received |
| `Returned_Date` | Date the pipe came back. Use this for arrival time. |
| `Item_No` | Item number (masked prefix) |
| `Equipment` | Pipe type: Drill Pipe, Tubing, Heavy Weight, Drill Collar, Landing String, … ("NM Flex Wate" is spelled as in the source) |
| `Customer` | Customer code |
| `CreationTimestamp` | When the record was entered. Usually 1–3 days after `Returned_Date`, sometimes up to 17 days. |

### `Orders.csv`: one row per work order

| Column | Meaning |
|---|---|
| `Order_No` | Order ID |
| `Item_No`, `Equipment`, `Customer` | As in `receive.csv` |
| `QTY_Recived` | Joints in the order |
| `calc_Qty_HB` / `calc_Qty_Machining` / `calc_Qty_Scrap` | Calculated by the system from inspection criteria: joints that need hardbanding or machining, or are scrap. This is the planned routing, which may differ from what was actually done. |
| `Scope_Of_Work2` | Order type. **Rig Return**: back from a rig, full treatment. **RtoR**: Rig to Rig, from a rig and straight back out. **Re Inspection** / **Re_Inspection**: same thing. **Redope**: re-dope the threads. **Mobilization**: sent out, no inspection. VTI, TPI: meaning not known. |
| `Spec` | Always empty |
| `Receive_complete_Date` | Hardly used. Some cells hold numbers by mistake. |
| `Receive_No` | Links to `receive.csv` |
| `Inspection_Completed_DATE` | Inspection signed off |
| `Machinig_Completed_Date`, `Hardbaning_Completed_Date` | Rarely filled in after mid-2025 |
| `Pre_Invoice_Sent_Date` | Pre-invoice sent to the customer. Only admin work is left after this. |

### `Workstation.csv`: inspection hall, one row per order batch

| Column | Meaning |
|---|---|
| `Order_No`, `Item_No`, `Equipment` | The order in the hall (`Order_No = 1` is a test record) |
| `CreationTimestamp` | When the batch was set up |
| `Quantity`, `Inspection_Date` | Empty or nearly so. Take the quantity from the order or the receive. |
| `Transfer` | `Report Transfered <timestamp>`: the inspection report was signed off |
| `PrimaryKey` | Links to `workstation_items.ForeignKey` |

### `workstation_items.csv`: one row per joint scanned into the hall

| Column | Meaning |
|---|---|
| `Serial No` | Joint (masked) |
| `Item No` | Item number (masked prefix) |
| `Line` | Place in the physical sequence through the hall, counted within the order: order 1 joints 1, 2, 3, then order 2 joint 1, and so on. Line 1 is furthest in, nearest the output (inferred from batch loading, not recorded). |
| `CreationTimestamp` | Scan time. Joints are scanned in bulk, mostly the same second, so this is when the batch went in, **not** a per-joint service time. |
| `ForeignKey` | Links to `Workstation.PrimaryKey` |

### `serial_history.csv`: one row per joint event (moves, receiving, shipping)

| Column | Meaning |
|---|---|
| `Serial Number` | Joint (masked) |
| `Item Number` | Item number (masked prefix) |
| `CreationTimestamp` | When the event happened |
| `Prev Location` | Where the joint was. Yard location or masked site. |
| `Current Location` | Where it went. Blank on about 37% of rows. |
| `Position` | Position in the rack |
| `Rack Location` | Always empty, so rack occupancy can't be rebuilt back in time |
| `Transaction type` | Relocation, Receiving (also spelled Receive), Shipping. A few rows are blank. |
| `Order No` | Order ID |
| `DT No` | Delivery ticket. **On a Shipping row this is a ticket the joint has already been on**, not a new one. Up to 2024 a Shipping row was written when the joint came **back** on that ticket, a couple of days before the next Receiving. From 2025 most are written at the next dispatch, with the previous ticket. Take dispatch dates from `DTs.csv` via this number, not from the row's timestamp. 97% agree with `DT_Items`. |
| `Rig` | Rig or field (masked) |
| `Site` | Base: Kverneland, Mongstad, Hammerfest |
| `Date` | Meaning not known |

### `DTs.csv`: delivery tickets (pipe out)

| Column | Meaning |
|---|---|
| `DT_No` | Delivery ticket ID |
| `Order_No` | Mostly empty |
| `Item_No`, `Quantity`, `Equipment` | What was shipped. `Equipment` is often empty. |
| `DT_Date` | Delivery date |
| `CreationTimestamp` | Ticket created, usually the day before or the same day |
| `Repair_YN` | **Yes = internal ticket**: not customer-facing, used for repairs and moves between sites and outside companies (the name is misleading). No = customer delivery. From the 2026-11-03 export. |

### `DT_Items.csv`: joints on each delivery ticket

UTF-16 like `DTs.csv`. **Cut off at the export's 2 MB limit**: it stops in DT 12006 (2023-08), so 2020 → Aug 2023 only.

| Column | Meaning |
|---|---|
| `Line` | Line on the ticket |
| `DT_no` | Delivery ticket, links to `DTs.DT_No` |
| `Serial_No` | Joint (masked). Blank on a few junk rows. |
| `Last_inspection` | The joint's last inspection date before the ticket, dd.mm.yyyy (sometimes dd/mm/yyyy) |
| `Last_Inspection_Order` | Always empty |

### `Location.csv`: rack snapshot, 2026-10-23

| Column | Meaning |
|---|---|
| `Rack_ID` | Rack and side, for example `Rack 01 A`. A rack is built like a rib cage: two sides (A and B), several floors each. |
| `Customer` | Customer code |
| `Asset` | The rig the pipe is held for (masked) |
| `Item_Number` … `Item_Number_5` | Up to five item sets in the rack, usually from the same customer |
| `Amount` | Joints in the rack |
| `Site_Location` | Yard area |
| `Maxrowcount` | Rows of pipe per floor |

### Reports

- `week_2026-09-28.md`: detailed study of one week, used to set and check the Petri net model.
- `Old data/reference_stats.md`: whole-period statistics (receipts, routing, processing times, deliveries).
