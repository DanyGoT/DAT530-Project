# Scripts behind `../model_datasheet.md`

Run from anywhere. Arg 1 is the data folder, arg 2 is this folder (so `load.py` can be imported):

```bash
cd ~/sync/skole/26H/DAT530/data/scripts
uv run --with pandas python -I analyze.py ../masked "$PWD"   # §2–6, §8–9
uv run --with pandas python -I moves.py   ../masked "$PWD"   # §7 transitions, dwell times, open stays
uv run --with pandas python -I moves2.py  ../masked "$PWD"   # §7 where joints go after "Shipped"
uv run --with pandas python -I overlap.py ../masked "$PWD"   # §6 overlap of machining/HB/scrap counts
python3 report.py                                            # §5.2 aggregates from the 2021 report's task table
```

- `load.py`: loaders. `u16()` reads the UTF-16 comma-split files, and `q()` reads the quoted UTF-8 ones.
- The window is hard-coded (`W0`, `W1`) at the top of `analyze.py`, `moves.py` and `moves2.py`.
- `moves2.py` repeats the first half of `moves.py`.
