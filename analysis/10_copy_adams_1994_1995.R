# Step 10 (run once): copy the 1994-1995 Lake Michigan tows of Adams et al. (2006, NAJFM 26:612-621) into
# inputs/adams_1994_1995/, with a manifest. Nothing outside the project is read after this step.
# Source: bloaterTS's copy of the USGS release "Great Lakes Research Vessel Operations 1958-2018" (ver. 3.0,
# doi:10.5066/F75M63X0): D:/pyprojects/bloaterTS/data/raw/trawl/{OP,OP_TARGET,TR_OP,TR_CATCH}.csv (user, 2026-11-19).
# Rows kept: LAKE 2, YEAR 1994-1995, SAMPLE_TYPE 1, TARGET 210 ("Fall Acoustic/Midwater Trawl Stdy"; its dates match
# the paper's survey windows, 8 Sep - 11 Oct 1994 and 14 Sep - 18 Oct 1995). All 159 such tows are copied (both
# vessels, both years); the choice of the paper's tows is made in R/adams.R. Files are written with their original
# columns; the manifest gives each source file's SHA-256 and the copy's.
src <- "D:/pyprojects/bloaterTS/data/raw/trawl"
dst <- "D:/pyprojects/cv_compare_acmt/inputs/adams_1994_1995"; dir.create(dst, recursive = TRUE, showWarnings = FALSE)
sha <- function(f) digest::digest(file = f, algo = "sha256")
rd <- function(f) read.csv(file.path(src, f), colClasses = "character", fileEncoding = "latin1", check.names = FALSE)

target <- rd("OP_TARGET.csv")
op <- rd("OP.csv")
ops <- op$OP_ID[op$LAKE == "2" & op$YEAR %in% c("1994", "1995") & op$SAMPLE_TYPE == "1" &
                op$OP_ID %in% target$OP_ID[target$TARGET == "210"]]
tabs <- list(OP = op, OP_TARGET = target, TR_OP = rd("TR_OP.csv"), TR_CATCH = rd("TR_CATCH.csv"))
man <- do.call(rbind, lapply(names(tabs), function(tb) {
  d <- tabs[[tb]][tabs[[tb]]$OP_ID %in% ops, , drop = FALSE]
  to <- paste0(tb, ".csv"); write.csv(d, file.path(dst, to), row.names = FALSE, na = "")
  data.frame(file = to, rows = nrow(d), source = file.path(src, to), source_sha256 = sha(file.path(src, to)),
             sha256 = sha(file.path(dst, to)))
}))
write.csv(man, file.path(dst, "manifest.csv"), row.names = FALSE)
print(man[c("file", "rows")])
cat(length(ops), "tows\n")
