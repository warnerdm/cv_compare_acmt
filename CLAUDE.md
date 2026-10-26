# cv_compare_acmt

Uncertainty of species density from acoustic + midwater trawl (ACMT) surveys, and the contributions of each gear
(Lake Michigan 2021 to start). Ship and saildrone acoustic data are POOLED into one acoustic data set (user,
2026-10-24: no ship vs saildrone comparison); each ship transect and each saildrone drone-night is one acoustic
sampling unit. Successor of trawlcomp's "two-gear" first
attempt (D:\pyprojects\trawlcomp, docs/TWO_GEAR_METHODS.md: method 1 analytic, method 2 bootstrap, trawl
post-strata), which is frozen there. This project is self-contained: it reads only its own data folder.

**Read `STATUS.md` first.** It holds the current state, decisions and open questions. `docs/METHODS.md` describes
the methods (keep it in step with the code).

## Data (data/, read only; not in git)
- acoustic/: EchoNet2Fish interval x 1 m layer output (fish_ha, sigma, NASC, species columns 106.L0/L100, 109.L0,
  204.L0/L100, slice, nearmt) for 2021: ships (`... ships ... 2026-07-23.csv`, 35 transects) and saildrones
  (`... sd ... 2025-03-07.csv`, 68 drone-nights, drones 1032 and 1046; units named sd<drone>_<m_d>-<m_d>).
  The files' `region` column merges nn into no; do not use it for strata.
- 2024 (user, 2026-10-26): acoustic `L2 Y2024 ACMT Estimates2025-01-17 intlaymeans_nph 2025-01-17.csv` (ships only,
  10 m layers, 24 transects); trawl `L_2_Y_2024_Acoustic_*` (38 tows).
- trawl/: L_2_Y_<year>_Acoustic_{optrop,tr_catch[,tr_lf]}.csv for 2011-2019, 2021-2024 (user, 2026-10-26). 2021: 67 tows = bloaterTS's 41 + 25 TARGET 119 survey-time
  tows + 119411 (excluded, experimental; R/data.R EXCLUDED_TOWS).
- gis/: final_five_strata_new.shp, the five original strata nn, no, sn, so, wn (WGS 84).
- Paths are set once in `R/paths.R`.

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
- Survey year (2026-10-26): env var `YEAR` (default 2021; 2011-2019, 2021-2024), read in `R/paths.R` / `python/cvacmt/paths.py`
  (`ACOUSTIC_FILES` lists each year's acoustic files by platform). E.g. `YEAR=2024 Rscript run_all.R`.
  fish_ha Inf (sigma = 0) or NA = 0, as EchoNet2Fish (user, 2026-10-26).
- Trawl pooling (user, 2026-10-26): every year with an optrop file in data/trawl (TRAWL_YEARS) feeds the upper-layer
  pooled within-year SD and the deep p/SD. Adding or removing trawl files changes every year's results.
- Code in `R/` (functions); `analysis/` numbered scripts that call them; results in `output/` (git-ignored).
  `run_all.R` runs the scripts in order.

## Working rules
- The user is the fisheries/acoustics expert. Zero fish density in acoustic cells is normal; don't flag zeros.
- One step at a time; ask before changing a settled choice.
- At session end, update `STATUS.md`, commit and `git push`.
