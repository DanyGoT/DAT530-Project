# DAT530-Project

GPenSIM model of a pipe yard: pipes arrive by truck, are unloaded, washed,
inspected, scrapped or repaired, and shipped to the customer.

## Run

1. Edit the input fields in `pipe_yard_config.m` (times, scrap/repair percent,
   yard capacity, inspection steps and difficulty, workers, shipment size).
2. Run `run_pipe_yard` (or `project_pn`). Tests: `test_pipe_yard`.

GPenSIM is added to the path automatically from `../3_ GPenSIM_v11_System_Files`.

## Modules

| Module | Files | Responsibility |
|---|---|---|
| Logistics | `logistics_pn_pdf.m`, `MOD_Logistics_PRE/POST.m` | Unloading (forklift + crew with one certified driver), yard space, loading and customer shipments |
| Operations | `operations_pn_pdf.m`, `MOD_Operations_PRE/POST.m` | Washing, inspection steps, scrap (leaves inspection early), easy/hard repair |
| IT | `it_pn_pdf.m`, `MOD_IT_POST.m` | Status registers: incoming, ready for washing/inspection/repair, repair done, ready to ship, scrapped. Logs every status change |

Worker levels: easy tasks accept trainee/junior/senior, moderate tasks junior/senior,
hard tasks senior only. The cheapest qualified crew is always picked.

The older single-file model (`pipe_simulation_pdf.m`, `run_pipe_simulation.m`) is kept for reference.
