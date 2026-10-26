# Trawl catch and proportions (user, 2026-10-24: rules as trawlcomp).
# - Groups: alewife (106), smelt (109), bloater (204), by number, summed over life stages; species absent = 0.
# - Alewife in tows fishing deeper than 40 m are contamination and set to 0.
# - Tows need >= 5 fish of the three groups.
# - Depth layers split at 40 m: a tow's layer by its fishing depth; acoustic 1 m layers by their mid-depth.
source("D:/pyprojects/cv_compare_acmt/R/data.R")

GROUPS <- c(`106` = "alewife", `109` = "smelt", `204` = "bloater")
ALEWIFE_CONTAMINATION_DEPTH_M <- 40
MIN_FISH <- 5
LAYER_SPLIT_M <- 40
layer_of <- function(depth) factor(if_else(depth < LAYER_SPLIT_M, "< 40 m", ">= 40 m"), c("< 40 m", ">= 40 m"))

read_catch <- function(year = YEAR) {
  read_csv(trawl_file("tr_catch", year), show_col_types = FALSE) %>%
    transmute(OP_ID, SPECIES = as.integer(SPECIES), N = as.numeric(N))
}

# One row per tow: counts per group, n, fishing depth, layer, stratum; all tows (filter n >= MIN_FISH to use)
tow_catch <- function(tows = read_tows(year), year = YEAR) {
  counts <- read_catch(year) %>%
    filter(SPECIES %in% as.integer(names(GROUPS))) %>%
    mutate(group = GROUPS[as.character(SPECIES)]) %>%
    summarise(.by = c(OP_ID, group), N = sum(N)) %>%
    pivot_wider(names_from = group, values_from = N, values_fill = 0)
  for (g in setdiff(GROUPS, names(counts))) counts[[g]] <- 0
  tows %>%
    transmute(OP_ID, YEAR, VESSEL, TRANSECT, fishing_depth = FISHING_DEPTH, stratum) %>%
    left_join(counts, by = "OP_ID") %>%
    mutate(across(all_of(unname(GROUPS)), \(x) coalesce(x, 0)),
           alewife_removed = if_else(fishing_depth > ALEWIFE_CONTAMINATION_DEPTH_M, alewife, 0),
           alewife = alewife - alewife_removed,
           n = alewife + smelt + bloater,
           layer = layer_of(fishing_depth))
}

# Tows used for proportions (>= MIN_FISH fish), with each group's proportion
tow_props <- function(tc = tow_catch()) {
  tc %>% filter(n >= MIN_FISH) %>% mutate(across(all_of(unname(GROUPS)), \(x) x / n, .names = "p_{.col}"))
}

# Tows used, all pooled trawl years (TRAWL_YEARS), with a `year` column
tow_props_all <- function(years = TRAWL_YEARS) {
  bind_rows(lapply(years, \(y) tow_props(tow_catch(read_tows(y), y)) %>% mutate(year = y)))
}
