# Strata (user, 2026-10-24): the five original Lake Michigan strata nn, no, sn, so, wn from the shapefile
# data/gis/final_five_strata_new.shp. Every ship and saildrone interval and every tow is placed by point-in-polygon;
# a ship transect or a saildrone drone-night (the acoustic sampling units) goes WHOLE to the stratum holding the
# majority of its intervals (e.g. sn11 lies entirely in the so polygon and is so). Stratum areas = polygon areas.
suppressMessages({ library(tidyverse); library(sf) })
source("D:/pyprojects/cv_compare_acmt/R/paths.R")

read_strata <- function() st_make_valid(st_read(STRATA_SHP, quiet = TRUE))

stratum_areas <- function(g = read_strata()) {
  tibble(stratum = g$stratum, area_ha = as.numeric(st_area(st_transform(g, AREA_CRS))) / 1e4)
}

# Stratum of each point (lon, lat in decimal degrees); NA outside every polygon
point_stratum <- function(lon, lat, g = read_strata()) {
  ok <- !is.na(lon) & !is.na(lat)
  out <- rep(NA_character_, length(lon))
  p <- st_as_sf(tibble(lon = lon[ok], lat = lat[ok]), coords = c("lon", "lat"), crs = 4326)
  hit <- st_intersects(p, g)
  out[ok] <- vapply(hit, \(k) if (length(k)) g$stratum[k[1]] else NA_character_, "")
  out
}

# Majority stratum per acoustic sampling unit (Region_name) from its intervals' polygon strata
unit_majority <- function(intervals) {
  intervals %>% filter(!is.na(interval_stratum)) %>%
    count(Region_name, interval_stratum) %>%
    group_by(Region_name) %>%
    summarise(stratum = interval_stratum[which.max(n)], share = max(n) / sum(n), n_strata = n(), .groups = "drop")
}
