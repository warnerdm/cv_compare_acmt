# cv_compare_acmt status (2026-11-18)

Paper A: which gear limits the precision of species density in an acoustic + midwater trawl survey, and what that
means for effort. Objectives: `docs/PAPER_A.md`. Dated history: `STATUS_log.md`.

## State
- Inputs: the LM EchoNet2Fish version of record v1.3.1, every year 2004-2024 (no 2020 survey); ship transects only
  (14-32 a year); 2005 nn1/sn6tonn1 split. See CLAUDE.md.
- Method 1 (analytic: Goodman acoustic + trawl + product variance; five strata above 40 m, one lake-wide deep
  proportion; trawl spread pooled over 2004-2024) run for all 20 years. Results: output/method1_*_<year>.csv;
  figures output/lake_shares_2004_2024.png, lake_density_2004_2024.png.
- Pattern: alewife acoustic-limited in most years (exceptions 2006, 2008, 2021); smelt trawl-limited in most years
  (acoustic larger 2007, 2009, 2011); bloater trawl-limited while scarce (2004-2007, 2010-2013), acoustic-limited
  2009, 2015, 2019, 2021, 2022.
- Strata with no upper tow borrow their half's tows: so 2013-2014 (sn + wn), wn 2010 (sn + so).

- Adams et al. (2006) reproduction started (2026-11-19): 1994-95 tows copied (step 10); Figure 2 rebuilt (step 11,
  output/adams_fig2_1994_1995.png) from 1994 Grayling + 1995 Steelhead less 20325 (fished at the lakebed; user) = 141 tows, the
  paper's total (by year 53 + 88, paper 52 + 89).

## Open
- Whether objectives 1-2 count as done (user: discuss later).

## Next
- Adams reproduction: user compares Figure 2 with the paper; then the depth strata (Figure 4,
  Table 4: 136 tows, N 32/23/27/54).

## Next (Paper A objectives not built yet)
- 3: what drives the trawl share (abundance, p near 0/1, tows, transects).
- 4: effort allocation (CV per added tow vs transect; optimal split for a cost ratio).
- 5: bootstrap (method 2) check of the analytic variance.
