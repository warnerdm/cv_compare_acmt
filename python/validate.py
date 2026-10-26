"""Check that the Python version reproduces the R results (output/*.csv from R step 03 vs output/python/*.csv)."""
import sys

import pandas as pd

from cvacmt.paths import ROOT, OUTPUT_DIR, YEAR, out_name

R_DIR = ROOT / "output"
CHECKS = [
    ("method1_stratum", ["stratum", "group"], ["units", "D", "var_ac", "var_tr", "var_x", "se_D", "cv_D", "area_ha"]),
    ("method1_lake", ["group"], ["density", "se_density", "cv", "share_acoustic", "share_trawl", "share_product", "N"]),
    ("method1_trawl", ["stratum", "layer", "group"], ["tows", "p", "sd", "se_p"]),
    ("method1_acoustic", ["stratum", "layer"], ["units", "rho", "var_rho"]),
]

worst = 0.0
for name, keys, cols in CHECKS:
    a = pd.read_csv(R_DIR / out_name(name))
    b = pd.read_csv(OUTPUT_DIR / out_name(name))
    m = a.merge(b, on=keys, suffixes=("_R", "_py"), how="outer", indicator=True)
    if not (m["_merge"] == "both").all():
        print(f"{name}: rows differ between R and Python")
        sys.exit(1)
    for c in cols:
        rel = ((m[c + "_R"] - m[c + "_py"]).abs() / m[c + "_R"].abs().clip(lower=1e-12)).max()
        worst = max(worst, rel)
        print(f"{name:28s} {c:16s} max relative difference {rel:.1e}  ({len(m)} rows)")
print(f"\nWorst relative difference: {worst:.1e}")
# Tolerance 1e-6: polygon areas differ by ~2e-8 relative between R (sf) and Python (geopandas) geometry library
# versions (~0.03 ha of 1.3 million); everything else matches to ~1e-15.
sys.exit(0 if worst < 1e-6 else 1)
