# Adams et al. (2006) Figure 4 and Table 4 from the 1994-1995 tows: the reference run of step 12 (start-of-tow bottom
# depth, lower cell edge, SD n-1, rook neighbours, 20325 in) with the 40-60 m surface cell moved to Shallow nearshore
# (user, 2026-11-19; ADAMS_CELL_OVERRIDES in R/adams.R).
# Writes output/adams_fig4_1994_1995.png, output/adams_table4_1994_1995.csv (ours beside the paper),
# output/adams_tow_strata_1994_1995.csv (each tow's cell and stratum).
source("D:/pyprojects/cv_compare_acmt/R/adams.R")
dir.create(OUTPUT_DIR, showWarnings = FALSE)

tows <- adams_tows()
ns <- adams_named_strata(adams_strata(tows, bottom = "beg_depth", edge = "lower", sd = "n-1", neighbours = "rook"))
t4 <- adams_table4(ns)
write_csv(t4, file.path(OUTPUT_DIR, "adams_table4_1994_1995.csv"))
write_csv(select(ns$tows, OP_ID, YEAR, vessel, beg_depth, fishing_depth, cell, name, starts_with("p_")),
          file.path(OUTPUT_DIR, "adams_tow_strata_1994_1995.csv"))
cat(sprintf("%d tows, %d in strata, %d in cells with < 2 tows\n", nrow(ns$tows), sum(!is.na(ns$tows$name)),
            sum(is.na(ns$tows$name))))
print(t4 %>% mutate(across(c(ours, paper), \(x) round(x, 2))) %>%
        pivot_wider(names_from = name, values_from = c(ours, paper)) %>%
        select(var, ends_with("nearshore"), ends_with("offshore"), ends_with("Deep")), width = Inf)

p <- plot_adams_fig4(ns, title = "Adams et al. (2006) Figure 4, rebuilt from the 1994-1995 tows",
                     caption = paste("Denser crosshatching = more variable catch composition (mean SD of the alewife, bloater and smelt",
                                     "proportions by weight).\nUnhatched: cells with fewer than 2 tows. Bottom depth at the start of the tow;",
                                     "40-60 m surface cell placed in Shallow nearshore as in the paper."))
ggsave(file.path(OUTPUT_DIR, "adams_fig4_1994_1995.png"), p, width = 8, height = 6.5, dpi = 200)
