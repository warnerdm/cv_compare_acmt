# Method 1 drawn step by step for one stratum and species (env vars STRATUM, GROUP; default sn, bloater), year YEAR,
# pooled acoustic platforms: A acoustic units by layer; B tow proportions (stratum above 40 m, lake-wide deep);
# C each unit's species density with p fixed; D the variance contributions. Matches step 03.
source("D:/pyprojects/cv_compare_acmt/R/estimate.R")
suppressMessages(library(patchwork))
STRATUM <- Sys.getenv("STRATUM", "sn"); GROUP <- Sys.getenv("GROUP", "bloater")
lv <- levels(layer_of(0))

au <- acoustic_units() %>% filter(stratum == STRATUM) %>% mutate(layer = factor(layer, lv))
tp <- tow_props()
tr <- trawl_cells(tp) %>% filter(stratum == STRATUM, group == GROUP) %>% mutate(layer = factor(layer, lv))
pl <- setNames(tr$p, as.character(tr$layer)); sel <- setNames(tr$se_p, as.character(tr$layer))
sdl <- setNames(tr$sd, as.character(tr$layer)); ntw <- setNames(tr$tows, as.character(tr$layer))
rho_od <- tr$rho_od[!is.na(tr$rho_od)][1]

# A: acoustic units
rho <- au %>% summarise(.by = layer, rho = mean(fish_ha), se = sd(fish_ha) / sqrt(n()), n = n())
pA <- ggplot(au, aes(layer, fish_ha)) +
  geom_jitter(aes(colour = platform, shape = platform), width = 0.1, height = 0, size = 2, alpha = 0.8) +
  geom_pointrange(data = rho, aes(y = rho, ymin = rho - se, ymax = rho + se), size = 0.6, position = position_nudge(x = 0.28)) +
  geom_text(data = rho, aes(y = rho, label = sprintf("rho = %.0f\nSE %.0f (n = %d)", rho, se, n)),
            position = position_nudge(x = 0.45), hjust = 0, size = 3.2) +
  scale_colour_manual(values = c(ships = "#1f4e9c", saildrone = "#2ca25f"), name = NULL) +
  scale_shape_manual(values = c(ships = 16, saildrone = 17), name = NULL) +
  scale_x_discrete(expand = expansion(add = c(0.5, 1.3))) +
  labs(x = "Depth layer", y = "Fish/ha (all species)", title = "A. Acoustics: each point is one transect or drone-night",
       subtitle = paste0("rho = mean of units (", ACOUSTIC_DESC, "); SE = SD / sqrt(units)")) +
  theme_bw(base_size = 10) + theme(legend.position = c(0.85, 0.85), legend.background = element_blank())

# B: tows (stratum above 40 m; all deep tows lake-wide)
B <- tp %>% filter((layer == lv[1] & stratum == STRATUM) | layer == lv[2]) %>%
  mutate(layer = factor(layer, lv), p = .data[[paste0("p_", GROUP)]])
trB <- tibble(layer = factor(lv, lv), p = pl[lv], se = sel[lv], sd = sdl[lv], n = ntw[lv]) %>%
  mutate(label = if_else(layer == lv[1],
    sprintf("p = %.2f\nSD = sqrt(%.2f x p(1-p)) = %.2f\nSE = %.2f / sqrt(%d) = %.2f", p, rho_od, sd, sd, n, se),
    sprintf("p = %.2f (lake-wide)\nSE = %.2f / sqrt(%d) = %.2f", p, sd, n, se)))
pB <- ggplot(B, aes(layer, p)) +
  geom_jitter(width = 0.1, height = 0, size = 2, colour = "darkorange", alpha = 0.8) +
  geom_pointrange(data = trB, aes(y = p, ymin = pmax(0, p - se), ymax = pmin(1, p + se)), size = 0.6,
                  position = position_nudge(x = 0.28)) +
  geom_text(data = trB, aes(y = p, label = label), position = position_nudge(x = 0.45), hjust = 0, size = 3) +
  scale_y_continuous(limits = c(0, 1.05)) + scale_x_discrete(expand = expansion(add = c(0.5, 1.6))) +
  labs(x = "Depth layer (tow fishing depth)", y = paste("Proportion", GROUP), title = "B. Trawl: each point is one tow",
       subtitle = sprintf("Above 40 m: %s's %d tows; 40 m and deeper: all %d deep tows (lake-wide)", STRATUM, YEAR, YEAR)) +
  theme_bw(base_size = 10)

