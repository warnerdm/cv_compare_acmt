# Assign ship transects, saildrone drone-nights and tows to the five strata; tabulate; stratum areas.
source("D:/pyprojects/cv_compare_acmt/R/data.R")
dir.create(OUTPUT_DIR, showWarnings = FALSE)
options(width = 200)

areas <- stratum_areas(); print(areas)
for (pf in PLATFORMS) {
  d <- read_acoustic(pf)
  u <- d %>% distinct(Region_name, Interval, interval_stratum, stratum)
  m <- unit_majority(u)
  cat("\n==", pf, ":", n_distinct(d$Region_name), "units,", nrow(u), "intervals;", sum(m$n_strata > 1), "units cross a boundary\n")
  print(table(unit = m$stratum))
  print(as.data.frame(filter(m, n_strata > 1)))
  write_csv(m, out_file(paste0("units_", pf)))
}
t <- read_tows(); cat("\nTows:", nrow(t), "\n"); print(table(t$stratum, useNA = "ifany"))
write_csv(select(t, OP_ID, VESSEL, TRANSECT, BEG_LATITUDE_DD, BEG_LONGITUDE_DD, FISHING_DEPTH, stratum), out_file("tows_strata"))
