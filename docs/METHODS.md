# Methods: acoustic + trawl uncertainty of species density (Lake Michigan 2021)

Code: `R/strata.R`, `R/data.R`, `R/trawl.R`, `R/estimate.R`; steps `analysis/01`-`05` (`run_all.R`).
Builds on trawlcomp's first attempt (`D:\pyprojects\trawlcomp\docs\TWO_GEAR_METHODS.md`).

## Data and strata

- **Acoustics:** EchoNet2Fish interval x 1 m layer output for 2021 (`fish_ha`, sigma from in-situ TS), ship transects
  and saildrone drone-nights **pooled** into one data set. Each ship transect and each drone-night is one sampling
  unit.
- **Trawl:** 2021 midwater tows (the L_2_Y survey tows plus 25 TARGET 119 tows made during the survey; 119411
  excluded as experimental).
- **Strata:** the five original strata (nn, no, sn, so, wn) from `data/gis/final_five_strata_new.shp`. Intervals and
  tows are placed by point-in-polygon; a sampling unit goes whole to the stratum holding the majority of its
  intervals. Stratum areas are the polygon areas (Great Lakes Albers).

## Species density in a stratum

- Groups: alewife, rainbow smelt, bloater (by number, summed over life stages). Tows need >= 5 fish of the three;
  alewife in tows fishing deeper than 40 m are set to 0 (contamination).
- Two depth layers, split at 40 m (tows by fishing depth; acoustic 1 m layers by mid-depth).
- **D_s = rho_upper,s x p_upper,s + rho_lower,s x p_deep**
  - rho: mean over the stratum's units of the unit's mean (over intervals) summed `fish_ha` in the layer.
  - p_upper,s: mean of the stratum's 2021 tow proportions above 40 m. p_deep: mean of all 2021 deep tows
    lake-wide (7 tows), used for every stratum.

## Uncertainty (method 1, analytic)

- **Acoustic:** each unit's species density with the proportions fixed, D_u = rho_upper,u p_upper + rho_lower,u p_deep;
  Var_ac = variance of D_u over the stratum's units / number of units.
- **Trawl:** SE(p) = SD / sqrt(tows). Above 40 m, SD = sqrt(rho_od x p(1 - p)), where rho_od is one overdispersion
  (intra-tow correlation) per species pooled over all strata (alewife 0.63, bloater 0.65, smelt 0.55); this scales
  each stratum's SD to its own composition. Deep: the SD of the 7 deep tows.
  Var_tr = rho_upper^2 SE(p_upper)^2 + rho_lower^2 SE(p_deep)^2.
- **Product:** Var(rho_upper) SE(p_upper)^2 + Var(rho_lower) SE(p_deep)^2.
- **Var(D_s) = Var_ac + Var_tr + product** (Goodman 1960). The shares of the three terms show which gear drives the
  uncertainty.
- **Lake-wide:** mean density = sum(A_s D_s) / sum(A_s). Strata are independent except for the shared deep
  proportion, whose trawl variance enters as (sum A_s rho_lower,s)^2 SE(p_deep)^2.

## Reading the shares figure (`output/shares_by_stratum_2021.png`, step 05)

- **Purpose:** to show the **relative contribution** of the acoustics and the trawl to the uncertainty of each
  species' density, and the **patterns** in it: which gear dominates for which species and where. Each bar is a
  share of one density's variance and always sums to 1, whatever the size of that variance.
- Patterns in 2021: the acoustics dominate a stratum's main species where the trawl proportion is well
  determined (alewife in nn and no); the trawl dominates minor species and strata with few or variable tows
  (bloater and smelt almost everywhere).
- The CV labels are context only. A bar's shares do not depend on how large the CV is, and a stratum's CV is not a
  measure of its weight in the lake-wide estimate (see the next section). Bars with very large CVs belong to
  species that are nearly absent from that stratum.

## Reading stratum CVs vs the lake-wide CV

The lake-wide CV is usually smaller than every stratum's CV, and strata with very large CVs (hundreds of percent)
often barely affect it. Two reasons:

1. **Independent errors partly cancel.** The strata are estimated independently, so some come out high and others
   low. Variances add, so the SE of the total grows only as the square root of the summed squared stratum errors,
   not as their sum.
2. **A CV is relative.** A huge CV can sit on a tiny absolute error when the density is tiny. What adds up in the
   lake-wide uncertainty is each stratum's absolute error (area x SE), not its CV.

**Alewife, 2021 (lake-wide CV 13%, every stratum 18-37%):**

| Stratum | Density (alewife/ha) | SE | CV | Area x density (alewife) | Area x SE |
|---|---|---|---|---|---|
| nn | 1,056 | 280 | 26% | 1.45 billion | 0.38 billion |
| no | 1,767 | 490 | 28% | 2.29 billion | 0.63 billion |
| wn | 637 | 238 | 37% | 0.44 billion | 0.16 billion |
| sn | 2,497 | 456 | 18% | 2.44 billion | 0.45 billion |
| so | 1,106 | 409 | 37% | 1.19 billion | 0.44 billion |
| **Lake** | | | | **7.80 billion** | sqrt(0.38^2 + 0.63^2 + 0.16^2 + 0.45^2 + 0.44^2) = **0.98 billion** |

Lake-wide CV = 0.98 / 7.80 = 12.6%. Adding the stratum errors instead (2.06 billion, CV 26%) would assume every
stratum is off in the same direction. Alewife are spread over all five strata, so the cancellation is strong.

**Smelt, 2021 (lake-wide CV 37%, strata 38-618%):**

| Stratum | Density (smelt/ha) | SE | CV | Area x density (smelt) | Area x SE |
|---|---|---|---|---|---|
| nn | 413 | 158 | 38% | 566 million | 217 million |
| no | 33 | 108 | 327% | 43 million | 140 million |
| wn | 134 | 125 | 93% | 91 million | 85 million |
| sn | 90 | 99 | 110% | 87 million | 96 million |
| so | 4 | 25 | 618% | 4 million | 27 million |
| **Lake** | 147 | 54 | **37%** | **792 million** | **about 290 million** |

- so's 618% is 25 smelt/ha of error on 4 smelt/ha: about 27 million smelt against a lake total of ~800 million.
- nn holds ~70% of the smelt with a CV of 38%; its absolute error is the largest piece, so the lake-wide CV is close
  to nn's.
- sqrt(217^2 + 140^2 + 85^2 + 96^2 + 27^2) ~ 290 million = 37% of 792 million.

**Rule of thumb:** a stratum's CV tells how well that stratum's density is known; its contribution to the lake-wide
uncertainty depends on its absolute error (area x SE). Huge CVs on tiny densities can usually be ignored for the
lake-wide estimate. (The shared deep proportion is the one non-cancelling part; it is zero for alewife and small
for smelt and bloater.)

Reference: Goodman, L. A. 1960. On the exact variance of products. Journal of the American Statistical Association
55: 708-713.
