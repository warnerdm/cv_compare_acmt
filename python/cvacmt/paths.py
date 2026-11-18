"""Data locations (inside the project; read only). Mirrors R/paths.R."""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "data"
# Inputs of every year: the LM EchoNet2Fish version of record v1.3.1_2026-11-15 (user decision; STATUS.md 2026-11-18),
# copied by R step 09 (acoustic_<year>.csv, trawl_<year>_<table>.csv; manifest.csv gives each file's source and SHA-256).
VOR_DIR = ROOT / "inputs" / "version_of_record"
# Survey year: env var YEAR (default 2021): 2004-2019, 2021-2024 (no 2020 survey). Ship transects only, every year.
YEAR = int(os.environ.get("YEAR", "2021"))
YEARS = [*range(2004, 2020), *range(2021, 2025)]
assert YEAR in YEARS, f"YEAR {YEAR} not in {YEARS}"
# Acoustic files per platform: ships from the version of record; 2021 saildrones (optional runs) from data/acoustic
ACOUSTIC = {"ships": VOR_DIR / f"acoustic_{YEAR}.csv"}
if YEAR == 2021:
    ACOUSTIC["saildrone"] = DATA_DIR / "acoustic" / "L2 Y2021 estimates sd intlaymeans_nph 2025-03-07.csv"
# Platform (env var PLATFORM): ships (default; user 2026-10-26: ship data only for now, every year), saildrone, or all
# (pooled ship + saildrone, 2021). Non-default runs are tagged _<year>_<platform> in output names.
PLATFORM = os.environ.get("PLATFORM", "ships")
if PLATFORM != "all":
    ACOUSTIC = {PLATFORM: ACOUSTIC[PLATFORM]}
RUN_TAG = str(YEAR) if PLATFORM == "ships" else f"{YEAR}_{PLATFORM}"
PLATFORMS = list(ACOUSTIC)
ACOUSTIC_DESC = ("ship + saildrone acoustics pooled" if len(PLATFORMS) > 1
                 else f"{PLATFORMS[0].removesuffix('s')} acoustics only")
STRATA_SHP = DATA_DIR / "gis" / "final_five_strata_new.shp"
OUTPUT_DIR = ROOT / "output" / "python"
AREA_CRS = 3175  # NAD83 / Great Lakes Albers (equal area)


def trawl_file(table: str, year: int = YEAR) -> Path:
    return VOR_DIR / f"trawl_{year}_{table}.csv"


# Trawl years pooled for the between-tow spread (upper) and the deep proportion (user, 2026-10-26): every year with
# an optrop file in the inputs (2004-2024)
TRAWL_YEARS = sorted(int(f.name[6:10]) for f in VOR_DIR.glob("trawl_[0-9][0-9][0-9][0-9]_optrop.csv"))


def out_name(stem: str, ext: str = "csv") -> str:
    return f"{stem}_{RUN_TAG}.{ext}"


# GDAL data for pyogrio inside the conda environment (silences a harmless warning)
os.environ.setdefault("GDAL_DATA", str(Path(sys.prefix) / "Library" / "share" / "gdal"))
