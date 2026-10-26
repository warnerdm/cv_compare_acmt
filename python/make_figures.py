"""Figures of method 1 (Python versions of R steps 04-06), written to output/python/.

    python make_figures.py                      # worked examples sn bloater, nn alewife, so bloater + shares + density
    python make_figures.py --worked sn:bloater  # choose the worked examples (stratum:group, repeatable)
"""
import argparse

from cvacmt.estimate import acoustic_units, method1
from cvacmt.figures import worked_example, shares_by_stratum, lake_density, lake_shares_years
from cvacmt.paths import OUTPUT_DIR, out_name

ap = argparse.ArgumentParser()
ap.add_argument("--worked", action="append", help="stratum:group, e.g. sn:bloater")
args = ap.parse_args()
worked = args.worked or ["sn:bloater", "nn:alewife", "so:bloater"]

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
r = method1(acoustic_units())
for w in worked:
    s, g = w.split(":")
    v = worked_example(s, g, OUTPUT_DIR / out_name(f"worked_{s}_{g}", "png"))
    print(f"{s} {g}: D {v['D']:.1f}, var_ac {v['var_ac']:.0f}, var_tr {v['var_tr']:.0f}, var_x {v['var_x']:.0f}, "
          f"SE {v['se']:.1f}, CV {v['cv']:.3f}")
shares_by_stratum(r["stratum"], r["lake"], OUTPUT_DIR / out_name("shares_by_stratum", "png"))
lake_density(r["lake"], OUTPUT_DIR / out_name("lake_density", "png"))
lake_shares_years(OUTPUT_DIR / "lake_shares_years.png")  # all years with output/python/method1_lake_<year>.csv
print(f"Figures written to {OUTPUT_DIR}")
