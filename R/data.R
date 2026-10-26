# Readers for the project's data (Lake Michigan, year YEAR from R/paths.R).
source("D:/pyprojects/cv_compare_acmt/R/strata.R")

# EchoNet2Fish interval x layer output (1 m layers in 2021, 10 m in 2024) for one platform, with the platform, each
# interval's polygon stratum and the unit's majority stratum (`stratum`, used for estimation).
# fish_ha Inf (sigma = 0: no single targets) or NA = 0, as EchoNet2Fish does (user, 2026-10-26; 2024 file).
read_acoustic <- function(platform = PLATFORMS[1]) {
  platform <- match.arg(platform, PLATFORMS)
  f <- ACOUSTIC[[platform]]
  d <- read_csv(f, show_col_types = FALSE, guess_max = 1e5) %>%
    mutate(platform = platform, fish_ha = if_else(is.finite(fish_ha), fish_ha, 0))
  g <- read_strata()
  iv <- d %>% distinct(Region_name, Interval, Lat_M, Lon_M) %>%
    mutate(interval_stratum = point_stratum(Lon_M, Lat_M, g))
  d %>% left_join(select(iv, Region_name, Interval, interval_stratum), by = c("Region_name", "Interval")) %>%
    left_join(select(unit_majority(iv), Region_name, stratum), by = "Region_name")
}

# Tows left out: 119411 (TARGET 209, transect "exp", experimental; user, 2026-10-24)
EXCLUDED_TOWS <- c(119411)

# One year's midwater tows (optrop) with their polygon stratum
read_tows <- function(year = YEAR) {
  read_csv(trawl_file("optrop", year), show_col_types = FALSE, guess_max = 1e4) %>%
    filter(!OP_ID %in% EXCLUDED_TOWS) %>%
    mutate(stratum = point_stratum(BEG_LONGITUDE_DD, BEG_LATITUDE_DD))
}
