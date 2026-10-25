# cv_compare_acmt status

## Current state (2026-10-24)
- Project created (user: folder and data; Claude: skeleton). Data: ship and saildrone EchoNet2Fish 2021 interval x
  1 m layer files, 2021 trawl (67 tows), strata shapefile. See CLAUDE.md.
- Step 01 (`analysis/01_assign_strata.R`): strata assigned.
  - Stratum areas (ha): nn 1,371,397; no 1,294,125; sn 977,257; so 1,071,138; wn 682,813 (polygons; EchoNet2Fish
    regarea is smaller for nn +25%, sn +12%, wn +14%).
  - Ships: 35 transects -> nn 10, no 2, sn 13, so 7, wn 3. nn8 splits (91% nn); sn11 lies wholly in so -> so.
  - Saildrones: 68 drone-nights -> nn 15, no 10, sn 20, so 13, wn 10; 12 cross a boundary (majority 56-92%).
  - Tows: 66 used (119411, an nn tow, excluded) -> nn 20, no 4, sn 23, so 13, wn 6 (output/tows_strata.csv).

- Trawl rules (user, 2026-10-24, as trawlcomp): >= 5 fish of alewife/smelt/bloater (by number, summed over life
  stages; no size split for now); alewife in tows deeper than 40 m = contamination (set to 0); layers split at 40 m
  (tows by fishing depth, acoustic 1 m layers by mid-depth). R/trawl.R; step 02 (`analysis/02_trawl_proportions.R`).
  66 tows: 1 without catch rows, 4 with < 5 fish -> 62 used; 25 alewife removed in 5 deep tows.
  Tows per stratum x layer (< 40 / >= 40 m): nn 17/1, no 3/0, sn 21/1, so 9/4, wn 5/1. no has no deep tow.

## Next (to discuss with the user)
1. no >= 40 m has no tow: lake-wide deep proportion (as trawlcomp), or another rule?
2. Ship and saildrone acoustics are POOLED (user, 2026-10-24; no comparison). Pooled acoustic units per stratum:
   nn 25, no 12, sn 33, so 20, wn 13 (ship transects + saildrone drone-nights).
3. Deep layer without tows (no in 2021): 2021 lake-wide deep proportion (user, as trawlcomp).
4. Open: trawl SD source / post-strata for the trawl; then method 1 and method 2 on the pooled acoustics.
