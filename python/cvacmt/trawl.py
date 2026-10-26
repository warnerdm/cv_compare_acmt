"""Trawl catch and proportions (user, 2026-10-24: rules as trawlcomp). Mirrors R/trawl.R.
Groups alewife (106), smelt (109), bloater (204) by number, summed over life stages (absent = 0); alewife in tows
fishing deeper than 40 m set to 0 (contamination); tows need >= 5 fish; layers split at 40 m."""
import numpy as np
import pandas as pd

from .paths import trawl_file
from .data import read_tows

GROUPS = {106: "alewife", 109: "smelt", 204: "bloater"}
ALEWIFE_CONTAMINATION_DEPTH_M = 40
MIN_FISH = 5
LAYER_SPLIT_M = 40
LAYERS = ["< 40 m", ">= 40 m"]


def layer_of(depth) -> np.ndarray:
    return np.where(np.asarray(depth, dtype=float) < LAYER_SPLIT_M, LAYERS[0], LAYERS[1])


def read_catch() -> pd.DataFrame:
    return pd.read_csv(trawl_file("tr_catch"))[["OP_ID", "SPECIES", "N"]]


def tow_catch(tows: pd.DataFrame | None = None) -> pd.DataFrame:
    """One row per tow: counts per group, n, fishing depth, layer, stratum (all tows)."""
    tows = read_tows() if tows is None else tows
    c = read_catch()
    c = c[c["SPECIES"].isin(GROUPS.keys())].assign(group=lambda x: x["SPECIES"].map(GROUPS))
    counts = c.pivot_table(index="OP_ID", columns="group", values="N", aggfunc="sum", fill_value=0).reset_index()
    for g in GROUPS.values():
        if g not in counts.columns:
            counts[g] = 0.0
    t = (tows[["OP_ID", "YEAR", "VESSEL", "TRANSECT", "FISHING_DEPTH", "stratum"]]
         .rename(columns={"FISHING_DEPTH": "fishing_depth"})
         .merge(counts, on="OP_ID", how="left"))
    for g in GROUPS.values():
        t[g] = t[g].fillna(0.0).astype(float)
    t["alewife_removed"] = np.where(t["fishing_depth"] > ALEWIFE_CONTAMINATION_DEPTH_M, t["alewife"], 0.0)
    t["alewife"] = t["alewife"] - t["alewife_removed"]
    t["n"] = t["alewife"] + t["smelt"] + t["bloater"]
    t["layer"] = layer_of(t["fishing_depth"])
    return t


def tow_props(tc: pd.DataFrame | None = None) -> pd.DataFrame:
    """Tows used for proportions (>= MIN_FISH fish), with p_<group>."""
    tc = tow_catch() if tc is None else tc
    tp = tc[tc["n"] >= MIN_FISH].copy()
    for g in GROUPS.values():
        tp["p_" + g] = tp[g] / tp["n"]
    return tp
