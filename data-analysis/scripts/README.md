# Scripts behind `../model_datasheet.md`

Run from anywhere. Arg 1 is the data folder, arg 2 is this folder (so `load.py` can be imported):

```bash
cd ~/sync/skole/26H/DAT530/data/scripts
uv run --with pandas python -I analyze.py ../masked "$PWD"   # §2–6, §8–9
uv run --with pandas python -I moves.py   ../masked "$PWD"   # §7 transitions, dwell times, open stays
uv run --with pandas python -I moves2.py  ../masked "$PWD"   # §7 where joints go after "Shipped"
uv run --with pandas python -I overlap.py ../masked "$PWD"   # §6 overlap of machining/HB/scrap counts
uv run --with pandas python -I deliveries.py ../masked "$PWD"   # §8 customer vs internal tickets, §12 joints on tickets
python3 report.py                                            # §5.2 aggregates from the 2021 report's task table
```

`mask_dt_items.py` masked the 2026-11-03 export: it wrote `../masked/DT_Items.csv`, added `Repair_YN` to `../masked/DTs.csv`, and appended the joints new to the key to `../masking_key.csv`. It ran once. Running it again redoes `DT_Items.csv` and leaves `DTs.csv` alone:

```bash
uv run python -I mask_dt_items.py ../data-03-11-2026 ../masked ../masking_key.csv
```

- `load.py`: loaders. `u16()` reads the UTF-16 comma-split files, and `q()` reads the quoted UTF-8 ones.
- The window is hard-coded (`W0`, `W1`) at the top of `analyze.py`, `moves.py`, `moves2.py` and `deliveries.py`.
- `moves2.py` repeats the first half of `moves.py`.
