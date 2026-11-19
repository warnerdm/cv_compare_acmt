# Adams et al. (2006) Figure 2 from the 1994-1995 tows (inputs/adams_1994_1995; step 10): catch composition by weight
# of each tow at its bottom depth x fishing depth. Writes the per-tow table and two figures:
#   adams_tows_1994_1995.csv        every TARGET 210 tow, in_working_set marked
#   adams_fig2_1994_1995.png        the working set (1994 Grayling + 1995 Steelhead), as the paper's Figure 2
#   adams_fig2_by_vessel_year.png   all 159 tows, one panel per year x vessel (to find the tows the paper used)
source("D:/pyprojects/cv_compare_acmt/R/adams.R")
dir.create(OUTPUT_DIR, showWarnings = FALSE)

tows <- adams_tows()
write_csv(tows, file.path(OUTPUT_DIR, "adams_tows_1994_1995.csv"))
ws <- filter(tows, in_working_set)
cat("tows by year x vessel (working set marked):\n")
print(count(tows, YEAR, vessel, in_working_set, no_catch = catch_rows == 0, no_prey = coalesce(total_prey, 0) == 0))
cat(sprintf("working set: %d tows; beg depth %g-%g m, end depth %g-%g m, fishing depth %g-%g m\n", nrow(ws),
            min(ws$beg_depth), max(ws$beg_depth), min(ws$end_depth), max(ws$end_depth),
            min(ws$fishing_depth), max(ws$fishing_depth)))

p <- plot_adams_fig2(ws, title = "Adams et al. (2006) Figure 2, rebuilt: 1994 Grayling + 1995 Steelhead tows",
                     caption = sprintf("%d tows (paper: 141; 20325, fished at the lakebed, left out). Bottom depth = depth at the start of the tow. Proportions by weight, nonprey species excluded.",
                                       nrow(ws)))
ggsave(file.path(OUTPUT_DIR, "adams_fig2_1994_1995.png"), p, width = 8, height = 6.5, dpi = 200)

pv <- plot_adams_fig2(mutate(tows, panel = paste(YEAR, vessel)), caption = "All TARGET 210 midwater tows.") +
  facet_wrap(~panel) + theme(legend.position = "bottom")
ggsave(file.path(OUTPUT_DIR, "adams_fig2_by_vessel_year.png"), pv, width = 10, height = 9, dpi = 200)
