# Reproduction of Adams et al. (2006, NAJFM 26:612-621) depth stratification with their 1994-1995 Lake Michigan
# midwater tows (inputs/adams_1994_1995, copied by step 10). Background: trawlcomp R/strata.R did the same method on
# 2004-2024 tows.
# Tows in the release (TARGET 210): 1994 Grayling (vessel 11) 53, Steelhead (17) 16; 1995 Grayling 1, Steelhead 89.
# Paper: 52 in 1994, 89 in 1995. Working set (2026-11-19): 1994 Grayling + 1995 Steelhead = 142 (53 + 89), one more
# than the paper.
# Bottom depth: not stated in the paper. Figure 2 uses BEG_DEPTH (the paper gives 10-140 m bottom depths; BEG_DEPTH of
# the working set spans 10-140 m, END_DEPTH reaches 153 m); the strata are run with start, mean and end depth.
library(tidyverse)
source("D:/pyprojects/cv_compare_acmt/R/paths.R")

ADAMS_DIR <- file.path(ROOT, "inputs", "adams_1994_1995")
ADAMS_SPECIES <- c(`106` = "alewife", `204` = "bloater", `109` = "smelt")
# Nonprey species the paper dropped before computing proportions (lake trout, lake whitefish, burbot, longnose sucker,
# Chinook salmon). These five large-bodied codes are the only ones of that kind in the 1994-95 catch: 203 whitefish,
# 127 burbot, 404 longnose sucker; 307 and 301 lake trout / Chinook (which is which not checked; both dropped).
ADAMS_NONPREY <- c(307, 203, 127, 404, 301)

# 20325 (1995 Steelhead, 15 Sep) was fished at 40 m with the bottom at 40 m (start; 53 m at the end), the only tow at
# the lakebed. Left out on 2026-11-19 (user: nothing that close to the bottom in the paper's Figure 2), then put back the
# same day to be tested by the strata (with it, 1995 has the paper's 89 tows). adams_tows(excluded = ...) leaves tows out.
ADAMS_LAKEBED_TOW <- 20325

adams_read <- function(f) read_csv(file.path(ADAMS_DIR, f), show_col_types = FALSE, col_types = cols(.default = "c"))

