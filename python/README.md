# Python version (core steps)

A Python version of the project's core steps for Lake Michigan 2021, mirroring the R code in `../R/`:
strata from the shapefile (point-in-polygon, majority per acoustic unit, polygon areas), the trawl rules and
proportions, pooled ship + saildrone acoustic units, and method 1 (species density with its acoustic, trawl and
product variance, by stratum and lake-wide). See `../docs/METHODS.md` for the methods.

| Module | Mirrors | Contents |
|---|---|---|
| `cvacmt/paths.py` | `R/paths.R` | data paths |
| `cvacmt/strata.py` | `R/strata.R` | `read_strata`, `stratum_areas`, `point_stratum`, `unit_majority` |
| `cvacmt/data.py` | `R/data.R` | `read_acoustic(platform)`, `read_tows` |
| `cvacmt/trawl.py` | `R/trawl.R` | `tow_catch`, `tow_props` (trawl rules) |
| `cvacmt/estimate.py` | `R/estimate.R` | `acoustic_units`, `trawl_cells`, `method1` |

## Run

```
conda env create -f ../environment.yml      # once: python 3.12, pandas, numpy, geopandas, pyproj
conda activate cv_compare_acmt
cd python
python run_method1.py   # writes output/python/method1_*.csv (same names and columns as R step 03)
python validate.py      # compares with the R output (output/method1_*.csv); needs R step 03 run first
```

Validation (2026-10-25): every acoustic, trawl and stratum value matches R to ~1e-15 relative; stratum areas
differ by ~2e-8 relative (geometry library versions), so lake-wide values match to ~1e-8.

The figures (steps 04-06) are R only.
