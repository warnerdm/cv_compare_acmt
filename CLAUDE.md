# cv_compare_acmt

Uncertainty of species density from acoustic + midwater trawl (ACMT) surveys, and the contributions of each gear,
comparing ship and saildrone acoustics (Lake Michigan 2021 to start). Successor of trawlcomp's "two-gear" first
attempt (D:\pyprojects\trawlcomp, docs/TWO_GEAR_METHODS.md: method 1 analytic, method 2 bootstrap, trawl
post-strata), which is frozen there. This project is self-contained: it reads only its own data folder.

**Read `STATUS.md` first.** It holds the current state, decisions and open questions.

## Data (data/, read only; not in git)
- acoustic/: EchoNet2Fish interval x 1 m layer output (fish_ha, sigma, NASC, species columns 106.L0/L100, 109.L0,
  204.L0/L100, slice, nearmt) for 2021: ships (`... ships ... 2026-07-23.csv`, 35 transects) and saildrones
  (`... sd ... 2025-03-07.csv`, 68 drone-nights, drones 1032 and 1046; units named sd<drone>_<m_d>-<m_d>).
  The files' `region` column merges nn into no; do not use it for strata.
- trawl/: L_2_Y_2021_Acoustic_{optrop,tr_catch,tr_lf}.csv, 67 tows = bloaterTS's 41 + 25 TARGET 119 survey-time
  tows + 119411 (excluded, experimental; R/data.R EXCLUDED_TOWS).
- gis/: final_five_strata_new.shp, the five original strata nn, no, sn, so, wn (WGS 84).
- Paths are set once in `R/paths.R`.

## Settled (user, 2026-10-24)
- Strata = the shapefile's five polygons. Intervals and tows placed by point-in-polygon; a ship transect or saildrone
  drone-night (acoustic sampling unit) goes whole to the stratum with the majority of its intervals (sn11 -> so).
- Stratum areas = polygon areas (Great Lakes Albers, EPSG 3175), not EchoNet2Fish regarea.

## Environment
- R 4.4.0: `C:\Program Files\R\R-4.4.0\bin\Rscript.exe` (tidyverse, sf, mgcv installed).
- Code in `R/` (functions); `analysis/` numbered scripts that call them; results in `output/` (git-ignored).
  `run_all.R` runs the scripts in order.

## Working rules
- The user is the fisheries/acoustics expert. Zero fish density in acoustic cells is normal; don't flag zeros.
- One step at a time; ask before changing a settled choice.
- At session end, update `STATUS.md`, commit and `git push`.
