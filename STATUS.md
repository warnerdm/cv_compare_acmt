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
14. Lake-wide density across years with +-1 SE and ~95% bars (step 08): output/lake_density_2011_2024.png.
15. 2021 by platform (user, 2026-10-26: "does each platform alone give the same shares?"): env var PLATFORM =
   ships / saildrone (empty = pooled); outputs *_2021_ships / *_2021_saildrone. Python matches R.
   Lake-wide CV (acoustic share) pooled / ships (35 transects) / saildrone (68 drone-nights): alewife 13 (54) / 13 (57) /
   14 (62); smelt 53 (9) / 47 (8) / 55 (18); bloater 18 (23) / 22 (60) / 18 (29). Saildrone densities higher than ship
   in every stratum and species (lake-wide alewife 1,615 vs 1,055; bloater 829 vs 590; smelt 167 vs 114).
   User (2026-10-26): limited to data at the same location within 24 h the platform difference all but disappears;
   it reflects where and when each platform sampled (coverage), not the platforms. Supports pooling.
16. Ship data only by default (user, 2026-10-26: "for now I just want to include ship data"): PLATFORM default =
   ships for every year; 2021 pooled = PLATFORM=all (outputs *_2021_all), saildrone = PLATFORM=saildrone. 2021 default
   rerun: lake-wide alewife 1,055/ha (CV 13%; acoustic 57%), smelt 114 (47%; 8%), bloater 590 (22%; 60%). Cross-year
   figures (07, 08) redrawn ship-only. Python matches R (ships, all, saildrone).
17. Next: method 2 (bootstrap).

