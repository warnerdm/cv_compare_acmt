# Which way of assigning trawl composition to acoustic cells predicts an unseen tow best?
# (user, 2026-11-16; design: STATUS.md). Tows of the Lake Michigan EchoNet2Fish version of record (v1.3.1, 2004-2024),
# composition by number among six size groups, predicted for each tow without that tow by:
#   nearest  - the nearest other tow in the same year and slice
#   slice    - the mean of the other tows in the same year and slice (every tow equal)
#   gam      - binomial GAMs per group over all years (fishing depth, bottom depth, location, year), renormalized
#   tree     - a classification tree per year on the tow's fish (Yule et al. 2013, CJFAS 70:1845)
# Score: total absolute difference between predicted and observed proportions (0-2; half = share of fish misassigned).

GROUPS <- c("ale_small", "ale_large", "smelt_small", "smelt_large", "bloat_small", "bloat_large")
CUTS <- c("106" = 100, "109" = 90, "204" = 120)   # EchoNet2Fish lcut (mm): small < cut <= large
DEEP_M <- 40                                      # slices: < 40 m fishing depth per region, >= 40 m all regions
MIN_FISH <- 5                                     # tows with at least 5 fish of the six groups (trawlcomp rule)

# One row per tow: covariates, slice and the six group counts, as EchoNet2Fish counts them (length frequencies scaled
# to the catch; alewife and smelt in tows fishing >= 40 m set to 0, as rmBycatch).
tow_table <- function(year, dir = "inputs/version_of_record") {
  e <- new.env(); load(file.path(dir, sprintf("ACMT_%d.RData", year)), envir = e)
  st <- function(d, w) EchoNet2Fish:::standardizeTrawl(d, w)
  op <- st(e$optrop, "optrop"); ca <- st(e$trcatch, "trcatch"); lf <- st(e$trlf, "trlf")
  ca <- ca[ca$SPECIES %in% names(CUTS), ]; lf <- lf[lf$SPECIES %in% names(CUTS) & !is.na(lf$LENGTH), ]
  nc <- aggregate(N ~ OP_ID + SPECIES, ca, sum)
  nm <- aggregate(N ~ OP_ID + SPECIES, lf, sum)
  sc <- merge(nc, nm, by = c("OP_ID", "SPECIES"), suffixes = c(".caught", ".measured"))
  lf <- merge(lf, sc, by = c("OP_ID", "SPECIES"))
  lf$n <- lf$N * lf$N.caught / lf$N.measured
  lf$group <- paste0(c("106" = "ale", "109" = "smelt", "204" = "bloat")[as.character(lf$SPECIES)],
                     ifelse(lf$LENGTH < CUTS[as.character(lf$SPECIES)], "_small", "_large"))
  g <- tapply(lf$n, list(lf$OP_ID, factor(lf$group, GROUPS)), sum); g[is.na(g)] <- 0
  t <- data.frame(OP_ID = as.numeric(rownames(g)), g, check.names = FALSE)
  o <- op[!duplicated(op$OP_ID), c("OP_ID", "TRANSECT", "FISHING_DEPTH", "BEG_DEPTH", "END_DEPTH", "Latitude", "Longitude")]
  t <- merge(o, t, by = "OP_ID")
  deep <- t$FISHING_DEPTH >= DEEP_M
  t[deep, c("ale_small", "ale_large", "smelt_small", "smelt_large")] <- 0
  regs <- if (year >= 2023) c("nne", "nnw", "no", "sn", "so", "wn") else c("nn", "no", "sn", "so", "wn")
  t$region <- EchoNet2Fish:::regionOf(t$TRANSECT, regs)
  t$slice <- ifelse(deep, "deep", paste0(t$region, ".upper"))
  t$bottom <- rowMeans(t[c("BEG_DEPTH", "END_DEPTH")], na.rm = TRUE)   # 2018: 11 tows lack END_DEPTH -> BEG_DEPTH
  t$total <- rowSums(t[GROUPS]); t$year <- year
  t[t$total >= MIN_FISH & !is.na(t$FISHING_DEPTH) & !is.na(t$Latitude) & !is.na(t$region), ]
}

