# Step 09 (run once): copy the inputs of the Lake Michigan EchoNet2Fish version of record into
# inputs/version_of_record/, with a manifest. Nothing outside the project is read after this step. Every year 2004-2024
# of steps 01-08 and 10 reads these (user decision, recorded in STATUS.md 2026-11-18).
# Source: D:/Acoustics/EchoNet2Fish_LM_versions/v1.3.1_2026-11-15/MI<year>/ (EchoNet2Fish 1.3.1; its MANIFEST.csv gives
# the SHA-256 checked here).
#   ACMT_<year>.RData       the input each year's run read (tows, catch, lengths, Sv/TS); copied
#   acoustic_<year>.csv     the run's interval x layer output (intlaymeans_nph); copied
#   trawl_<year>_optrop.csv, trawl_<year>_tr_catch.csv   the RData's optrop and trcatch, written as csv (column names
#     standardized by EchoNet2Fish, as the run read them). 2013's optrop has no BEG_LATITUDE_DD / BEG_LONGITUDE_DD: they
#     are filled from its Latitude / Longitude (all 31 tows fall in the same stratum either way; checked 2026-11-18).
src <- "D:/Acoustics/EchoNet2Fish_LM_versions/v1.3.1_2026-11-15"
dst <- "D:/pyprojects/cv_compare_acmt/inputs/version_of_record"; dir.create(dst, recursive = TRUE, showWarnings = FALSE)
years <- c(2004:2019, 2021:2024)
vm <- read.csv(file.path(src, "MANIFEST.csv"))
sha <- function(f) digest::digest(file = f, algo = "sha256")
copy_checked <- function(y, from, to) {
  stopifnot(file.copy(file.path(src, from), file.path(dst, to), overwrite = TRUE, copy.date = TRUE))
  s <- sha(file.path(dst, to)); stopifnot(s == vm$sha256[vm$file == from])
  data.frame(year = y, file = to, source = file.path(src, from), sha256 = s)
}
man <- do.call(rbind, lapply(years, function(y) {
  r1 <- copy_checked(y, sprintf("MI%d/ACMT.RData", y), sprintf("ACMT_%d.RData", y))
  r2 <- copy_checked(y, sprintf("MI%d/L2 Y%d v1.3.1 intlaymeans_nph 2026-11-15.csv", y, y), sprintf("acoustic_%d.csv", y))
  e <- new.env(); load(file.path(dst, sprintf("ACMT_%d.RData", y)), envir = e)
  op <- EchoNet2Fish:::standardizeTrawl(e$optrop, "optrop")
  if (!"BEG_LATITUDE_DD" %in% names(op)) op$BEG_LATITUDE_DD <- op$Latitude
  if (!"BEG_LONGITUDE_DD" %in% names(op)) op$BEG_LONGITUDE_DD <- op$Longitude
  tabs <- list(optrop = op, tr_catch = EchoNet2Fish:::standardizeTrawl(e$trcatch, "trcatch")[c("OP_ID", "SPECIES", "N")])
  r3 <- do.call(rbind, lapply(names(tabs), function(tb) {
    to <- sprintf("trawl_%d_%s.csv", y, tb); write.csv(tabs[[tb]], file.path(dst, to), row.names = FALSE)
    data.frame(year = y, file = to, source = paste0(r1$source, " (", c(optrop = "optrop", tr_catch = "trcatch")[[tb]], ")"),
               sha256 = sha(file.path(dst, to)))
  }))
  rbind(r1, r2, r3)
}))
write.csv(man, file.path(dst, "manifest.csv"), row.names = FALSE)
cat("copied", sum(grepl("RData$|^acoustic", man$file)), "files (all match the version's manifest); wrote",
    sum(grepl("^trawl", man$file)), "trawl csvs\n")
