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
# Acoustics: ship transects only (user, 2026-11-18: the saildrone option dropped; ship vs saildrone is ship_vs_usv's).
ACOUSTIC    <- c(ships = file.path(VOR_DIR, sprintf("acoustic_%d.csv", YEAR)))
RUN_TAG     <- as.character(YEAR)
PLATFORMS   <- names(ACOUSTIC)
ACOUSTIC_DESC <- "ship acoustics"
trawl_file  <- function(table, year = YEAR) file.path(VOR_DIR, sprintf("trawl_%d_%s.csv", year, table))
# Trawl years pooled for the between-tow spread (upper) and the deep proportion (user, 2026-10-26): every year with
# an optrop file in the inputs (2004-2024)
TRAWL_YEARS <- sort(as.integer(sub("^trawl_([0-9]{4})_optrop[.]csv$", "\\1",
  list.files(VOR_DIR, "^trawl_[0-9]{4}_optrop[.]csv$"))))
STRATA_SHP  <- file.path(DATA_DIR, "gis", "final_five_strata_new.shp")
OUTPUT_DIR  <- file.path(ROOT, "output")
out_file    <- function(stem, ext = "csv") file.path(OUTPUT_DIR, sprintf("%s_%s.%s", stem, RUN_TAG, ext))
AREA_CRS    <- 3175   # NAD83 / Great Lakes Albers (equal area) for stratum areas