props <- function(t) as.matrix(t[GROUPS]) / t$total

utm_km <- function(t) { z <- EchoNet2Fish::latlon2utm(t$Longitude, t$Latitude); cbind(z[, 1], z[, 2]) / 1000 }

# nearest other tow in the same year and slice; slice mean of the others. A tow alone in its slice falls back to the
# year's tows in the same layer (upper / deep), as EchoNet2Fish's same-layer borrowing; alone there: NA.
pred_nearest_slice <- function(t) {
  p <- props(t); xy <- utm_km(t); n <- nrow(t)
  layer <- ifelse(t$slice == "deep", "deep", "upper")
  near <- slice <- matrix(NA_real_, n, length(GROUPS), dimnames = list(NULL, GROUPS)); src <- rep(NA_character_, n)
  for (i in seq_len(n)) {
    pool <- which(t$year == t$year[i] & t$slice == t$slice[i] & seq_len(n) != i); s <- "own slice"
    if (!length(pool)) { pool <- which(t$year == t$year[i] & layer == layer[i] & seq_len(n) != i); s <- "same layer" }
    if (!length(pool)) next
    d <- sqrt(colSums((t(xy[pool, , drop = FALSE]) - xy[i, ])^2))
    near[i, ] <- p[pool[which.min(d)], ]; slice[i, ] <- colMeans(p[pool, , drop = FALSE]); src[i] <- s
  }
  list(nearest = near, slice = slice, source = src)
}

# binomial GAMs per group (all years; year as random effect), K-fold by tow, renormalized to sum 1
pred_gam <- function(t, k = 10, seed = 1) {
  set.seed(seed); fold <- sample(rep(seq_len(k), length.out = nrow(t)))
  t$fyear <- factor(t$year)
  out <- matrix(NA_real_, nrow(t), length(GROUPS), dimnames = list(NULL, GROUPS))
  for (f in seq_len(k)) {
    tr <- t[fold != f, ]; te <- t[fold == f, ]
    pr <- sapply(GROUPS, function(g) {
      tr$y <- tr[[g]]; tr$nn <- tr$total - tr[[g]]
      if (sum(tr$y) == 0) return(rep(0, nrow(te)))
      m <- mgcv::gam(cbind(round(y), round(nn)) ~ s(FISHING_DEPTH, k = 6) + s(bottom, k = 6) +
                       s(Longitude, Latitude, k = 20) + s(fyear, bs = "re"), family = binomial, data = tr, method = "REML")
      as.numeric(predict(m, te, type = "response"))
    })
    pr <- matrix(pr, nrow(te)); pr <- pr / pmax(rowSums(pr), 1e-12)
    out[fold == f, ] <- pr
  }
  out
}

# classification tree per year on fish (weights = counts), leave one tow out (Yule et al.: splits explaining >= 5% of
# the variation, nodes of >= 5 fish)
pred_tree <- function(t) {
  out <- matrix(NA_real_, nrow(t), length(GROUPS), dimnames = list(NULL, GROUPS))
  for (y in unique(t$year)) {
    iy <- which(t$year == y)
    long <- do.call(rbind, lapply(iy, function(i) data.frame(row = i, group = factor(GROUPS, GROUPS), w = unlist(t[i, GROUPS]),
      FISHING_DEPTH = t$FISHING_DEPTH[i], bottom = t$bottom[i], Latitude = t$Latitude[i], Longitude = t$Longitude[i])))
    long <- long[long$w > 0, ]
    for (i in iy) {
      tr <- long[long$row != i, ]; tr$group <- droplevels(tr$group)   # rpart's predict fails on empty classes
      m <- rpart::rpart(group ~ FISHING_DEPTH + bottom + Latitude + Longitude, data = tr, weights = w, method = "class",
                        control = rpart::rpart.control(cp = 0.05, minbucket = 5, xval = 0))
      pr <- predict(m, t[i, c("FISHING_DEPTH", "bottom", "Latitude", "Longitude")], type = "prob")
      out[i, ] <- 0; out[i, colnames(pr)] <- pr[1, ]
    }
  }
  out
}

tad <- function(pred, obs) rowSums(abs(pred - obs))
