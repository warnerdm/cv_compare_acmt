# Step 11 (user, 2026-11-16): how much do the calibration values the archival exports used differ from the values now in
# use (the release's), and what does that do to density? A desk calculation, no data.
# Source: the release's calibration table, calibration_values.csv (F:/acoustics/Michigan; identical copy in
# D:/projects/lm_acoustic_data_release/docs/raw_reorg), read in place. Column original_values_used_by_exports = the
# ECS each archival survey EV file names and its values for the survey channel (or "no ECS": header / file values).
#
# Density ~ sv / mean sigma_bs, so a change that moves Sv and TS equally cancels:
#   dt4:    Sv and TS carry their ECS offsets  -> density dB = dSvOffset - dTsOffset
#           (no ECS values -> offsets 0, i.e. the dt4 header calibration; beam angles and angle offsets from the header)
#   Simrad: Sv carries -2G - 2Sa - psi, TS -2G -> density dB = -2 dSa - dpsi (gain cancels)
#   d = in use - archive; density factor = 10^(dB/10) = (in use) / (archive).
# Flags (do not cancel, not converted to density): |dTS| >= 0.5 dB (targets cross the fixed TS limits: -60 dB floor,
# TSrange, the -45 dB rule), beam angle |d| >= 0.3 deg and angle offset |d| >= 0.2 deg (beam compensation of TS).
# Unknown for dt4 header values: the header's own beam angles and offsets are not in the table (NA).
suppressPackageStartupMessages(library(dplyr))
src <- "D:/projects/lm_acoustic_data_release/docs/raw_reorg/calibration_values.csv"
cv <- read.csv(src, check.names = FALSE)
out <- "output/calibration_desk"; dir.create(out, recursive = TRUE, showWarnings = FALSE)

num <- function(s, key) { m <- regmatches(s, regexpr(paste0(key, " -?[0-9.]+"), s)); if (length(m)) as.numeric(sub(".* ", "", m)) else NA_real_ }
filev <- function(s, key) { if (is.na(s)) return(NA_real_); m <- regmatches(s, regexpr(paste0(key, " -?[0-9.]+"), s)); if (length(m)) as.numeric(sub(".* ", "", m)) else NA_real_ }

rows <- list()
for (i in seq_len(nrow(cv))) {
  r <- cv[i, ]; simrad <- grepl("Simrad", r$echosounder)
  for (e in strsplit(r$original_values_used_by_exports, " | ", fixed = TRUE)[[1]]) {
    ecs <- trimws(sub(" \\[.*", "", e)); n_ev <- as.integer(sub(".*\\[([0-9]+) EV.*", "\\1", e))
    vals <- sub("^[^]]*\\]: ", "", e)
    novals <- grepl("EMPTY FILE|no values for the channel|no ECS", vals)
    if (!simrad) {
      a_sv <- if (novals) 0 else num(vals, "CalibrationOffsetSv"); a_ts <- if (novals) 0 else num(vals, "CalibrationOffsetTs")
      d_sv <- r$sv_offset_db - a_sv; d_ts <- r$ts_offset_db - a_ts; dens <- d_sv - d_ts
      a_bm <- if (novals) NA else num(vals, "MajorAxis3dbBeamAngle"); a_bn <- if (novals) NA else num(vals, "MinorAxis3dbBeamAngle")
      a_om <- if (novals) NA else num(vals, "MajorAxisAngleOffset"); a_on <- if (novals) NA else num(vals, "MinorAxisAngleOffset")
      d_beam <- max(abs(c(r$beam_major_deg - a_bm, r$beam_minor_deg - a_bn)))
      d_off <- max(abs(c(r$offset_major_deg - a_om, r$offset_minor_deg - a_on)))
      a_desc <- if (novals) "none (header)" else sprintf("Sv %.3f TS %.3f", a_sv, a_ts)
      n_desc <- sprintf("Sv %.3f TS %.3f", r$sv_offset_db, r$ts_offset_db)
    } else {
      fs <- r$file_stored_values
      g <- if (novals) NA else num(vals, "TransducerGain"); if (is.na(g)) g <- filev(fs, "gain_db")
      sa <- if (novals) NA else num(vals, "SaCorrectionFactor"); if (is.na(sa)) sa <- filev(fs, "sa_correction_db")
      ps <- filev(fs, "psi_db")   # no archival ECS sets psi
      d_g <- r$gain_db - g; d_sa <- r$sa_correction_db - sa; d_ps <- r$psi_db - ps
      d_sv <- -2 * d_g - 2 * d_sa - d_ps; d_ts <- -2 * d_g; dens <- -2 * d_sa - d_ps
      bm <- c(r$beam_along_deg, r$beam_athw_deg); ab <- c(if (novals) NA else num(vals, "MinorAxis3dbBeamAngle"), if (novals) NA else num(vals, "MajorAxis3dbBeamAngle"))
      if (all(is.na(ab))) ab <- c(filev(fs, "beamwidth_along_deg"), filev(fs, "beamwidth_athw_deg"))
      ao <- c(if (novals) NA else num(vals, "MinorAxisAngleOffset"), if (novals) NA else num(vals, "MajorAxisAngleOffset"))
      if (all(is.na(ao))) ao <- c(filev(fs, "offset_along_deg"), filev(fs, "offset_athw_deg"))
      d_beam <- max(abs(bm - ab)); d_off <- max(abs(c(r$offset_along_deg, r$offset_athw_deg) - ao))
      a_desc <- sprintf("G %.2f Sa %.2f psi %.1f%s", g, sa, ps, if (novals) " (file)" else "")
      n_desc <- sprintf("G %.2f Sa %.2f psi %.1f", r$gain_db, r$sa_correction_db, r$psi_db)
    }
    rows[[length(rows) + 1]] <- data.frame(year = r$year, vessel = r$vessel, system = if (simrad) "Simrad" else "dt4",
      archive_ecs = ecs, ev_files = n_ev, archive_values = a_desc, in_use = n_desc,
      d_sv_db = round(d_sv, 3), d_ts_db = round(d_ts, 3), density_db = round(dens, 3), density_factor = round(10^(dens / 10), 3),
      d_beam_deg = round(d_beam, 2), d_offset_deg = round(d_off, 2),
      flags = paste(c(if (!is.na(d_ts) && abs(d_ts) >= 0.5) "TS", if (!is.na(d_beam) && d_beam >= 0.3) "beam",
                      if (!is.na(d_off) && d_off >= 0.2) "offset", if (novals) "archive: no ECS values" else NULL), collapse = "; "))
  }
}
d <- do.call(rbind, rows)
write.csv(d, file.path(out, "calibration_archive_vs_in_use.csv"), row.names = FALSE)
options(width = 250); print(d[, c("year", "vessel", "ev_files", "archive_values", "in_use", "d_sv_db", "d_ts_db", "density_db", "density_factor", "d_beam_deg", "d_offset_deg", "flags")], row.names = FALSE)
cat("\nsource:", src, " sha256", digest::digest(file = src, algo = "sha256"), "\n")
