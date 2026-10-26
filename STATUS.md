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
8. Year setting (2026-10-26): env var YEAR (default 2021) in R/paths.R and python/cvacmt/paths.py; outputs
   <name>_<year>.csv/png. 2021 outputs byte-identical after the change; Python matches R for both years (2.4e-8).
9. 2024 (user, 2026-10-26: option 1 = run as 2021, no borrowing; ~20-25 transects is typical effort, 2021 was
   unusual). Ship transects only, 10 m layers. 24 transects: nn 8, no 3, sn 4, so 4, wn 5. Tows: 38, 33 used;
   upper nn 9, no 2, sn 7, so 5, wn 6; deep 4 (2 nn, 2 no), all 100% bloater. fish_ha Inf (sigma = 0; 510 rows)
   and NA (20) set to 0 (user, as EchoNet2Fish).
   Lake-wide (fish/ha): alewife 669 (CV 31%; acoustic 39% / trawl 51% / product 9%), smelt 82 (CV 79%; 9 / 76 / 15),
   bloater 709 (CV 27%; 29 / 60 / 11). vs 2021: CVs about double; trawl still the larger share.
   Note: the 4 deep tows are all bloater, so SE(p_deep) = 0 and the deep layer adds no trawl variance in 2024.
10. 2022 and 2023 (user, 2026-10-26; run as 2024). Ship transects only; 2022 10 m layers, 2023 5 m (all break at 40 m).
   fish_ha Inf/NA set to 0 (2022: 1,054 / 121 rows; 2023: 2,438 / 314). Python matches R (2022 5e-8, 2023 2e-8).
   2022: 26 transects (nn 6, no 3, sn 8, so 6, wn 3); 37 tows, 31 used; upper nn 10, no 3, sn 6, so 1, wn 3; deep 8.
     Lake-wide: alewife 193 (CV 24%; acoustic 69% / trawl 26%), smelt 51 (CV 44%; 19 / 74), bloater 154 (CV 30%; 87 / 9).
     so upper has ONE tow (0 alewife), so so alewife D = 0 with no variance; wn upper bloater p = 0 -> trawl share 0.
   2023: 20 transects (nn 6, no 4, sn 4, so 3, wn 3); 29 tows, 24 used; upper nn 7, no 4, sn 4, so 3, wn 4; deep 2.
     Lake-wide: alewife 1,480 (CV 38%; 80 / 13), smelt 377 (CV 50%; 34 / 45), bloater 382 (CV 72%; 34 / 41).
   Worked examples: 2022 sn bloater (acoustic 97%), 2023 nn alewife (acoustic 86%), 2024 sn bloater.
   Every year 2022-2024 the deep tows are all bloater, so SE(p_deep) = 0 (no deep trawl variance).
   A species with stratum p = 0 or 1 gets trawl SE 0 under p(1-p) scaling (few tows make this common).
11. Trawl pooled across years (user, 2026-10-26; replaces within-year rho_od): upper SD = stratum's pooled within-year
   SD over all years in data/trawl (2011-2019, 2021-2024; df 32-102 per stratum), SE = SD / sqrt(the year's tows);
   deep p and SD from all 57 deep tows (12 years; bloater 0.951, smelt 0.049, SE 0.023). All 4 years rerun; Python
   matches R (<= 5e-8). 11 tows have FISHING_DEPTH 0 (surface tows; kept). 2015 tow 92795 (so2, 112 m water) is a
   real surface tow: 111 age-0 bloater 23-52 mm + 43 small alewife (user, 2026-10-26).
   Lake-wide CV year-only -> pooled (acoustic share pooled): 2021 alewife 13->13 (54%), smelt 37->53 (9%), bloater
   17->18 (23%); 2022 23->23 (74%), 44->37 (23%), 30->29 (88%); 2023 38->37 (86%), 50->46 (40%), 72->64 (44%);
   2024 31->27 (51%), 79->97 (5%), 27->22 (45%).
   A stratum where a species is near 0 in the year now gets the stratum's typical SD -> very large stratum CVs
   (e.g. 2021 so smelt 2,838%); 2022 so alewife D = 0 with SE > 0 (CV Inf).
12. Lake-wide shares across years (step 07, analysis/07_lake_shares_years.R; Python figures.lake_shares_years):
   output/lake_shares_2021_2024.png. Reads method1_lake_<year>.csv of every year run.
13. 2011-2019 added (user, 2026-10-26; sizes skipped for now: small/large bloater likely later, as in the survey
   products 106.L0/L100, 109.L0/L90, 204.L0/L120 (2021 file: 204.L100)). 13 years run, ship transects only except
   2021 (20-29 transects). so has no upper tow with >= 5 fish in 2013 (2 tows, 1 fish) and 2014 (1 tow, 2 fish):
   south half (sn + wn) tows used (user), with the donor covariance in the lake-wide total. Python matches R, all
   13 years (<= 5e-8). Figure: output/lake_shares_2011_2024.png (step 07).
   Pattern: alewife acoustic-dominated in most years (42-86%); smelt trawl-dominated except 2011 (acoustic 56%);
   bloater varies year to year. Bloater nearly absent 2011-2014 (7-126/ha; 3 fish in all 2013 tows).
14. Next: method 2 (bootstrap) on the pooled data.
