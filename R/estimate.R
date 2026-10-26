# Method 1 (analytic) species density and its uncertainty, Lake Michigan, year YEAR (user, 2026-10-24).
# - Acoustics: ship and saildrone POOLED; sampling unit = ship transect or saildrone drone-night, placed in a stratum
#   by majority. Per interval, rho_layer = sum of fish_ha over its 1 m layers in the layer (by mid-depth); unit value
#   = mean over its intervals; stratum rho = mean over units.
# - Trawl (user, 2026-10-26: pool the spread across years and the deep p): above 40 m, p = the stratum's mean of the
#   year's tows; SE(p) = the stratum's pooled within-year SD (all TRAWL_YEARS) / sqrt(the year's tows). 40 m and
#   deeper: one lake-wide proportion from all TRAWL_YEARS' deep tows; SE = their SD / sqrt(their number).
# - D = rho_upper p_upper + rho_lower p_deep. Var = acoustic + trawl + product (Goodman 1960); acoustic part from the
#   units' species densities with p fixed (keeps the covariance between layers).
# - Lake-wide mean density = sum(A_s D_s) / sum(A_s), A = polygon area. The deep proportion is shared by all strata,
#   so its trawl variance enters the lake-wide total as (sum A_s rho_lower,s)^2 SE(p_deep)^2 (fully correlated).
source("D:/pyprojects/cv_compare_acmt/R/trawl.R")

# Acoustic value per unit x layer (fish/ha), pooled platforms
acoustic_units <- function() {
  bind_rows(lapply(PLATFORMS, read_acoustic)) %>%
    mutate(layer = layer_of((Layer_depth_min + Layer_depth_max) / 2)) %>%
    summarise(.by = c(platform, Region_name, stratum, Interval, layer), fish_ha = sum(fish_ha)) %>%
    complete(nesting(platform, Region_name, stratum, Interval), layer, fill = list(fish_ha = 0)) %>%
    summarise(.by = c(platform, Region_name, stratum, layer), intervals = n(), fish_ha = mean(fish_ha))
}

to_long <- function(tp) {
  tp %>% pivot_longer(c(p_alewife, p_smelt, p_bloater), names_to = "group", values_to = "p") %>%
    mutate(group = str_remove(group, "p_"))
}

# Trawl proportions: upper by stratum, deep lake-wide; one row per stratum x layer x group.
# tp = the year's tows; tp_all = all pooled years' tows (with `year`). sd = the SD used; sd_own = the year's own SD;
# df = degrees of freedom of sd; years = years contributing.
trawl_cells <- function(tp = tow_props(), tp_all = tow_props_all(), strata = c("nn", "no", "sn", "so", "wn")) {
  up <- filter(to_long(tp), layer == "< 40 m")
  # pooled within-year SD per stratum x group: deviations from each year's own stratum mean
  sd_pool <- filter(to_long(tp_all), layer == "< 40 m") %>%
    summarise(.by = c(year, stratum, group), ss = sum((p - mean(p))^2), df = n() - 1) %>%
    summarise(.by = c(stratum, group), sd = sqrt(sum(ss) / sum(df)), df = sum(df), years = n())
  upper <- up %>% summarise(.by = c(stratum, group), tows = n(), sd_own = if (n() > 1) sd(p) else NA_real_, p = mean(p)) %>%
    left_join(sd_pool, by = c("stratum", "group")) %>%
    mutate(layer = layer_of(0), source = "stratum", se_p = sd / sqrt(tows))
  if (anyNA(upper$sd)) stop("no pooled upper-layer SD for: ", paste(unique(upper$stratum[is.na(upper$sd)]), collapse = ", "))
  # A stratum without upper-layer tows (>= MIN_FISH fish) in the year borrows the year's tows of its half of the lake
  # (user, 2026-10-26; so in 2013 and 2014). p = mean of the donor tows; Var(p) = sum_k n_k sd_k^2 / N^2 with sd_k the
  # donor strata's pooled SDs (N = donor tows); shown as sd = sqrt(sum_k n_k sd_k^2 / N), se_p = sd / sqrt(N).
  # The shared tows' covariance with the donors enters the lake-wide total (method1).
  miss <- setdiff(strata, upper$stratum)
  if (any(duplicated(HALVES[miss]))) stop("more than one stratum without upper tows in a half in ", YEAR)
  borrowed <- map_dfr(miss, \(m) {
    don <- upper %>% filter(HALVES[stratum] == HALVES[m])
    if (!nrow(don)) stop("no upper-layer tows in the ", HALVES[m], " half in ", YEAR, " for ", m)
    up %>% filter(stratum %in% don$stratum) %>%
      summarise(.by = group, tows = n(), sd_own = sd(p), p = mean(p)) %>%
      left_join(don %>% summarise(.by = group, nsd2 = sum(tows * sd^2)), by = "group") %>%
      mutate(stratum = m, sd = sqrt(nsd2 / tows), se_p = sd / sqrt(tows), layer = layer_of(0),
             source = paste0(HALVES[m], " half"), donors = paste(sort(unique(don$stratum)), collapse = "+")) %>%
      select(-nsd2)
  })
  upper <- bind_rows(upper, borrowed)
  sd_own_deep <- filter(to_long(tp), layer == ">= 40 m") %>%
    summarise(.by = group, sd_own = if (n() > 1) sd(p) else NA_real_)
  deep <- filter(to_long(tp_all), layer == ">= 40 m") %>%
    summarise(.by = group, tows = n(), sd = sd(p), p = mean(p), df = n() - 1, years = n_distinct(year)) %>%
    left_join(sd_own_deep, by = "group") %>%
    mutate(se_p = sd / sqrt(tows), layer = layer_of(100), source = "lake-wide deep, all years")
  bind_rows(upper, expand_grid(stratum = strata, deep)) %>%
    select(stratum, layer, group, source, tows, p, sd, sd_own, se_p, df, years, any_of("donors"))
}

