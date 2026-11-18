"""Readers for the project's data (Lake Michigan, year YEAR from paths.py). Mirrors R/data.R."""
import numpy as np
import pandas as pd

from .paths import ACOUSTIC, PLATFORMS, YEAR, trawl_file
from .strata import read_strata, point_stratum, unit_majority

EXCLUDED_TOWS = [119411]  # TARGET 209, transect "exp", experimental (user, 2026-10-24)

# Intervals left out (user, 2026-11-14; D:/projects/lm_echonet2fish_rerun/TIDYING.md, row 2005): in 2005 transects nn1
# and sn6tonn1 share a leg (the same pings). Split at the nn/sn stratum boundary, as in the release EV files: keep
# sn6tonn1 intervals 1-9 and nn1 intervals 10-27; drop nn1 intervals 1-9 and sn6tonn1 intervals 10-16.
EXCLUDED_INTERVALS = [(2005, "nn1", 1, 9), (2005, "sn6tonn1", 10, 16)]  # (year, Region_name, first, last)


def drop_excluded_intervals(d: pd.DataFrame, year: int = YEAR) -> pd.DataFrame:
    for y, unit, first, last in EXCLUDED_INTERVALS:
        if y == year:
            d = d[~((d["Region_name"] == unit) & d["Interval"].between(first, last))]
    return d


def read_acoustic(platform: str = PLATFORMS[0]) -> pd.DataFrame:
    """EchoNet2Fish interval x layer output (1 m layers in 2021, 10 m in 2024) with interval_stratum (polygon) and
    stratum (unit majority). fish_ha Inf (sigma = 0: no single targets) or NA = 0, as EchoNet2Fish (user, 2026-10-26)."""
    d = pd.read_csv(ACOUSTIC[platform])
    d["platform"] = platform
    d["fish_ha"] = d["fish_ha"].where(np.isfinite(d["fish_ha"]), 0.0)
    d = drop_excluded_intervals(d).copy()
    g = read_strata()
    iv = d[["Region_name", "Interval", "Lat_M", "Lon_M"]].drop_duplicates(["Region_name", "Interval"]).copy()
    iv["interval_stratum"] = point_stratum(iv["Lon_M"], iv["Lat_M"], g)
    d = d.merge(iv[["Region_name", "Interval", "interval_stratum"]], on=["Region_name", "Interval"], how="left")
    return d.merge(unit_majority(iv)[["Region_name", "stratum"]], on="Region_name", how="left")


def read_tows(year: int = YEAR) -> pd.DataFrame:
    """One year's midwater tows with their polygon stratum (119411 excluded)."""
    t = pd.read_csv(trawl_file("optrop", year))
    t = t[~t["OP_ID"].isin(EXCLUDED_TOWS)].copy()
    t["stratum"] = point_stratum(t["BEG_LONGITUDE_DD"], t["BEG_LATITUDE_DD"])
    return t
