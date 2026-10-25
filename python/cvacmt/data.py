"""Readers for the project's data (Lake Michigan 2021). Mirrors R/data.R."""
import pandas as pd

from .paths import ACOUSTIC_SHIPS, ACOUSTIC_SAILDRONE, TRAWL_DIR
from .strata import read_strata, point_stratum, unit_majority

EXCLUDED_TOWS = [119411]  # TARGET 209, transect "exp", experimental (user, 2026-10-24)


def read_acoustic(platform: str) -> pd.DataFrame:
    """EchoNet2Fish interval x 1 m layer output with interval_stratum (polygon) and stratum (unit majority)."""
    f = {"ships": ACOUSTIC_SHIPS, "saildrone": ACOUSTIC_SAILDRONE}[platform]
    d = pd.read_csv(f)
    d["platform"] = platform
    g = read_strata()
    iv = d[["Region_name", "Interval", "Lat_M", "Lon_M"]].drop_duplicates(["Region_name", "Interval"]).copy()
    iv["interval_stratum"] = point_stratum(iv["Lon_M"], iv["Lat_M"], g)
    d = d.merge(iv[["Region_name", "Interval", "interval_stratum"]], on=["Region_name", "Interval"], how="left")
    return d.merge(unit_majority(iv)[["Region_name", "stratum"]], on="Region_name", how="left")


def read_tows() -> pd.DataFrame:
    """2021 midwater tows with their polygon stratum (119411 excluded)."""
    t = pd.read_csv(TRAWL_DIR / "L_2_Y_2021_Acoustic_optrop.csv")
    t = t[~t["OP_ID"].isin(EXCLUDED_TOWS)].copy()
    t["stratum"] = point_stratum(t["BEG_LONGITUDE_DD"], t["BEG_LATITUDE_DD"])
    return t
