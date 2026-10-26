# Method 1 (analytic) species density and its uncertainty, Lake Michigan, year YEAR (user, 2026-10-24).
# - Acoustics: ship and saildrone POOLED; sampling unit = ship transect or saildrone drone-night, placed in a stratum
#   by majority. Per interval, rho_layer = sum of fish_ha over its 1 m layers in the layer (by mid-depth); unit value
#   = mean over its intervals; stratum rho = mean over units.
# - Trawl: above 40 m by stratum (the year's tows); 40 m and deeper one lake-wide proportion (all the year's deep tows).
#   SE(p) above 40 m = sqrt(rho_od p(1-p)) / sqrt(stratum's tows), rho_od = pooled overdispersion (see trawl_cells);
#   deep SE = SD of the deep tows / sqrt(their number).
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

# Trawl proportions: upper by stratum, deep lake-wide; one row per stratum x layer x group
trawl_cells <- function(tp = tow_props(), strata = c("nn", "no", "sn", "so", "wn")) {
  long <- tp %>% pivot_longer(c(p_alewife, p_smelt, p_bloater), names_to = "group", values_to = "p") %>%
    mutate(group = str_remove(group, "p_"))
  up <- filter(long, layer == "< 40 m")
  # Pooled overdispersion (user, 2026-10-24): a tow proportion's variance ~ rho_od x p(1 - p) (the tow is a cluster;
  # rho_od = intra-tow correlation for large catches). One rho_od per group from all strata:
  #   rho_od = sum over strata of sum (p_t - pbar_s)^2 / sum over strata of (n_s - 1) pbar_s (1 - pbar_s)
  # and each stratum's SD = sqrt(rho_od x pbar_s (1 - pbar_s)), so it scales with the stratum's own composition.
  rho_od <- up %>% mutate(.by = c(stratum, group), pbar = mean(p), n_s = n()) %>%
    summarise(.by = c(stratum, group), ss = sum((p - pbar)^2), w = (first(n_s) - 1) * first(pbar) * (1 - first(pbar))) %>%
    summarise(.by = group, rho_od = sum(ss) / sum(w))
  upper <- up %>% summarise(.by = c(stratum, group), tows = n(), sd_own = if (n() > 1) sd(p) else NA_real_, p = mean(p)) %>%
    left_join(rho_od, by = "group") %>%
    mutate(layer = layer_of(0), source = "stratum", sd = sqrt(rho_od * p * (1 - p)), se_p = sd / sqrt(tows))
  deep <- filter(long, layer == ">= 40 m") %>%
    summarise(.by = group, tows = n(), sd = sd(p), p = mean(p)) %>%
    mutate(se_p = sd / sqrt(tows), sd_own = sd, layer = layer_of(100), source = "lake-wide deep")
  bind_rows(upper, expand_grid(stratum = strata, deep)) %>%
    select(stratum, layer, group, source, tows, p, sd, sd_own, se_p, any_of("rho_od"))
}

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
