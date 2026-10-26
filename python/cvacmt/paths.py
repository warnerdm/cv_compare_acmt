"""Data locations (inside the project; read only). Mirrors R/paths.R."""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "data"
# Survey year: env var YEAR (default 2021). 2011-2019, 2022-2024 (user, 2026-10-26): ship transects only, run as 2021.
YEAR = int(os.environ.get("YEAR", "2021"))
# EchoNet2Fish interval x layer files per year and platform
ACOUSTIC_FILES = {
    2011: {"ships": "L2 Y2011 ACMT Estimates 60db 2023-02-01 intlaymeans_nph 2023-02-01.csv"},
    2012: {"ships": "L2 Y2012 ACMT Estimates 60db 2023-02-03 intlaymeans_nph 2023-02-03.csv"},
    2013: {"ships": "L2 Y2013 ACMT Estimates_2019-05-15 intlaymeans_nph 2019-05-15.csv"},
    2014: {"ships": "L2 Y2014 ACMT Estimates2023-02-07 intlaymeans_nph 2023-02-07.csv"},
    2015: {"ships": "L2 Y2015 ACMT Estimates2020-03-11 intlaymeans_nph 2020-03-11.csv"},
    2016: {"ships": "L2 Y2016 ACMT Estimates2020-03-13 intlaymeans_nph 2020-03-13.csv"},
    2017: {"ships": "L2 Y2017 ACMT Estimates2020-03-15 intlaymeans_nph 2020-03-15.csv"},
    2018: {"ships": "L2 Y2018 ACMT Estimates2020-03-15 intlaymeans_nph 2020-03-15.csv"},
    2019: {"ships": "L2 Y2019 ACMT Estimates2020-07-07 intlaymeans_nph 2020-07-07.csv"},
    2021: {"ships": "L2 Y2021 estimates ships intlaymeans_nph 2026-07-23.csv",
           "saildrone": "L2 Y2021 estimates sd intlaymeans_nph 2025-03-07.csv"},
    2022: {"ships": "L2 Y2022 ACMT Estimates 60db2023-02-23 intlaymeans_nph 2023-02-23.csv"},
    2023: {"ships": "L2 Y2023 ACMT Estimates with alewife age2024-03-08 intlaymeans_nph 2024-03-08.csv"},
    2024: {"ships": "L2 Y2024 ACMT Estimates2025-01-17 intlaymeans_nph 2025-01-17.csv"},
}
ACOUSTIC = {k: DATA_DIR / "acoustic" / v for k, v in ACOUSTIC_FILES[YEAR].items()}
# Optional single platform (env var PLATFORM = ships or saildrone; empty = all pooled, the default). 2026-10-26: user
# asked to compare ship-only and saildrone-only 2021 estimates with the pooled one; outputs tagged _<year>_<platform>.
PLATFORM = os.environ.get("PLATFORM", "")
if PLATFORM:
    ACOUSTIC = {PLATFORM: ACOUSTIC[PLATFORM]}
RUN_TAG = f"{YEAR}_{PLATFORM}" if PLATFORM else str(YEAR)
PLATFORMS = list(ACOUSTIC)
ACOUSTIC_DESC = ("ship + saildrone acoustics pooled" if len(PLATFORMS) > 1
                 else f"{PLATFORMS[0].removesuffix('s')} acoustics only")
TRAWL_DIR = DATA_DIR / "trawl"
STRATA_SHP = DATA_DIR / "gis" / "final_five_strata_new.shp"
OUTPUT_DIR = ROOT / "output" / "python"
AREA_CRS = 3175  # NAD83 / Great Lakes Albers (equal area)


def trawl_file(table: str, year: int = YEAR) -> Path:
    return TRAWL_DIR / f"L_2_Y_{year}_Acoustic_{table}.csv"


# Trawl years pooled for the between-tow spread (upper) and the deep proportion (user, 2026-10-26): every year with
# an optrop file in data/trawl
TRAWL_YEARS = sorted(int(f.name[6:10]) for f in TRAWL_DIR.glob("L_2_Y_[0-9][0-9][0-9][0-9]_Acoustic_optrop.csv"))


def out_name(stem: str, ext: str = "csv") -> str:
    return f"{stem}_{RUN_TAG}.{ext}"


# GDAL data for pyogrio inside the conda environment (silences a harmless warning)
os.environ.setdefault("GDAL_DATA", str(Path(sys.prefix) / "Library" / "share" / "gdal"))
