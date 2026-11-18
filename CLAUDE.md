# cv_compare_acmt

**Paper A** (user, 2026-11-18): which gear limits the precision of species density in an acoustic + midwater trawl
(ACMT) survey, and what that means for effort. Lake Michigan 2004-2024, ship transects only (each transect = one
acoustic sampling unit). Objectives, figure/table list and claims: `docs/PAPER_A.md`. Successor of trawlcomp's
"two-gear" first attempt (D:\pyprojects\trawlcomp, frozen). Self-contained: reads only its own inputs/ and data/gis.

**Read `STATUS.md` first** (short: state, open issues, next). Dated history: `STATUS_log.md`. Methods:
`docs/METHODS.md` (keep in step with the code).

Moved out 2026-11-18 (user): Paper B (apportionment cross-validation) -> D:\pyprojects\apportion_cv; calibration
desk calculation -> D:\projects\lm_acoustic_data_release\docs\checks\calibration_desk; Python copy retired (git
history); 2021 saildrone option dropped (ship vs saildrone belongs to ship_vs_usv).

## Inputs: the version of record, every year (user decision; carried out 2026-11-18)
- Every year 2004-2024 (no 2020 survey) reads the LM EchoNet2Fish version of record
  D:/Acoustics/EchoNet2Fish_LM_versions/v1.3.1_2026-11-15, copied by step 09 (`analysis/09_copy_version_of_record.R`)
  into `inputs/version_of_record/`: `acoustic_<year>.csv` (intlaymeans_nph), `trawl_<year>_{optrop,tr_catch}.csv`
  (written from the run's ACMT.RData), `ACMT_<year>.RData`. `manifest.csv` (committed) gives each file's source and
  SHA-256; the copies are git-ignored. 2013's optrop lacks BEG_*_DD: filled from Latitude/Longitude (same strata).
- 2022's revised inputs: not an issue (user). 2005: nn1/sn6tonn1 shared leg split as decided in
  D:/projects/lm_echonet2fish_rerun/TIDYING.md (R/data.R EXCLUDED_INTERVALS). Settled; don't re-raise.
- 2021 in the version of record = the archived survey run: 25 transects, 10 m layers, 41 tows.
- data/gis/final_five_strata_new.shp: the five original strata nn, no, sn, so, wn (WGS 84). Paths: `R/paths.R`.

## Settled (user, 2026-10-24)
- Strata = the shapefile's five polygons. Intervals and tows placed by point-in-polygon; a ship transect goes whole to
  the stratum with the majority of its intervals.
- Stratum areas = polygon areas (Great Lakes Albers, EPSG 3175), not EchoNet2Fish regarea.

## Environment
- R 4.4.0: `C:\Program Files\R\R-4.4.0\bin\Rscript.exe` (tidyverse, sf, mgcv installed).
- Survey year: env var `YEAR` (default 2021; 2004-2019, 2021-2024; `YEARS`), read in `R/paths.R`.
  E.g. `YEAR=2024 Rscript run_all.R 01 02 03 04 05 06`; steps 07-08 draw all years run.
  fish_ha Inf (sigma = 0) or NA = 0, as EchoNet2Fish (user, 2026-10-26).
- Trawl pooling (user, 2026-10-26): every year with a trawl_<year>_optrop.csv in inputs/version_of_record
  (TRAWL_YEARS, 2004-2024) feeds the upper-layer pooled within-year SD and the deep p/SD. Adding or removing years
  changes every year's results.
- Code in `R/` (functions); `analysis/` numbered scripts that call them; results in `output/` (git-ignored).
  `run_all.R` runs steps 01-08 in order (step 09, the input copy, is run once by hand).

## Working rules
- The user is the fisheries/acoustics expert. Zero fish density in acoustic cells is normal; don't flag zeros.
- One step at a time; ask before changing a settled choice. Before raising caveats, check STATUS, STATUS_log and the
  related projects' docs for decisions already made.
- At session end, update `STATUS.md` (short) and add a dated entry at the top of `STATUS_log.md`; commit and `git push`.