# Halves of the lake for strata without upper-layer tows (trawlcomp's north/south rule: wn goes with the south)
HALVES <- c(nn = "north", no = "north", sn = "south", so = "south", wn = "south")

method1 <- function(au = acoustic_units(), tr = trawl_cells(), areas = stratum_areas()) {
  w <- tr %>% select(stratum, layer, group, p)
  # acoustic: per unit species density with p fixed
  ac <- au %>% inner_join(w, by = c("stratum", "layer"), relationship = "many-to-many") %>%
    summarise(.by = c(stratum, group, Region_name), d_u = sum(fish_ha * p)) %>%
    summarise(.by = c(stratum, group), units = n(), D = mean(d_u), var_ac = var(d_u) / n())
  rho <- au %>% summarise(.by = c(stratum, layer), units = n(), rho = mean(fish_ha), var_rho = var(fish_ha) / n())
  tv <- rho %>% inner_join(tr, by = c("stratum", "layer")) %>%
    summarise(.by = c(stratum, group), var_tr = sum(rho^2 * se_p^2), var_x = sum(var_rho * se_p^2))
  st <- ac %>% inner_join(tv, by = c("stratum", "group")) %>%
    mutate(se_D = sqrt(var_ac + var_tr + var_x), cv_D = se_D / D,
           share_acoustic = var_ac / se_D^2, share_trawl = var_tr / se_D^2, share_product = var_x / se_D^2) %>%
    left_join(areas, by = "stratum")
  # lake-wide: upper trawl terms independent between strata; deep trawl term fully correlated
  A <- sum(areas$area_ha)
  up_tr <- rho %>% filter(layer == "< 40 m") %>% inner_join(filter(tr, layer == "< 40 m"), by = c("stratum", "layer")) %>%
    left_join(areas, by = "stratum") %>% summarise(.by = group, v = sum(area_ha^2 * rho^2 * se_p^2))
  # a stratum that borrowed its half's tows: covariance with each donor stratum k, Cov(p_b, p_k) = sd_k^2 / N
  if ("donors" %in% names(tr) && any(!is.na(tr$donors))) {
    ur <- rho %>% filter(layer == "< 40 m") %>% left_join(areas, by = "stratum") %>% transmute(stratum, ar = area_ha * rho)
    cv_tr <- tr %>% filter(layer == "< 40 m", !is.na(donors)) %>% select(stratum, group, N = tows, donors) %>%
      separate_longer_delim(donors, "+") %>%
      left_join(ur, by = "stratum") %>%
      left_join(tr %>% filter(layer == "< 40 m") %>% select(donors = stratum, group, sd_k = sd), by = c("donors", "group")) %>%
      left_join(rename(ur, donors = stratum, ar_k = ar), by = "donors") %>%
      summarise(.by = group, cov = sum(2 * ar * ar_k * sd_k^2 / N))
    up_tr <- up_tr %>% left_join(cv_tr, by = "group") %>% mutate(v = v + coalesce(cov, 0)) %>% select(-cov)
  }
  dp_tr <- rho %>% filter(layer == ">= 40 m") %>% left_join(areas, by = "stratum") %>%
    cross_join(filter(tr, layer == ">= 40 m") %>% distinct(group, se_p)) %>%
    summarise(.by = group, v = sum(area_ha * rho)^2 * first(se_p)^2)
  lake <- st %>% summarise(.by = group, N = sum(area_ha * D), v_ac = sum(area_ha^2 * var_ac), v_x = sum(area_ha^2 * var_x)) %>%
    left_join(rename(up_tr, v_up = v), by = "group") %>% left_join(rename(dp_tr, v_dp = v), by = "group") %>%
    mutate(v_tr = v_up + v_dp, v = v_ac + v_tr + v_x,
           density = N / A, se_density = sqrt(v) / A, cv = sqrt(v) / N,
           share_acoustic = v_ac / v, share_trawl = v_tr / v, share_product = v_x / v) %>%
    select(group, density, se_density, cv, share_acoustic, share_trawl, share_product, N)
  list(rho = rho, trawl = tr, stratum = st, lake = lake)
}
