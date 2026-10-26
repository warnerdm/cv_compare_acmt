"""Data locations (inside the project; read only). Mirrors R/paths.R."""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "data"
# Survey year: env var YEAR (default 2021). 2024 (user, 2026-10-26): ship transects only, run as 2021 (option 1).
YEAR = int(os.environ.get("YEAR", "2021"))
# EchoNet2Fish interval x layer files per year and platform
ACOUSTIC_FILES = {
    2021: {"ships": "L2 Y2021 estimates ships intlaymeans_nph 2026-07-23.csv",
           "saildrone": "L2 Y2021 estimates sd intlaymeans_nph 2025-03-07.csv"},
    2022: {"ships": "L2 Y2022 ACMT Estimates 60db2023-02-23 intlaymeans_nph 2023-02-23.csv"},
    2023: {"ships": "L2 Y2023 ACMT Estimates with alewife age2024-03-08 intlaymeans_nph 2024-03-08.csv"},
    2024: {"ships": "L2 Y2024 ACMT Estimates2025-01-17 intlaymeans_nph 2025-01-17.csv"},
}
ACOUSTIC = {k: DATA_DIR / "acoustic" / v for k, v in ACOUSTIC_FILES[YEAR].items()}
PLATFORMS = list(ACOUSTIC)
ACOUSTIC_DESC = ("ship + saildrone acoustics pooled" if len(PLATFORMS) > 1
                 else f"{PLATFORMS[0].removesuffix('s')} acoustics only")
TRAWL_DIR = DATA_DIR / "trawl"
STRATA_SHP = DATA_DIR / "gis" / "final_five_strata_new.shp"
OUTPUT_DIR = ROOT / "output" / "python"
AREA_CRS = 3175  # NAD83 / Great Lakes Albers (equal area)


def trawl_file(table: str) -> Path:
    return TRAWL_DIR / f"L_2_Y_{YEAR}_Acoustic_{table}.csv"


def out_name(stem: str, ext: str = "csv") -> str:
    return f"{stem}_{YEAR}.{ext}"


# GDAL data for pyogrio inside the conda environment (silences a harmless warning)
os.environ.setdefault("GDAL_DATA", str(Path(sys.prefix) / "Library" / "share" / "gdal"))
