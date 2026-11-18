# Data locations (all inside the project; read only)
ROOT        <- "D:/pyprojects/cv_compare_acmt"
DATA_DIR    <- file.path(ROOT, "data")
# Inputs of every year: the LM EchoNet2Fish version of record v1.3.1_2026-11-15 (user decision; STATUS.md 2026-11-18),
# copied by step 09 (acoustic_<year>.csv, trawl_<year>_<table>.csv; manifest.csv gives each file's source and SHA-256).
VOR_DIR     <- file.path(ROOT, "inputs", "version_of_record")
# Survey year: env var YEAR (default 2021): 2004-2019, 2021-2024 (no 2020 survey). Ship transects only, every year.
YEAR        <- as.integer(Sys.getenv("YEAR", "2021"))
YEARS       <- c(2004:2019, 2021:2024)
stopifnot(YEAR %in% YEARS)
# Acoustic files per platform: ships from the version of record; 2021 saildrones (optional runs) from data/acoustic
ACOUSTIC    <- c(ships = file.path(VOR_DIR, sprintf("acoustic_%d.csv", YEAR)))
if (YEAR == 2021) ACOUSTIC["saildrone"] <- file.path(DATA_DIR, "acoustic", "L2 Y2021 estimates sd intlaymeans_nph 2025-03-07.csv")
# Platform (env var PLATFORM): ships (default; user 2026-10-26: ship data only for now, every year), saildrone, or all
# (pooled ship + saildrone, 2021). Non-default runs are tagged _<year>_<platform> in output names.
PLATFORM    <- Sys.getenv("PLATFORM", "ships")
if (PLATFORM != "all") {
  stopifnot(PLATFORM %in% names(ACOUSTIC))
  ACOUSTIC <- ACOUSTIC[PLATFORM]
}
RUN_TAG     <- if (PLATFORM == "ships") as.character(YEAR) else paste0(YEAR, "_", PLATFORM)
PLATFORMS   <- names(ACOUSTIC)
ACOUSTIC_DESC <- if (length(PLATFORMS) > 1) "ship + saildrone acoustics pooled" else paste(sub("s$", "", PLATFORMS), "acoustics only")
trawl_file  <- function(table, year = YEAR) file.path(VOR_DIR, sprintf("trawl_%d_%s.csv", year, table))
# Trawl years pooled for the between-tow spread (upper) and the deep proportion (user, 2026-10-26): every year with
# an optrop file in the inputs (2004-2024)
TRAWL_YEARS <- sort(as.integer(sub("^trawl_([0-9]{4})_optrop[.]csv$", "\\1",
  list.files(VOR_DIR, "^trawl_[0-9]{4}_optrop[.]csv$"))))
STRATA_SHP  <- file.path(DATA_DIR, "gis", "final_five_strata_new.shp")
OUTPUT_DIR  <- file.path(ROOT, "output")
out_file    <- function(stem, ext = "csv") file.path(OUTPUT_DIR, sprintf("%s_%s.%s", stem, RUN_TAG, ext))
AREA_CRS    <- 3175   # NAD83 / Great Lakes Albers (equal area) for stratum areas
