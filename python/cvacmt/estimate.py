"""Method 1 (analytic) species density and its uncertainty, Lake Michigan, year YEAR. Mirrors R/estimate.R.

- Acoustics: ship + saildrone POOLED; unit = transect or drone-night (majority stratum). Per interval, rho_layer =
  sum of fish_ha over its 1 m layers in the layer (by mid-depth); unit value = mean over intervals; stratum rho =
  mean over units.
- Trawl (user, 2026-10-26: pool the spread across years and the deep p): above 40 m, p = the stratum's mean of the
  year's tows; SE = the stratum's pooled within-year SD (all TRAWL_YEARS) / sqrt(the year's tows). 40 m and deeper:
  one lake-wide proportion from all TRAWL_YEARS' deep tows; SE = their SD / sqrt(their number).
- D = rho_upper p_upper + rho_lower p_deep; Var = acoustic + trawl + product (Goodman 1960).
- Lake-wide mean density = sum(A D) / sum(A); the shared deep proportion's trawl variance enters fully correlated.
"""
import numpy as np
import pandas as pd

from .data import read_acoustic
from .paths import PLATFORMS
from .strata import stratum_areas
from .trawl import tow_props, tow_props_all, layer_of, GROUPS, LAYERS

STRATA = ["nn", "no", "sn", "so", "wn"]


def _var_mean(x: pd.Series) -> float:
    """Variance of the mean: var(x, ddof=1) / n."""
    return x.var(ddof=1) / len(x)


def acoustic_units() -> pd.DataFrame:
    """Acoustic value per unit x layer (fish/ha), pooled platforms."""
    d = pd.concat([read_acoustic(p) for p in PLATFORMS], ignore_index=True)
    d["layer"] = layer_of((d["Layer_depth_min"] + d["Layer_depth_max"]) / 2)
    keys = ["platform", "Region_name", "stratum", "Interval"]
    s = (d.groupby(keys + ["layer"], dropna=False)["fish_ha"].sum()
           .unstack("layer").reindex(columns=LAYERS).fillna(0.0)
           .stack().rename("fish_ha").reset_index())
    return (s.groupby(["platform", "Region_name", "stratum", "layer"], dropna=False)
             .agg(intervals=("fish_ha", "size"), fish_ha=("fish_ha", "mean")).reset_index())


def _long(tp: pd.DataFrame) -> pd.DataFrame:
    ids = [c for c in ["OP_ID", "year", "stratum", "layer"] if c in tp.columns]
    long = tp.melt(id_vars=ids, value_vars=["p_" + g for g in GROUPS.values()], var_name="group", value_name="p")
    long["group"] = long["group"].str.removeprefix("p_")
    return long


def _sd_or_nan(x: pd.Series) -> float:
    return x.std(ddof=1) if len(x) > 1 else np.nan


def trawl_cells(tp: pd.DataFrame | None = None, tp_all: pd.DataFrame | None = None) -> pd.DataFrame:
    """Trawl proportions: upper by stratum, deep lake-wide; one row per stratum x layer x group.
    tp = the year's tows; tp_all = all pooled years' tows (with `year`). sd = the SD used; sd_own = the year's own SD;
    df = degrees of freedom of sd; years = years contributing."""
    tp = tow_props() if tp is None else tp
    tp_all = tow_props_all() if tp_all is None else tp_all
    long, la = _long(tp), _long(tp_all)
    up = long[long["layer"] == LAYERS[0]]
    # pooled within-year SD per stratum x group: deviations from each year's own stratum mean
    ua = la[la["layer"] == LAYERS[0]].copy()
    ua["d2"] = (ua["p"] - ua.groupby(["year", "stratum", "group"])["p"].transform("mean")) ** 2
    cy = ua.groupby(["year", "stratum", "group"]).agg(ss=("d2", "sum"), n=("p", "size")).reset_index()
    cy["df"] = cy["n"] - 1
    sd_pool = cy.groupby(["stratum", "group"]).agg(ss=("ss", "sum"), df=("df", "sum"), years=("year", "size")).reset_index()
    sd_pool["sd"] = np.sqrt(sd_pool["ss"] / sd_pool["df"])
    upper = (up.groupby(["stratum", "group"]).agg(tows=("p", "size"), sd_own=("p", _sd_or_nan), p=("p", "mean"))
               .reset_index().merge(sd_pool[["stratum", "group", "sd", "df", "years"]], on=["stratum", "group"], how="left"))
    if upper["sd"].isna().any():
        raise ValueError(f"no pooled upper-layer SD for: {sorted(upper.loc[upper['sd'].isna(), 'stratum'].unique())}")
    upper["layer"] = LAYERS[0]
    upper["source"] = "stratum"
    upper["se_p"] = upper["sd"] / np.sqrt(upper["tows"])
    own = long[long["layer"] == LAYERS[1]].groupby("group")["p"].agg(_sd_or_nan).rename("sd_own").reset_index()
    da = la[la["layer"] == LAYERS[1]]
    dp = (da.groupby("group").agg(tows=("p", "size"), sd=("p", lambda x: x.std(ddof=1)), p=("p", "mean"),
                                  years=("year", "nunique")).reset_index().merge(own, on="group", how="left"))
    dp["df"] = dp["tows"] - 1
    dp["se_p"] = dp["sd"] / np.sqrt(dp["tows"])
    dp["layer"] = LAYERS[1]
    dp["source"] = "lake-wide deep, all years"
    deep = pd.concat([dp.assign(stratum=s) for s in STRATA], ignore_index=True)
    cols = ["stratum", "layer", "group", "source", "tows", "p", "sd", "sd_own", "se_p", "df", "years"]
    return pd.concat([upper, deep], ignore_index=True).reindex(columns=cols)


