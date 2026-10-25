# Readers for the project's data (Lake Michigan 2021).
source("D:/pyprojects/cv_compare_acmt/R/strata.R")

# EchoNet2Fish interval x 1 m layer output for ships or saildrones, with the platform, each interval's polygon
# stratum and the unit's majority stratum (`stratum`, used for estimation)
read_acoustic <- function(platform = c("ships", "saildrone")) {
  platform <- match.arg(platform)
  f <- if (platform == "ships") ACOUSTIC_SHIPS else ACOUSTIC_SAILDRONE
  d <- read_csv(f, show_col_types = FALSE, guess_max = 1e5) %>% mutate(platform = platform)
  g <- read_strata()
  iv <- d %>% distinct(Region_name, Interval, Lat_M, Lon_M) %>%
    mutate(interval_stratum = point_stratum(Lon_M, Lat_M, g))
  d %>% left_join(select(iv, Region_name, Interval, interval_stratum), by = c("Region_name", "Interval")) %>%
    left_join(select(unit_majority(iv), Region_name, stratum), by = "Region_name")
}

# Tows left out: 119411 (TARGET 209, transect "exp", experimental; user, 2026-10-24)
EXCLUDED_TOWS <- c(119411)

# 2021 midwater tows (optrop) with their polygon stratum
read_tows <- function() {
  read_csv(file.path(TRAWL_DIR, "L_2_Y_2021_Acoustic_optrop.csv"), show_col_types = FALSE) %>%
    filter(!OP_ID %in% EXCLUDED_TOWS) %>%
    mutate(stratum = point_stratum(BEG_LONGITUDE_DD, BEG_LATITUDE_DD))
}
