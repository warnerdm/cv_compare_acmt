"""Figures of method 1 (Python versions of R steps 04-06), written to output/python/.

    python make_figures.py                      # worked examples sn bloater, nn alewife, so bloater + shares + density
    python make_figures.py --worked sn:bloater  # choose the worked examples (stratum:group, repeatable)
"""
import argparse

from cvacmt.estimate import acoustic_units, method1
from cvacmt.figures import worked_example, shares_by_stratum, lake_density
from cvacmt.paths import OUTPUT_DIR

ap = argparse.ArgumentParser()
ap.add_argument("--worked", action="append", help="stratum:group, e.g. sn:bloater")
args = ap.parse_args()
worked = args.worked or ["sn:bloater", "nn:alewife", "so:bloater"]

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
r = method1(acoustic_units())
for w in worked:
    s, g = w.split(":")
    v = worked_example(s, g, OUTPUT_DIR / f"worked_{s}_{g}_2021.png")
    print(f"{s} {g}: D {v['D']:.1f}, var_ac {v['var_ac']:.0f}, var_tr {v['var_tr']:.0f}, var_x {v['var_x']:.0f}, "
          f"SE {v['se']:.1f}, CV {v['cv']:.3f}")
shares_by_stratum(r["stratum"], r["lake"], OUTPUT_DIR / "shares_by_stratum_2021.png")
lake_density(r["lake"], OUTPUT_DIR / "lake_density_2021.png")
print(f"Figures written to {OUTPUT_DIR}")
