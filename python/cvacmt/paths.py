"""Data locations (inside the project; read only). Mirrors R/paths.R."""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "data"
ACOUSTIC_SHIPS = DATA_DIR / "acoustic" / "L2 Y2021 estimates ships intlaymeans_nph 2026-07-23.csv"
ACOUSTIC_SAILDRONE = DATA_DIR / "acoustic" / "L2 Y2021 estimates sd intlaymeans_nph 2025-03-07.csv"
TRAWL_DIR = DATA_DIR / "trawl"
STRATA_SHP = DATA_DIR / "gis" / "final_five_strata_new.shp"
OUTPUT_DIR = ROOT / "output" / "python"
AREA_CRS = 3175  # NAD83 / Great Lakes Albers (equal area)

# GDAL data for pyogrio inside the conda environment (silences a harmless warning)
os.environ.setdefault("GDAL_DATA", str(Path(sys.prefix) / "Library" / "share" / "gdal"))