## Apportionment cross-validation (2026-11-16; user: compare nearest tow, slice mean and model predictions)
- Inputs (step 09): the 20 ACMT.RData of the LM EchoNet2Fish version of record
  (D:/Acoustics/EchoNet2Fish_LM_versions/v1.3.1_2026-11-15), copied to inputs/version_of_record (RData git-ignored;
  manifest.csv committed; SHA-256 match the version's MANIFEST).
- Step 10 (R/apportion_cv.R, analysis/10_apportion_cv.R): 549 tows 2004-2024 with >= 5 fish of six groups (alewife
  <100/>=100, smelt <90/>=90, bloater <120/>=120 mm; length frequencies scaled to catch; alewife and smelt zeroed at
  fishing depth >= 40 m). Each tow predicted without itself by: nearest other tow in year+slice; mean of the other tows
  in year+slice (tow-equal; alone in its slice -> same layer); binomial GAMs per group over all years (fishing depth,
  bottom depth, lon/lat, year random effect; 10-fold by tow, renormalized); rpart tree per year on fish (cp 0.05,
  minbucket 5; leave one tow out). Bottom depth = mean of BEG/END (2018: 11 tows lack END -> BEG).
  Score = total absolute difference (half = share of fish misassigned). Outputs output/apportion_cv/.
- Results, share misassigned (mean over 548 scored tows): GAM 36.7%, nearest 40.3%, slice mean 40.9%, tree 45.7%.
  Paired difference vs nearest (TAD, 95% CI): GAM -0.071 (-0.131, -0.012); slice mean +0.012 (-0.034, 0.058);
  tree +0.109 (0.039, 0.178). Best year: GAM 10, nearest 7, slice mean 2, tree 1. Deep (>= 40 m) tows: GAM 0.205,
  slice 0.292, nearest 0.322, tree 1.077 (tree unsplit by depth at cp 0.05). Upper: GAM 0.803, nearest 0.869,
  slice 0.886, tree 0.894.
- Caveats: the GAM borrows across all years (other years' tows inform it), the slice methods only within the year;
  the tree uses no slice structure (Yule et al. fitted per lake-year with their own settings). One GAM fit warned
  (step failure). Not discussed with the user yet.
- Update (same day, user: a tree that cannot get the 0-40 / >= 40 m split is not right; try a GAM within year).
  Tree response = each fish's size group (6 classes, no ages), fish-weighted as the user's earlier trees. The one tree
  per year put its depth split at 9-61 m (2-6 deep tows a year) -> deep score 1.09. Now one tree per year AND layer
  (40 m rule = first split), cp 0.05, minbucket 5 (Yule). GAM predictions get the 40 m rule too (deep alewife/smelt 0,
  renormalized). Added a within-year GAM (leave one tow out; fallbacks never needed).
  Share misassigned: GAM all years 36.6%, tree 39.5%, nearest 40.3%, GAM within year 40.9%, slice mean 40.9%.
  Paired vs nearest (TAD, 95% CI): GAM all years -0.073 (-0.133, -0.014); tree -0.016 (-0.080, +0.048); slice mean
  +0.012; GAM within year +0.011 (-0.048, +0.071); tree with every tow equal (sensitivity) -0.050 (-0.110, +0.010).
  Deep tows: GAM all years 0.190, tree 0.265, slice 0.292, nearest 0.322, GAM within year 0.341.
  Best year: nearest 6, GAM all years 6, tree 4, GAM within year 3, slice mean 1. Medians: tree 0.449 (lowest), nearest 0.588.
  Reading: only the all-year GAM beats nearest tow clearly; its edge comes from borrowing across years (the
  within-year GAM loses it). Not discussed with the user yet.

## Calibration: archive vs values in use (2026-11-16, step 11; desk calculation, no data)
- Source: the release's calibration_values.csv (read in place; sha256 in the step's output). Archive = the ECS each
  archival survey EV file names (column original_values_used_by_exports); no ECS values -> dt4 header calibration
  (offsets 0) / Simrad file values. Density dB: dt4 dSv - dTS offset; Simrad -2 dSa - dpsi (gain cancels).
  output/calibration_desk/calibration_archive_vs_in_use.csv (one row per vessel-year x archive ECS).
- Simrad (Baird, Sturgeon 2022-2023, Arcticus 2024): density factor 0.99-1.00 everywhere; gains differ by up to 0.33 dB
  but cancel.
- dt4, largest density factors (in use / archive): Steelhead 2004 0.57 (archive TS offset 0.03 vs 2.49); Sturgeon 2006
  1.16-1.72 (three ECS); Steelhead 2007 1.49; Sturgeon 2008 1.51; Sturgeon 2018 1.38; Steelhead 2009 1.25, 2010 1.26;
  Steelhead 2013 1.22 (archive ECS EMPTY today -> header assumed); Steelhead 2023 1.18 (ECS has no values for the
  channel -> header); Steelhead 2014 0.70 and Sturgeon 2014 0.71. Most others within 0.9-1.16.
- Not in the density factor (flags in the table): TS shifts >= 0.5 dB (fixed TS limits), beam angle and angle offset
  differences (beam compensation). Several archive ECS angle offsets look relative to the header (near 0).
- Caveats: Steelhead 2013's ECS is 0 bytes today; whether it was empty when the exports were made is not known. The
  factors are per vessel; the lake-wide effect depends on each vessel's share of the transects. Not discussed with the user yet.

## Inputs: version of record for all years (user decision; carried out 2026-11-18)
- Every year 2004-2024 reads the LM EchoNet2Fish version of record v1.3.1_2026-11-15 (decided in the EchoNet2Fish
  session). Step 09 copies each year's acoustic_<year>.csv (intlaymeans_nph) and ACMT_<year>.RData (SHA-256 checked
  against the version's MANIFEST) and writes trawl_<year>_{optrop,tr_catch}.csv from the RData; R/paths.R and
  python/cvacmt/paths.py read only these (2021 saildrone file still from data/acoustic). 2013's optrop lacks BEG_*_DD:
  filled from Latitude/Longitude (all 31 tows in the same stratum either way).
- 2005: nn1/sn6tonn1 shared leg split as decided in D:/projects/lm_echonet2fish_rerun/TIDYING.md (R/data.R and
  python EXCLUDED_INTERVALS: drop nn1 1-9, sn6tonn1 10-16): 398 -> 382 intervals. 2022 revised inputs: not an issue (user).
- Version of record vs the earlier inputs (2011-2024): identical fish_ha and tows in 2011, 2012, 2014-2017, 2023, 2024;
  2013 one tow fewer (86724, no catch; no effect); 2018/2019 91/140 extra empty rows (fish_ha 0; no effect: the
  layer sums fill 0); 2022 the revised inputs. 2021 differs: the version of record has the archived survey run (25
  transects, 10 m layers, 41 tows = bloaterTS's), the earlier inputs the 2026-11-04 reprocessing (35 transects, 1 m
  layers, 67 tows incl. 25 TARGET 119).
- Rerun (R steps 01-08, every year; Python matches R in every year, worst relative difference 4.7e-8). Units 14-32 a year
  (2006 14, 2010 17). New borrowing case: wn 2010 has no upper tow -> south half (sn + so), as so 2013-2014. Deep
  layer: 68 tows from 16 years, bloater p 0.933. Unit majority tie: 2005 so2 (50/50) goes to sn.
- Lake-wide shares 2004-2024 (output/lake_shares_2004_2024.png; density figure lake_density_2004_2024.png):
  alewife acoustic-dominated in most years (acoustic 46-89%) except 2006 (19%), 2008 (35%), 2021 (41%), 2007/2015/2024 ~half;
  smelt trawl-dominated in most years, acoustic larger in 2007 (62%), 2009 (55%), 2011 (53%); bloater trawl-dominated
  while scarce (2004-2007, 2010-2013; CV 52-1,736%), acoustic-dominated 2009, 2015, 2019, 2021, 2022.
- 2021 (now 25 transects, 41 tows): alewife 519/ha (CV 28%; acoustic 41%) vs 1,055 (13%; 57%) on the earlier inputs;
  bloater 837 (28%; 85%) vs 590 (22%; 60%); smelt 102 (62%; 4%) vs 114 (47%; 8%). Other years change only through the
  wider trawl pooling (e.g. 2016 alewife acoustic 61% -> 65%, 2024 unchanged at 51%).
- data/acoustic and data/trawl are no longer read except the 2021 saildrone file.
