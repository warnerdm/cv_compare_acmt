# cv_compare_acmt

Uncertainty of species density from acoustic + midwater trawl (ACMT) surveys, and the contributions of each gear
(Lake Michigan 2004-2024). Acoustics: SHIP transects only, every year (user, 2026-10-26: "for now I just want to
include ship data"; replaces the 2026-10-24 pooling of 2021 ship + saildrone, still available as PLATFORM=all). Each
ship transect (or saildrone drone-night) is one acoustic sampling unit. Successor of trawlcomp's "two-gear" first
attempt (D:\pyprojects\trawlcomp, docs/TWO_GEAR_METHODS.md: method 1 analytic, method 2 bootstrap, trawl
post-strata), which is frozen there. This project is self-contained: it reads only its own inputs/ and data/ folders.

**Read `STATUS.md` first.** It holds the current state, decisions and open questions. `docs/METHODS.md` describes
the methods (keep it in step with the code).

## Inputs: the version of record, every year (user decision; carried out 2026-11-18)
- Every year 2004-2024 (no 2020 survey) reads the LM EchoNet2Fish version of record
  D:/Acoustics/EchoNet2Fish_LM_versions/v1.3.1_2026-11-15, copied by step 09 (`analysis/09_copy_version_of_record.R`)
  into `inputs/version_of_record/`: `acoustic_<year>.csv` (intlaymeans_nph), `trawl_<year>_{optrop,tr_catch}.csv`
  (written from the run's ACMT.RData), `ACMT_<year>.RData`. `manifest.csv` (committed) gives each file's source and
  SHA-256; the copies are git-ignored. 2013's optrop lacks BEG_*_DD: filled from Latitude/Longitude (same strata).
- 2022's revised inputs: not an issue (user). 2005: nn1/sn6tonn1 shared leg split as decided in
  D:/projects/lm_echonet2fish_rerun/TIDYING.md (R/data.R EXCLUDED_INTERVALS). Settled; don't re-raise.
- 2021 in the version of record = the archived survey run: 25 transects, 10 m layers, 41 tows. The earlier inputs
  (2026-11-04 reprocessing, 35 transects, 1 m layers, 67 tows incl. 25 TARGET 119) are no longer used.

## Data (data/, read only; not in git)
- acoustic/: the 2021 saildrone file (`... sd ... 2025-03-07.csv`, 68 drone-nights; PLATFORM=saildrone / all only) and
  the older per-year files (2011-2024; no longer read). The files' `region` column merges nn into no; do not use it for strata.
- trawl/: older L_2_Y_<year>_Acoustic_* files (2011-2024; no longer read).
- gis/: final_five_strata_new.shp, the five original strata nn, no, sn, so, wn (WGS 84).
- Paths are set once in `R/paths.R` (and `python/cvacmt/paths.py`).

## Settled (user, 2026-10-24)
- Strata = the shapefile's five polygons. Intervals and tows placed by point-in-polygon; a ship transect or saildrone
  drone-night (acoustic sampling unit) goes whole to the stratum with the majority of its intervals (sn11 -> so).
- Stratum areas = polygon areas (Great Lakes Albers, EPSG 3175), not EchoNet2Fish regarea.

## Environment
- R 4.4.0: `C:\Program Files\R\R-4.4.0\bin\Rscript.exe` (tidyverse, sf, mgcv installed). R is the main version.
- Python version of the core steps in `python/` (user, 2026-10-25: for a Python-only collaborator writing a paper on
  the 2021 ship + saildrone data): conda env `cv_compare_acmt` (`environment.yml`; geopandas, pyproj), run from
  `python/`. `python/validate.py` must match the R output (step 03); keep both versions in step when the method
  changes. Call `C:\Users\dmwar\miniconda3\envs\cv_compare_acmt\python.exe` with the env's DLL folders on PATH.
- Env var `PLATFORM`: ships (default, plain output names), saildrone or all (2021 pooled ship + saildrone); non-default
  runs write `<name>_<year>_<platform>`.
- Survey year: env var `YEAR` (default 2021; 2004-2019, 2021-2024; `YEARS`), read in `R/paths.R` /
  `python/cvacmt/paths.py`. E.g. `YEAR=2024 Rscript run_all.R 01 02 03 04 05 06`; steps 07-08 draw all years run.
  fish_ha Inf (sigma = 0) or NA = 0, as EchoNet2Fish (user, 2026-10-26).
- Trawl pooling (user, 2026-10-26): every year with a trawl_<year>_optrop.csv in inputs/version_of_record
  (TRAWL_YEARS, 2004-2024) feeds the upper-layer pooled within-year SD and the deep p/SD. Adding or removing years
  changes every year's results.
- Code in `R/` (functions); `analysis/` numbered scripts that call them; results in `output/` (git-ignored).
  `run_all.R` runs the scripts in order.

## Working rules
- The user is the fisheries/acoustics expert. Zero fish density in acoustic cells is normal; don't flag zeros.
- One step at a time; ask before changing a settled choice.
- At session end, update `STATUS.md`, commit and `git push`.
