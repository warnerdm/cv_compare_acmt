# Data locations (all inside the project; read only)
ROOT        <- "D:/pyprojects/cv_compare_acmt"
DATA_DIR    <- file.path(ROOT, "data")
ACOUSTIC_SHIPS     <- file.path(DATA_DIR, "acoustic", "L2 Y2021 estimates ships intlaymeans_nph 2026-07-23.csv")
ACOUSTIC_SAILDRONE <- file.path(DATA_DIR, "acoustic", "L2 Y2021 estimates sd intlaymeans_nph 2025-03-07.csv")
TRAWL_DIR   <- file.path(DATA_DIR, "trawl")
STRATA_SHP  <- file.path(DATA_DIR, "gis", "final_five_strata_new.shp")
OUTPUT_DIR  <- file.path(ROOT, "output")
AREA_CRS    <- 3175   # NAD83 / Great Lakes Albers (equal area) for stratum areas
