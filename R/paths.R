# Data locations (all inside the project; read only)
ROOT        <- "D:/pyprojects/cv_compare_acmt"
DATA_DIR    <- file.path(ROOT, "data")
# Survey year: env var YEAR (default 2021). 2011-2019, 2022-2024 (user, 2026-10-26): ship transects only, run as 2021.
YEAR        <- as.integer(Sys.getenv("YEAR", "2021"))
# EchoNet2Fish interval x layer files per year and platform
ACOUSTIC_FILES <- list(
  `2011` = c(ships     = "L2 Y2011 ACMT Estimates 60db 2023-02-01 intlaymeans_nph 2023-02-01.csv"),
  `2012` = c(ships     = "L2 Y2012 ACMT Estimates 60db 2023-02-03 intlaymeans_nph 2023-02-03.csv"),
  `2013` = c(ships     = "L2 Y2013 ACMT Estimates_2019-05-15 intlaymeans_nph 2019-05-15.csv"),
  `2014` = c(ships     = "L2 Y2014 ACMT Estimates2023-02-07 intlaymeans_nph 2023-02-07.csv"),
  `2015` = c(ships     = "L2 Y2015 ACMT Estimates2020-03-11 intlaymeans_nph 2020-03-11.csv"),
  `2016` = c(ships     = "L2 Y2016 ACMT Estimates2020-03-13 intlaymeans_nph 2020-03-13.csv"),
  `2017` = c(ships     = "L2 Y2017 ACMT Estimates2020-03-15 intlaymeans_nph 2020-03-15.csv"),
  `2018` = c(ships     = "L2 Y2018 ACMT Estimates2020-03-15 intlaymeans_nph 2020-03-15.csv"),
  `2019` = c(ships     = "L2 Y2019 ACMT Estimates2020-07-07 intlaymeans_nph 2020-07-07.csv"),
  `2021` = c(ships     = "L2 Y2021 estimates ships intlaymeans_nph 2026-07-23.csv",
             saildrone = "L2 Y2021 estimates sd intlaymeans_nph 2025-03-07.csv"),
  `2022` = c(ships     = "L2 Y2022 ACMT Estimates 60db2023-02-23 intlaymeans_nph 2023-02-23.csv"),
  `2023` = c(ships     = "L2 Y2023 ACMT Estimates with alewife age2024-03-08 intlaymeans_nph 2024-03-08.csv"),
  `2024` = c(ships     = "L2 Y2024 ACMT Estimates2025-01-17 intlaymeans_nph 2025-01-17.csv"))
stopifnot(as.character(YEAR) %in% names(ACOUSTIC_FILES))
ACOUSTIC    <- setNames(file.path(DATA_DIR, "acoustic", ACOUSTIC_FILES[[as.character(YEAR)]]),
                        names(ACOUSTIC_FILES[[as.character(YEAR)]]))
PLATFORMS   <- names(ACOUSTIC)
ACOUSTIC_DESC <- if (length(PLATFORMS) > 1) "ship + saildrone acoustics pooled" else paste(sub("s$", "", PLATFORMS), "acoustics only")
TRAWL_DIR   <- file.path(DATA_DIR, "trawl")
trawl_file  <- function(table, year = YEAR) file.path(TRAWL_DIR, sprintf("L_2_Y_%d_Acoustic_%s.csv", year, table))
# Trawl years pooled for the between-tow spread (upper) and the deep proportion (user, 2026-10-26): every year with
# an optrop file in data/trawl
TRAWL_YEARS <- sort(as.integer(sub("^L_2_Y_([0-9]{4})_Acoustic_optrop[.]csv$", "\\1",
  list.files(TRAWL_DIR, "^L_2_Y_[0-9]{4}_Acoustic_optrop[.]csv$"))))
STRATA_SHP  <- file.path(DATA_DIR, "gis", "final_five_strata_new.shp")
OUTPUT_DIR  <- file.path(ROOT, "output")
out_file    <- function(stem, ext = "csv") file.path(OUTPUT_DIR, sprintf("%s_%d.%s", stem, YEAR, ext))
AREA_CRS    <- 3175   # NAD83 / Great Lakes Albers (equal area) for stratum areas
