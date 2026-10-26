"""Readers for the project's data (Lake Michigan, year YEAR from paths.py). Mirrors R/data.R."""
import numpy as np
import pandas as pd

from .paths import ACOUSTIC, PLATFORMS, trawl_file
from .strata import read_strata, point_stratum, unit_majority

EXCLUDED_TOWS = [119411]  # TARGET 209, transect "exp", experimental (user, 2026-10-24)


def read_acoustic(platform: str = PLATFORMS[0]) -> pd.DataFrame:
    """EchoNet2Fish interval x layer output (1 m layers in 2021, 10 m in 2024) with interval_stratum (polygon) and
    stratum (unit majority). fish_ha Inf (sigma = 0: no single targets) or NA = 0, as EchoNet2Fish (user, 2026-10-26)."""
    d = pd.read_csv(ACOUSTIC[platform])
    d["platform"] = platform
    d["fish_ha"] = d["fish_ha"].where(np.isfinite(d["fish_ha"]), 0.0)
    g = read_strata()
    iv = d[["Region_name", "Interval", "Lat_M", "Lon_M"]].drop_duplicates(["Region_name", "Interval"]).copy()
    iv["interval_stratum"] = point_stratum(iv["Lon_M"], iv["Lat_M"], g)
    d = d.merge(iv[["Region_name", "Interval", "interval_stratum"]], on=["Region_name", "Interval"], how="left")
    return d.merge(unit_majority(iv)[["Region_name", "stratum"]], on="Region_name", how="left")


def read_tows() -> pd.DataFrame:
    """The year's midwater tows with their polygon stratum (119411 excluded)."""
    t = pd.read_csv(trawl_file("optrop"))
    t = t[~t["OP_ID"].isin(EXCLUDED_TOWS)].copy()
    t["stratum"] = point_stratum(t["BEG_LONGITUDE_DD"], t["BEG_LATITUDE_DD"])
    return t
