# Step 09 (run once): copy the inputs of the Lake Michigan EchoNet2Fish version of record (the RData each year's run
# read: tows, catch, lengths, Sv/TS) into inputs/version_of_record/, with a manifest. Nothing outside the project is
# read after this step. Source: D:/Acoustics/EchoNet2Fish_LM_versions/v1.3.1_2026-11-15/MI<year>/ACMT.RData
# (EchoNet2Fish 1.3.1; its MANIFEST.csv gives the SHA-256 checked here).
src <- "D:/Acoustics/EchoNet2Fish_LM_versions/v1.3.1_2026-11-15"
dst <- "inputs/version_of_record"; dir.create(dst, recursive = TRUE, showWarnings = FALSE)
years <- c(2004:2019, 2021:2024)
vm <- read.csv(file.path(src, "MANIFEST.csv"))
man <- do.call(rbind, lapply(years, function(y) {
  f <- sprintf("MI%d/ACMT.RData", y); to <- file.path(dst, sprintf("ACMT_%d.RData", y))
  stopifnot(file.copy(file.path(src, f), to, overwrite = TRUE, copy.date = TRUE))
  sha <- digest::digest(file = to, algo = "sha256"); stopifnot(sha == vm$sha256[vm$file == f])
  data.frame(year = y, file = basename(to), source = file.path(src, f), sha256 = sha)
}))
write.csv(man, file.path(dst, "manifest.csv"), row.names = FALSE)
cat("copied", nrow(man), "inputs; all match the version's manifest\n")
