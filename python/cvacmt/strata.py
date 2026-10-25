"""Strata (user, 2026-10-24): the five original Lake Michigan strata nn, no, sn, so, wn from the shapefile.
Points placed by point-in-polygon; an acoustic sampling unit (ship transect or saildrone drone-night) goes whole to
the stratum holding the majority of its intervals. Stratum areas = polygon areas (Great Lakes Albers).
Mirrors R/strata.R."""
import numpy as np
import pandas as pd
import geopandas as gpd
from shapely.validation import make_valid

from .paths import STRATA_SHP, AREA_CRS


def read_strata() -> gpd.GeoDataFrame:
    g = gpd.read_file(STRATA_SHP)
    g["geometry"] = g.geometry.apply(make_valid)
    return g


def stratum_areas(g: gpd.GeoDataFrame | None = None) -> pd.DataFrame:
    g = read_strata() if g is None else g
    return pd.DataFrame({"stratum": g["stratum"].values, "area_ha": g.to_crs(AREA_CRS).area.values / 1e4})


def point_stratum(lon, lat, g: gpd.GeoDataFrame | None = None) -> np.ndarray:
    """Stratum of each point (decimal degrees); None outside every polygon. First polygon in file order on ties."""
    g = read_strata() if g is None else g
    lon = np.asarray(lon, dtype=float)
    lat = np.asarray(lat, dtype=float)
    out = np.full(len(lon), None, dtype=object)
    ok = ~(np.isnan(lon) | np.isnan(lat))
    pts = gpd.GeoDataFrame({"i": np.flatnonzero(ok)}, geometry=gpd.points_from_xy(lon[ok], lat[ok]), crs=4326)
    polys = g[["stratum", "geometry"]].reset_index(names="poly")
    hit = gpd.sjoin(pts, polys, predicate="intersects", how="inner")
    hit = hit.sort_values(["i", "poly"]).drop_duplicates("i")
    out[hit["i"].to_numpy()] = hit["stratum"].to_numpy()
    return out


def unit_majority(intervals: pd.DataFrame) -> pd.DataFrame:
    """Majority stratum per Region_name from columns Region_name, interval_stratum (ties: alphabetical first)."""
    c = (intervals.dropna(subset=["interval_stratum"])
         .groupby(["Region_name", "interval_stratum"]).size().rename("n").reset_index()
         .sort_values(["Region_name", "interval_stratum"], ignore_index=True))
    c["share"] = c["n"] / c.groupby("Region_name")["n"].transform("sum")
    c["n_strata"] = c.groupby("Region_name")["interval_stratum"].transform("size")
    best = c.loc[c.groupby("Region_name")["n"].idxmax()]
    return best.rename(columns={"interval_stratum": "stratum"})[["Region_name", "stratum", "share", "n_strata"]].reset_index(drop=True)
