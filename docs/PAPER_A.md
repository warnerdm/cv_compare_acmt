# Paper A: which gear limits the precision of species density in an acoustic + midwater trawl survey?

Lake Michigan, 2004-2024 (no 2020 survey), ship transects + midwater tows, EchoNet2Fish version of record v1.3.1.
Objectives agreed in general by the user (2026-11-18); whether each is "done" is still to be discussed.

## Objectives

1. **Precision.** Lake-wide and stratum density with CVs for alewife, rainbow smelt and bloater, 20 years.
2. **Sources of uncertainty.** Split each density's variance into acoustic, trawl and product terms (Goodman 1960) by
   species, stratum and year.
3. **Why the shares vary.** Relate the trawl share to abundance, how close a species' proportion is to 0 or 1, number
   of tows and number of transects, to give a rule other surveys can use.
4. **Effort allocation.** The CV reduction from one more tow vs one more transect, per species; an optimal split for a
   given cost ratio.
5. **Method check.** A bootstrap (method 2) to confirm the analytic variance.

Possible later addition: size groups (small / large bloater and alewife).

## Figures and tables (where each comes from)

| Item | Script | Output |
|---|---|---|
| Lake-wide shares by year and species | analysis/07_lake_shares_years.R | output/lake_shares_2004_2024.png |
| Lake-wide density with SE by year | analysis/08_lake_density_years.R | output/lake_density_2004_2024.png |
| Shares by stratum (one year) | analysis/05_shares_figure.R | output/shares_by_stratum_<year>.png |
| Method 1 step by step (one stratum and species) | analysis/04_worked_example.R | output/worked_<stratum>_<group>_<year>.png |
| Objective 3, 4, 5 | not built yet | |
| Adams et al. (2006) Figure 2 rebuilt (1994-95 tows; background for effort allocation) | analysis/11_adams_fig2.R | output/adams_fig2_1994_1995.png |
| Adams et al. (2006) Figure 4 and Table 4 rebuilt | analysis/13_adams_fig4.R | output/adams_fig4_1994_1995.png, adams_table4_1994_1995.csv |

## Claims and their sources

(Add each statement meant for the manuscript here with the output file and run it comes from.)
