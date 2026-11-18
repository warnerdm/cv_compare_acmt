# Readers for the project's data (Lake Michigan, year YEAR from R/paths.R).
source("D:/pyprojects/cv_compare_acmt/R/strata.R")

# EchoNet2Fish interval x layer output (ship transects) with a platform column, each
# interval's polygon stratum and the unit's majority stratum (`stratum`, used for estimation).
# fish_ha Inf (sigma = 0: no single targets) or NA = 0, as EchoNet2Fish does (user, 2026-10-26; 2024 file).
read_acoustic <- function(platform = PLATFORMS[1]) {
  platform <- match.arg(platform, PLATFORMS)
  f <- ACOUSTIC[[platform]]
  d <- read_csv(f, show_col_types = FALSE, guess_max = 1e5) %>%
    mutate(platform = platform, fish_ha = if_else(is.finite(fish_ha), fish_ha, 0)) %>%
    drop_excluded_intervals()
  g <- read_strata()
  iv <- d %>% distinct(Region_name, Interval, Lat_M, Lon_M) %>%
    mutate(interval_stratum = point_stratum(Lon_M, Lat_M, g))
  d %>% left_join(select(iv, Region_name, Interval, interval_stratum), by = c("Region_name", "Interval")) %>%
    left_join(select(unit_majority(iv), Region_name, stratum), by = "Region_name")
}

# Intervals left out (user, 2026-11-14; D:/projects/lm_echonet2fish_rerun/TIDYING.md, row 2005): in 2005 transects nn1
# and sn6tonn1 share a leg (the same pings). Split at the nn/sn stratum boundary, as in the release EV files: keep
# sn6tonn1 intervals 1-9 and nn1 intervals 10-27; drop nn1 intervals 1-9 and sn6tonn1 intervals 10-16.
EXCLUDED_INTERVALS <- tibble(year = 2005, Region_name = c("nn1", "sn6tonn1"), first = c(1, 10), last = c(9, 16))
drop_excluded_intervals <- function(d, year = YEAR) {
  x <- filter(EXCLUDED_INTERVALS, .data$year == .env$year)
  for (i in seq_len(nrow(x)))
    d <- filter(d, !(Region_name == x$Region_name[i] & Interval >= x$first[i] & Interval <= x$last[i]))
  d
}

# Tows left out: 119411 (TARGET 209, transect "exp", experimental; user, 2026-10-24)
EXCLUDED_TOWS <- c(119411)

# One year's midwater tows (optrop) with their polygon stratum
read_tows <- function(year = YEAR) {
  read_csv(trawl_file("optrop", year), show_col_types = FALSE, guess_max = 1e4) %>%
    filter(!OP_ID %in% EXCLUDED_TOWS) %>%
    mutate(stratum = point_stratum(BEG_LONGITUDE_DD, BEG_LATITUDE_DD))
}
