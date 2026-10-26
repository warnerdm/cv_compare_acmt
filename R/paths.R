# Data locations (all inside the project; read only)
ROOT        <- "D:/pyprojects/cv_compare_acmt"
DATA_DIR    <- file.path(ROOT, "data")
# Survey year: env var YEAR (default 2021). 2024 (user, 2026-10-26): ship transects only, run as 2021 (option 1).
YEAR        <- as.integer(Sys.getenv("YEAR", "2021"))
# EchoNet2Fish interval x layer files per year and platform
ACOUSTIC_FILES <- list(
  `2021` = c(ships     = "L2 Y2021 estimates ships intlaymeans_nph 2026-07-23.csv",
             saildrone = "L2 Y2021 estimates sd intlaymeans_nph 2025-03-07.csv"),
  `2024` = c(ships     = "L2 Y2024 ACMT Estimates2025-01-17 intlaymeans_nph 2025-01-17.csv"))
stopifnot(as.character(YEAR) %in% names(ACOUSTIC_FILES))
ACOUSTIC    <- setNames(file.path(DATA_DIR, "acoustic", ACOUSTIC_FILES[[as.character(YEAR)]]),
                        names(ACOUSTIC_FILES[[as.character(YEAR)]]))
PLATFORMS   <- names(ACOUSTIC)
ACOUSTIC_DESC <- if (length(PLATFORMS) > 1) "ship + saildrone acoustics pooled" else paste(sub("s$", "", PLATFORMS), "acoustics only")
TRAWL_DIR   <- file.path(DATA_DIR, "trawl")
trawl_file  <- function(table) file.path(TRAWL_DIR, sprintf("L_2_Y_%d_Acoustic_%s.csv", YEAR, table))
STRATA_SHP  <- file.path(DATA_DIR, "gis", "final_five_strata_new.shp")
OUTPUT_DIR  <- file.path(ROOT, "output")
out_file    <- function(stem, ext = "csv") file.path(OUTPUT_DIR, sprintf("%s_%d.%s", stem, YEAR, ext))
AREA_CRS    <- 3175   # NAD83 / Great Lakes Albers (equal area) for stratum areas
