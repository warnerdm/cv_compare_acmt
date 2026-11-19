# Reproduction of Adams et al. (2006, NAJFM 26:612-621) depth stratification with their 1994-1995 Lake Michigan
# midwater tows (inputs/adams_1994_1995, copied by step 10). Background: trawlcomp R/strata.R did the same method on
# 2004-2024 tows.
# Tows in the release (TARGET 210): 1994 Grayling (vessel 11) 53, Steelhead (17) 16; 1995 Grayling 1, Steelhead 89.
# Paper: 52 in 1994, 89 in 1995. Working set (2026-11-19): 1994 Grayling + 1995 Steelhead = 142, one more than the paper.
# Bottom depth: BEG_DEPTH. The paper gives 10-140 m bottom depths; BEG_DEPTH of the working set spans 10-140 m, END_DEPTH
# reaches 153 m. Inferred, not stated in the paper.
library(tidyverse)
source("D:/pyprojects/cv_compare_acmt/R/paths.R")

ADAMS_DIR <- file.path(ROOT, "inputs", "adams_1994_1995")
ADAMS_SPECIES <- c(`106` = "alewife", `204` = "bloater", `109` = "smelt")
# Nonprey species the paper dropped before computing proportions (lake trout, lake whitefish, burbot, longnose sucker,
# Chinook salmon). These five large-bodied codes are the only ones of that kind in the 1994-95 catch: 203 whitefish,
# 127 burbot, 404 longnose sucker; 307 and 301 lake trout / Chinook (which is which not checked; both dropped).
ADAMS_NONPREY <- c(307, 203, 127, 404, 301)

adams_read <- function(f) read_csv(file.path(ADAMS_DIR, f), show_col_types = FALSE, col_types = cols(.default = "c"))

# One row per tow: OP_ID, YEAR, VESSEL, vessel, date, beg_depth, end_depth, fishing_depth, in_working_set,
# catch weights (g) alewife, bloater, smelt, other_prey (all but the three and nonprey), nonprey, total_prey
# (= all but nonprey), catch_rows (0 = no catch records), proportions p_alewife, p_bloater, p_smelt of total_prey.
adams_tows <- function() {
  num <- \(x) suppressWarnings(as.numeric(x))
  tows <- adams_read("OP.csv") %>%
    transmute(OP_ID = as.integer(OP_ID), YEAR = as.integer(YEAR), VESSEL = as.integer(VESSEL),
              vessel = recode(VESSEL, `11` = "Grayling", `17` = "Steelhead", .default = "other"),
              date = dmy(OP_DATE), beg_depth = num(BEG_DEPTH), end_depth = num(END_DEPTH)) %>%
    left_join(adams_read("TR_OP.csv") %>% transmute(OP_ID = as.integer(OP_ID), fishing_depth = num(FISHING_DEPTH)),
              by = "OP_ID") %>%
    mutate(in_working_set = (YEAR == 1994 & VESSEL == 11) | (YEAR == 1995 & VESSEL == 17))
  w <- adams_read("TR_CATCH.csv") %>%
    transmute(OP_ID = as.integer(OP_ID), SPECIES = as.integer(SPECIES), WEIGHT = num(WEIGHT)) %>%
    mutate(group = if_else(SPECIES %in% ADAMS_NONPREY, "nonprey",
                           coalesce(ADAMS_SPECIES[as.character(SPECIES)], "other_prey"))) %>%
    summarise(.by = c(OP_ID, group), w = sum(WEIGHT), rows = n()) %>%
    mutate(catch_rows = sum(rows), .by = OP_ID) %>%
    select(-rows) %>%
    pivot_wider(names_from = group, values_from = w, values_fill = 0)
  for (g in c("alewife", "bloater", "smelt", "other_prey", "nonprey")) if (!g %in% names(w)) w[[g]] <- 0
  tows %>%
    left_join(w, by = "OP_ID") %>%
    mutate(catch_rows = coalesce(catch_rows, 0L),
           total_prey = alewife + bloater + smelt + other_prey,
           across(c(alewife, bloater, smelt), \(x) if_else(total_prey > 0, x / total_prey, NA_real_), .names = "p_{.col}")) %>%
    arrange(YEAR, date, OP_ID)
}

# Adams Figure 2: each tow at (bottom depth, fishing depth); circle = alewife, square = bloater, plus = rainbow smelt,
# symbol size ~ proportion of catch by weight. Bottom depth on the top axis, depth on the right, lakebed diagonal.
# bottom: the column plotted as bottom depth.
plot_adams_fig2 <- function(d, bottom = "beg_depth", title = NULL, caption = NULL) {
  pts <- d %>%
    filter(!is.na(p_alewife)) %>%
    mutate(bd = .data[[bottom]]) %>%
    pivot_longer(c(p_alewife, p_bloater, p_smelt), names_to = "species", values_to = "p", names_prefix = "p_") %>%
    filter(p > 0) %>%
    mutate(species = factor(species, c("alewife", "bloater", "smelt"), c("Alewife", "Bloater", "Rainbow smelt")))
  ggplot(pts, aes(bd, fishing_depth)) +
    annotate("segment", x = 0, y = 0, xend = 160, yend = 160) +   # lakebed (fishing depth = bottom depth)
    geom_point(aes(shape = species, size = p), stroke = 0.5) +
    scale_shape_manual(values = c(Alewife = 1, Bloater = 0, `Rainbow smelt` = 3), name = NULL) +
    scale_size_area(max_size = 7, limits = c(0, 1), breaks = c(0.1, 0.5, 1), name = "Proportion") +
    scale_x_continuous(position = "top", breaks = seq(20, 140, 20), expand = c(0, 0)) +
    scale_y_reverse(position = "right", breaks = seq(0, 140, 20), expand = c(0, 0)) +
    coord_cartesian(xlim = c(0, 160), ylim = c(150, -5)) +
    labs(x = "Bottom depth (m)", y = "Midwater depth (m)", title = title, caption = caption) +
    theme_classic(base_size = 11) +
    theme(legend.position = "inside", legend.position.inside = c(0.2, 0.2), legend.box = "horizontal", plot.caption = element_text(hjust = 0))
}