# One row per tow: OP_ID, YEAR, VESSEL, vessel, date, beg_depth, end_depth, fishing_depth, in_working_set,
# catch weights (g) alewife, bloater, smelt, other_prey (all but the three and nonprey), nonprey, total_prey
# (= all but nonprey), catch_rows (0 = no catch records), proportions p_alewife, p_bloater, p_smelt of total_prey.
adams_tows <- function(excluded = integer()) {
  num <- \(x) suppressWarnings(as.numeric(x))
  tows <- adams_read("OP.csv") %>%
    transmute(OP_ID = as.integer(OP_ID), YEAR = as.integer(YEAR), VESSEL = as.integer(VESSEL),
              vessel = recode(VESSEL, `11` = "Grayling", `17` = "Steelhead", .default = "other"),
              date = dmy(OP_DATE), beg_depth = num(BEG_DEPTH), end_depth = num(END_DEPTH)) %>%
    left_join(adams_read("TR_OP.csv") %>% transmute(OP_ID = as.integer(OP_ID), fishing_depth = num(FISHING_DEPTH)),
              by = "OP_ID") %>%
    mutate(in_working_set = ((YEAR == 1994 & VESSEL == 11) | (YEAR == 1995 & VESSEL == 17)) & !OP_ID %in% excluded)
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

# ---- Depth strata (paper's "Depth stratification"; trawlcomp R/strata.R ported) ----
# 1. grid of cell_m x cell_m cells, bottom depth x fishing depth; 2. each cell: mean and SD over its tows (years pooled)
# of the alewife, bloater, smelt proportions by weight; cells with < min_tows tows left out; 3. complete-linkage
# clustering, Euclidean distance on the six values, only cells sharing an edge may join (adespatial::constr.hclust);
# 4. cut into k strata.
ADAMS_GROUPS <- c("alewife", "bloater", "smelt")

# Tows with a bin per axis. bottom: column used as bottom depth (beg_depth, end_depth or mean_depth). edge: a depth on a
# cell boundary goes to the cell below it ("lower": floor(d / cell_m)) or above it ("upper": ceiling(d / cell_m) - 1).
adams_tow_cells <- function(tows, bottom = "beg_depth", cell_m = 20, edge = c("lower", "upper")) {
  edge <- match.arg(edge)
  bin <- if (edge == "lower") \(d) floor(d / cell_m) else \(d) pmax(ceiling(d / cell_m) - 1, 0)
  tows %>%
    filter(in_working_set, !is.na(p_alewife)) %>%
    mutate(mean_depth = (beg_depth + end_depth) / 2, bd = .data[[bottom]],
           bd_bin = bin(bd), fd_bin = bin(fishing_depth), cell = paste(bd_bin, fd_bin, sep = "_"))
}

# sd: "n-1" (sample SD, R's default) or "n" (divide by the number of tows)
adams_cell_stats <- function(tc, min_tows = 2, sd = c("n-1", "n")) {
  sd <- match.arg(sd)
  sdf <- if (sd == "n-1") stats::sd else \(x) sqrt(mean((x - mean(x))^2))
  tc %>%
    summarise(.by = c(cell, bd_bin, fd_bin), tows = n(),
              across(all_of(paste0("p_", ADAMS_GROUPS)), list(mean = mean, sd = sdf), .names = "{.fn}_{.col}")) %>%
    filter(tows >= min_tows) %>%
    arrange(bd_bin, fd_bin)
}

# Neighbouring cells: "rook" = sharing an edge; "queen" = sharing an edge or a corner
adams_links <- function(cs, neighbours = c("rook", "queen")) {
  neighbours <- match.arg(neighbours)
  idx <- seq_len(nrow(cs))
  dx <- abs(outer(cs$bd_bin, cs$bd_bin, "-")); dy <- abs(outer(cs$fd_bin, cs$fd_bin, "-"))
  adj <- if (neighbours == "rook") dx + dy == 1 else pmax(dx, dy) == 1
  as.matrix(expand_grid(i = idx, j = idx) %>% filter(i < j, adj[cbind(i, j)]))
}

# Connected blocks of cells (rook neighbours)
adams_components <- function(cs, neighbours = "rook") {
  comp <- seq_len(nrow(cs)); links <- adams_links(cs, neighbours)
  repeat {
    changed <- FALSE
    for (r in seq_len(nrow(links))) {
      a <- links[r, 1]; b <- links[r, 2]; m <- min(comp[a], comp[b])
      if (comp[a] != m || comp[b] != m) { comp[comp == comp[a] | comp == comp[b]] <- m; changed <- TRUE }
    }
    if (!changed) break
  }
  as.integer(factor(comp))
}

# Strata for one tow set: cells of the largest connected block clustered and cut into k. Returns list(tows = tows with
# their cell and stratum (NA = left out: cell with < min_tows tows, or a cell outside the main block), cells, tree).
adams_strata <- function(tows, k = 4, bottom = "beg_depth", cell_m = 20, edge = "lower", min_tows = 2,
                         sd = "n-1", neighbours = "rook") {
  tc <- adams_tow_cells(tows, bottom, cell_m, edge)
  cs <- adams_cell_stats(tc, min_tows, sd)
  comp <- adams_components(cs, neighbours)
  cs$block <- comp == as.integer(names(which.max(table(comp))))
  cb <- filter(cs, block)
  feat <- as.matrix(cb[c(paste0("mean_p_", ADAMS_GROUPS), paste0("sd_p_", ADAMS_GROUPS))])
  tree <- adespatial::constr.hclust(dist(feat), method = "complete", links = adams_links(cb, neighbours),
                                    coords = as.matrix(cb[c("bd_bin", "fd_bin")]))
  cb$stratum <- cutree(tree, k)
  cs <- left_join(cs, select(cb, cell, stratum), by = "cell")
  list(tows = left_join(tc, select(cs, cell, stratum), by = "cell"), cells = cs, tree = tree, cell_m = cell_m)
}

# Table 4 style summary: tows, cells, depth ranges, mean (SD) proportion over the stratum's tows. Strata named as the
# paper by composition and place: largest mean bloater proportion = Deep; of the rest, the next largest bloater =
# Midwater nearshore; of the remaining two, the deeper mean bottom depth = Shallow offshore, the other Shallow nearshore.
adams_stratum_table <- function(st) {
  s <- st$tows %>% filter(!is.na(stratum)) %>%
    summarise(.by = stratum, tows = n(), cells = n_distinct(cell),
              bottom_m = paste(min(bd_bin) * st$cell_m, (max(bd_bin) + 1) * st$cell_m, sep = "-"),
              fishing_m = paste(min(fd_bin) * st$cell_m, (max(fd_bin) + 1) * st$cell_m, sep = "-"),
              mbd = mean(bd), mfd = mean(fishing_depth),
              across(all_of(paste0("p_", ADAMS_GROUPS)), list(mean = mean, sd = sd), .names = "{.fn}_{.col}"))
  if (nrow(s) == 4) {
    deep <- s$stratum[which.max(s$mean_p_bloater)]; r <- filter(s, stratum != deep)
    mn <- r$stratum[which.max(r$mean_p_bloater)]; r <- filter(r, stratum != mn)
    off <- r$stratum[which.max(r$mbd)]; sn <- setdiff(r$stratum, off)
    nm <- setNames(c("Deep", "Shallow offshore", "Shallow nearshore", "Midwater nearshore"), c(deep, off, sn, mn))
    s$name <- factor(nm[as.character(s$stratum)], c("Shallow nearshore", "Midwater nearshore", "Shallow offshore", "Deep"))
    s <- arrange(s, name)
  }
  select(s, -mbd, -mfd)
}

# Paper's Table 4 (136 tows in 4 strata; mean (SD) proportion by weight)
ADAMS_TABLE4 <- tribble(
  ~name, ~tows, ~mean_p_alewife, ~sd_p_alewife, ~mean_p_smelt, ~sd_p_smelt, ~mean_p_bloater, ~sd_p_bloater,
  "Shallow nearshore", 32, 0.71, 0.32, 0.18, 0.24, 0.06, 0.20,
  "Midwater nearshore", 23, 0.40, 0.38, 0.20, 0.32, 0.38, 0.39,
  "Shallow offshore", 27, 0.93, 0.14, 0.05, 0.12, 0.00, 0.01,
  "Deep", 54, 0.06, 0.10, 0.01, 0.04, 0.90, 0.15)

# ---- Reproduction choice (user, 2026-11-19) ----
# Reference run: start-of-tow bottom depth, lower cell edge, SD n-1, rook neighbours, 20325 in (step 12). The
# clustering puts the 40-60 m bottom x 0-20 m surface cell with Shallow offshore; the paper's Figure 4 and text (division
# at 60 m bottom depth) have it in Shallow nearshore, so it is moved there.
ADAMS_CELL_OVERRIDES <- tribble(~bd_bin, ~fd_bin, ~name,
                                2, 0, "Shallow nearshore")

# Tows and cells of a strata run with paper names, overrides applied. Returns list(tows, cells, cell_m).
adams_named_strata <- function(st, overrides = ADAMS_CELL_OVERRIDES) {
  tab <- adams_stratum_table(st)
  nm <- setNames(as.character(tab$name), tab$stratum)
  fix <- \(d) d %>% mutate(name = nm[as.character(stratum)]) %>%
    left_join(rename(overrides, name_override = name), by = c("bd_bin", "fd_bin")) %>%
    mutate(name = factor(coalesce(name_override, name), levels(tab$name))) %>% select(-name_override)
  list(tows = fix(st$tows), cells = fix(st$cells), cell_m = st$cell_m)
}

# Table 4 from named strata: tows, mean (SD) of each proportion, beside the paper's values
adams_table4 <- function(ns) {
  ours <- ns$tows %>% filter(!is.na(name)) %>%
    summarise(.by = name, tows = n(), cells = n_distinct(cell),
              across(all_of(paste0("p_", ADAMS_GROUPS)), list(mean = mean, sd = sd), .names = "{.fn}_{.col}")) %>%
    mutate(name = as.character(name)) %>%
    pivot_longer(-name, names_to = "var", values_to = "ours")
  paper <- ADAMS_TABLE4 %>% pivot_longer(-name, names_to = "var", values_to = "paper")
  full_join(ours, paper, by = c("name", "var")) %>%
    mutate(name = factor(name, ADAMS_TABLE4$name), var = factor(var, unique(c("tows", "cells", names(ADAMS_TABLE4)[-1])))) %>%
    arrange(name, var)
}

# Diagonal hatching (both directions) clipped to a rectangle, on a grid shared by all cells
adams_hatch <- function(x0, x1, y0, y1, spacing) {
  cs <- seq(-400, 400, by = spacing)
  up <- tibble(c = cs, xa = pmax(x0, y0 + c), xb = pmin(x1, y1 + c)) %>%
    filter(xa < xb) %>% transmute(x = xa, y = xa - c, xend = xb, yend = xb - c)
  dn <- tibble(c = cs, xa = pmax(x0, c - y1), xb = pmin(x1, c - y0)) %>%
    filter(xa < xb) %>% transmute(x = xa, y = c - xa, xend = xb, yend = c - xb)
  bind_rows(up, dn)
}

# Adams Figure 4: the strata in the water column (bottom depth on the top axis, depth on the right), crosshatching
# denser where catch composition is more variable (mean over alewife, bloater, smelt of the SD of tow proportions in
# the stratum), stratum outlines, lakebed diagonal; cells left out (< 2 tows) unhatched.
plot_adams_fig4 <- function(ns, title = NULL, caption = NULL) {
  m <- ns$cell_m
  msd <- ns$tows %>% filter(!is.na(name)) %>%
    summarise(.by = name, across(all_of(paste0("p_", ADAMS_GROUPS)), sd)) %>%
    mutate(mean_sd = (p_alewife + p_bloater + p_smelt) / 3) %>% select(name, mean_sd)
  d <- ns$cells %>% filter(!is.na(name)) %>% left_join(msd, by = "name") %>%
    mutate(x0 = bd_bin * m, x1 = x0 + m, y0 = fd_bin * m, y1 = y0 + m)
  hatch <- pmap(d, \(x0, x1, y0, y1, mean_sd, ...) adams_hatch(x0, x1, y0, y1, 0.6 / mean_sd^1.5)) %>% list_rbind() %>%
    filter(!(x < y - 1e-9 & xend < yend - 1e-9))   # nothing below the lakebed
  st_of <- setNames(as.character(d$name), paste(d$bd_bin, d$fd_bin))
  nb <- \(dx, dy) unname(st_of[paste(d$bd_bin + dx, d$fd_bin + dy)])
  edges <- bind_rows(
    d %>% mutate(o = nb(-1, 0)) %>% filter(is.na(o) | o != name) %>% transmute(x = x0, y = y0, xend = x0, yend = y1),
    d %>% mutate(o = nb(1, 0)) %>% filter(is.na(o) | o != name) %>% transmute(x = x1, y = y0, xend = x1, yend = y1),
    d %>% mutate(o = nb(0, -1)) %>% filter(is.na(o) | o != name) %>% transmute(x = x0, y = y0, xend = x1, yend = y0),
    d %>% mutate(o = nb(0, 1)) %>% filter(is.na(o) | o != name) %>% transmute(x = x0, y = y1, xend = x1, yend = y1)) %>%
    # clip at the lakebed (depth = bottom depth): vertical lines end at y = x, horizontal lines start at x = y
    mutate(yend = if_else(x == xend, pmin(yend, x), yend), x = if_else(y == yend, pmax(x, y), x)) %>%
    filter(x < xend | y < yend)
  # label in the stratum's top row of cells
  labs_df <- d %>% filter(fd_bin == min(fd_bin), .by = name) %>%
    summarise(.by = c(name, mean_sd), x = mean((x0 + x1) / 2), y = mean((y0 + y1) / 2)) %>%
    mutate(label = paste0(name, "\nmean SD ", sprintf("%.2f", mean_sd)))
  ggplot() +
    geom_segment(data = hatch, aes(x, y, xend = xend, yend = yend), linewidth = 0.25, colour = "grey30") +
    geom_polygon(data = tibble(x = c(0, 160, 0), y = c(0, 160, 160)), aes(x, y), fill = "white") +
    geom_segment(data = edges, aes(x, y, xend = xend, yend = yend), linewidth = 0.8) +
    annotate("segment", x = 0, y = 0, xend = 160, yend = 160) +
    geom_label(data = labs_df, aes(x, y, label = label), size = 3, linewidth = 0, fill = alpha("white", 0.85),
               lineheight = 0.9) +
    scale_x_continuous(position = "top", breaks = seq(20, 140, 20), expand = c(0, 0)) +
    scale_y_reverse(position = "right", breaks = seq(0, 140, 20), expand = c(0, 0)) +
    coord_cartesian(xlim = c(0, 160), ylim = c(150, 0)) +
    labs(x = "Bottom depth (m)", y = "Midwater depth (m)", title = title, caption = caption) +
    theme_classic(base_size = 11) + theme(plot.caption = element_text(hjust = 0))
}
