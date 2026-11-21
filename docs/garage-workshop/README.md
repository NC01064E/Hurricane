# Garage workshop conversion

Documentation for converting the back 19 x 12 ft of the garage into a conditioned workshop / gym / mancave. **This folder is unrelated to the Roku channel in the rest of the repository.**

> **Roku packaging:** the channel README says to re-zip the channel and sideload it. A zip made from the repo root would also pick up `docs/` (about 1 MB with the PDF). Leave `docs/` out of the zip.

| File | What it is |
|---|---|
| `PLAN.md` | the corrected plan (changes marked) |
| `AUDIT.md` | every finding, what was verified, and sources |
| `CUTLIST.md` | formulas, framing layout, cut list, lumber and sheet goods, hardware |
| `SIZING.md` | hand load estimate behind the 12K mini-split choice |
| `BUDGET.md`, `budget.csv` | the plan's prices re-added, corrected and completed |
| `CHECKLIST.md` | phase-by-phase checklist with gates |
| `drawings/` | the three schematics, redrawn from the model |
| `garage-workshop-plan-corrected.pdf` | all of the above in one document |
| `tools/` | `model.py`, `sizing.py`, `budget.py`, `drawings.py`, `build_docs.py`, `build_pdf.sh` - regenerate everything |

To regenerate after measuring the wall height: edit `H` in `tools/model.py`, then `python3 tools/build_docs.py` and `python3 tools/drawings.py`.
