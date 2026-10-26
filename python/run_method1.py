"""Run the Python version of method 1; write its tables to output/python/ (same names and columns as R step 03)."""
import pandas as pd

from cvacmt.estimate import acoustic_units, method1
from cvacmt.paths import OUTPUT_DIR, out_name

pd.set_option("display.width", 200)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
r = method1(acoustic_units())
for key, name in [("stratum", "method1_stratum"), ("lake", "method1_lake"),
                  ("trawl", "method1_trawl"), ("rho", "method1_acoustic")]:
    r[key].to_csv(OUTPUT_DIR / out_name(name), index=False)
print("Lake-wide mean density (fish/ha):")
print(r["lake"].round(4).to_string(index=False))
