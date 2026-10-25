"""Run the Python version of method 1; write its tables to output/python/ (same names and columns as R step 03)."""
import pandas as pd

from cvacmt.estimate import acoustic_units, method1
from cvacmt.paths import OUTPUT_DIR

pd.set_option("display.width", 200)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
r = method1(acoustic_units())
for key, name in [("stratum", "method1_stratum_2021.csv"), ("lake", "method1_lake_2021.csv"),
                  ("trawl", "method1_trawl_2021.csv"), ("rho", "method1_acoustic_2021.csv")]:
    r[key].to_csv(OUTPUT_DIR / name, index=False)
print("Lake-wide mean density (fish/ha):")
print(r["lake"].round(4).to_string(index=False))