# C: unit species density with p fixed
C <- au %>% mutate(w = pl[as.character(layer)]) %>% summarise(.by = c(platform, Region_name), d_u = sum(fish_ha * w))
Dm <- mean(C$d_u); var_ac <- var(C$d_u) / nrow(C)
pC <- ggplot(C, aes("units", d_u)) +
  geom_jitter(aes(colour = platform, shape = platform), width = 0.08, height = 0, size = 2, alpha = 0.8) +
  geom_pointrange(data = tibble(), aes(x = "units", y = Dm, ymin = Dm - sqrt(var_ac), ymax = Dm + sqrt(var_ac)),
                  size = 0.6, position = position_nudge(x = 0.2), inherit.aes = FALSE) +
  annotate("text", x = 1.3, y = Dm, hjust = 0, size = 3.2, label = sprintf("D = %.0f\nacoustic SE %.0f", Dm, sqrt(var_ac))) +
  scale_colour_manual(values = c(ships = "#1f4e9c", saildrone = "#2ca25f"), name = NULL) +
  scale_shape_manual(values = c(ships = 16, saildrone = 17), name = NULL) +
  labs(x = NULL, y = paste(GROUP, "/ha"), title = "C. Species density per unit",
       subtitle = sprintf("D_u = rho_upper,u x %.2f + rho_lower,u x %.2f", pl[lv[1]], pl[lv[2]])) +
  theme_bw(base_size = 10) + theme(legend.position = c(0.85, 0.9), legend.background = element_blank())

# D: variance contributions
rl <- setNames(rho$rho, as.character(rho$layer)); vr <- setNames(rho$se^2, as.character(rho$layer))
var_tr <- sum(rl[lv]^2 * sel[lv]^2); var_x <- sum(vr[lv] * sel[lv]^2); tot <- var_ac + var_tr + var_x
vt <- tibble(term = factor(c("acoustic", "trawl", "product"), c("acoustic", "trawl", "product")), value = c(var_ac, var_tr, var_x),
             how = c("var(D_u) / units", "sum over layers of\nrho^2 x SE(p)^2", "sum over layers of\nSE(rho)^2 x SE(p)^2"))
pD <- ggplot(vt, aes(term, value, fill = term)) + geom_col(width = 0.6) +
  geom_text(aes(label = sprintf("%s\n%.0f (%.0f%%)", how, value, 100 * value / tot)), vjust = -0.15, size = 3) +
  scale_fill_manual(values = c(acoustic = "steelblue", trawl = "darkorange", product = "grey60"), guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.35))) +
  labs(x = NULL, y = paste0("Contribution to the variance of\nspecies density, (", GROUP, "/ha)^2"),
       title = "D. Add the variance contributions (all in density units)",
       subtitle = sprintf("Var = %.0f; SE = %.0f; CV = %.0f / %.0f = %.0f%%", tot, sqrt(tot), sqrt(tot), Dm, 100 * sqrt(tot) / Dm),
       caption = "Trawl bar = the proportion's variance converted to density units (x rho^2); product = both uncertainties together.") +
  theme_bw(base_size = 10) + theme(plot.caption = element_text(hjust = 0, size = 8))

p <- (pA | pB) / (pC | pD) + plot_annotation(
  title = sprintf("Method 1 step by step: %s in stratum %s, Lake Michigan %d (%s)", GROUP, STRATUM, YEAR, ACOUSTIC_DESC),
  subtitle = "Species density D = rho_upper x p_upper + rho_lower x p_deep (layers split at 40 m)")
ggsave(out_file(sprintf("worked_%s_%s", STRATUM, GROUP), "png"), p, width = 14, height = 9, dpi = 150)
cat(sprintf("D %.1f, var_ac %.0f, var_tr %.0f, var_x %.0f, SE %.1f, CV %.3f\n", Dm, var_ac, var_tr, var_x, sqrt(tot), sqrt(tot) / Dm))
