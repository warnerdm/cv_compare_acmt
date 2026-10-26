# Run every analysis step in order; logs in output/logs/.
root <- "D:/pyprojects/cv_compare_acmt"
rscript <- file.path(R.home("bin"), "Rscript.exe")
dir.create(file.path(root, "output", "logs"), showWarnings = FALSE, recursive = TRUE)
steps <- c("01_assign_strata", "02_trawl_proportions", "03_method1", "04_worked_example", "05_shares_figure", "06_lake_density_figure",
           "07_lake_shares_years", "08_lake_density_years")
only <- commandArgs(trailingOnly = TRUE)
if (length(only)) steps <- steps[substr(steps, 1, 2) %in% only]
for (s in steps) {
  log <- file.path(root, "output", "logs", paste0(s, ".log"))
  st <- system2(rscript, shQuote(file.path(root, "analysis", paste0(s, ".R"))), stdout = log, stderr = log)
  cat(sprintf("%-28s %s\n", s, if (st == 0) "ok" else paste("FAILED, see", log)))
  if (st != 0) stop("stopped at ", s)
}
