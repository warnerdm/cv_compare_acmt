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

- Method 1 on pooled acoustics (step 03, R/estimate.R; user 2026-10-24: five strata above 40 m for both gears; deep
  layer = one lake-wide 2021 trawl proportion, 7 tows; deep trawl variance fully correlated in the lake total).
  Goal (user): the contributions of acoustics and trawl to the overall CV, as in trawlcomp's two-gear work.
- Trawl SE above 40 m: POOLED OVERDISPERSION (user, 2026-10-24): Var(tow p) ~ rho_od x p(1 - p), one rho_od per
  species from all strata (alewife 0.63, bloater 0.65, smelt 0.55), SD_s = sqrt(rho_od pbar_s(1 - pbar_s)),
  SE = SD_s / sqrt(n_s). Replaces a plain pooled SD, which inflated strata where a species is near 0 or 1.
- Results 2021, lake-wide mean density (fish/ha): alewife 1,440 (CV 13%; acoustic 58% / trawl 40%), smelt 147
  (CV 37%; 20% / 77%), bloater 743 (CV 17%; 24% / 74%). By stratum: acoustics dominate alewife in nn and no;
  the trawl dominates elsewhere and for bloater and smelt. Acoustic CVs per stratum x upper layer 11-26%.

## Next (to discuss with the user)
1. (Settled: see 3.)
2. Ship and saildrone acoustics are POOLED (user, 2026-10-24; no comparison). Pooled acoustic units per stratum:
   nn 25, no 12, sn 33, so 20, wn 13 (ship transects + saildrone drone-nights).
3. Deep layer without tows (no in 2021): 2021 lake-wide deep proportion (user, as trawlcomp).
4. Worked-example figure (step 04, STRATUM / GROUP env vars; default sn bloater): output/worked_sn_bloater_2021.png;
   matches step 03 (D 1,671, SE 406, CV 24%: trawl 80%, acoustic 19%).
   Also drawn: nn alewife (D 1,056, CV 26%, acoustic 72%) and so bloater (D 1,755, CV 26%, trawl 66%).
   Example (user: a great example): nn alewife's acoustic share comes largely from one drone-night,
   sd1046_9_2-9_3 (~5,970 alewife/ha); without it D 852, CV 20%, acoustic 52% / trawl 47%. Kept (real data).
5. Shares by stratum and lake-wide (step 05): output/shares_by_stratum_2021.png (as trawlcomp two_gear ..._region_layer.png).
6. Lake-wide mean density by species with +-1 SE and ~95% bars (step 06): output/lake_density_2021.png.
7. Python version of the core steps (user, 2026-10-25; for a Python-only collaborator writing a paper on the 2021
   ship + saildrone data): python/ (cvacmt package, run_method1.py, validate.py, README.md), conda env
   cv_compare_acmt (environment.yml). Matches R step 03 to ~1e-15 (areas ~2e-8: geometry library versions).
   python/make_figures.py draws the step 04-06 figures (matplotlib) to output/python/.
8. Next: method 2 (bootstrap) on the pooled data.