def method1(au: pd.DataFrame | None = None, tr: pd.DataFrame | None = None, areas: pd.DataFrame | None = None) -> dict:
    au = acoustic_units() if au is None else au
    tr = trawl_cells() if tr is None else tr
    areas = stratum_areas() if areas is None else areas
    # acoustic: each unit's species density with p fixed
    du = au.merge(tr[["stratum", "layer", "group", "p"]], on=["stratum", "layer"])
    du["x"] = du["fish_ha"] * du["p"]
    du = du.groupby(["stratum", "group", "Region_name"])["x"].sum().rename("d_u").reset_index()
    ac = du.groupby(["stratum", "group"]).agg(units=("d_u", "size"), D=("d_u", "mean"), var_ac=("d_u", _var_mean)).reset_index()
    rho = au.groupby(["stratum", "layer"]).agg(units=("fish_ha", "size"), rho=("fish_ha", "mean"),
                                               var_rho=("fish_ha", _var_mean)).reset_index()
    tv = rho.merge(tr, on=["stratum", "layer"])
    tv["vt"] = tv["rho"] ** 2 * tv["se_p"] ** 2
    tv["vx"] = tv["var_rho"] * tv["se_p"] ** 2
    tv = tv.groupby(["stratum", "group"]).agg(var_tr=("vt", "sum"), var_x=("vx", "sum")).reset_index()
    st = ac.merge(tv, on=["stratum", "group"])
    v = st["var_ac"] + st["var_tr"] + st["var_x"]
    st["se_D"] = np.sqrt(v)
    st["cv_D"] = st["se_D"] / st["D"]
    st["share_acoustic"] = st["var_ac"] / v
    st["share_trawl"] = st["var_tr"] / v
    st["share_product"] = st["var_x"] / v
    st = st.merge(areas, on="stratum")
    # lake-wide: upper trawl terms independent between strata; deep trawl term fully correlated
    A = areas["area_ha"].sum()
    up = (rho[rho["layer"] == LAYERS[0]].merge(tr[tr["layer"] == LAYERS[0]], on=["stratum", "layer"])
             .merge(areas, on="stratum"))
    v_up = (up["area_ha"] ** 2 * up["rho"] ** 2 * up["se_p"] ** 2).groupby(up["group"]).sum()
    lo = rho[rho["layer"] == LAYERS[1]].merge(areas, on="stratum")
    s_lo = (lo["area_ha"] * lo["rho"]).sum()
    se_deep = tr[tr["layer"] == LAYERS[1]].drop_duplicates("group").set_index("group")["se_p"]
    v_dp = s_lo ** 2 * se_deep ** 2
    lake = (st.assign(N=st["area_ha"] * st["D"], v_ac=st["area_ha"] ** 2 * st["var_ac"], v_x=st["area_ha"] ** 2 * st["var_x"])
              .groupby("group")[["N", "v_ac", "v_x"]].sum())
    lake["v_tr"] = v_up + v_dp
    lake["v"] = lake["v_ac"] + lake["v_tr"] + lake["v_x"]
    lake["density"] = lake["N"] / A
    lake["se_density"] = np.sqrt(lake["v"]) / A
    lake["cv"] = np.sqrt(lake["v"]) / lake["N"]
    lake["share_acoustic"] = lake["v_ac"] / lake["v"]
    lake["share_trawl"] = lake["v_tr"] / lake["v"]
    lake["share_product"] = lake["v_x"] / lake["v"]
    lake = lake.reset_index()[["group", "density", "se_density", "cv", "share_acoustic", "share_trawl", "share_product", "N"]]
    return {"rho": rho, "trawl": tr, "stratum": st, "lake": lake}
