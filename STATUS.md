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

## Next (to discuss with the user)
1. Trawl rules carried over from trawlcomp? (>= 5 fish; alewife below 40 m = contamination; species groups:
   alewife, smelt, bloater, with or without the files' size split 106.L100 / 204.L100.)
2. Depth layers: the files' slices (epi, meta, lake-wide hypo) or a fixed split (40 m)?
3. Method 1 (analytic) and method 2 (bootstrap) for ships and for saildrones; compare CVs and gear shares.
