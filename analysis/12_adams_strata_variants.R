# Adams et al. (2006) depth strata (k = 4, 20 m cells, >= 2 tows per cell) from the 1994-1995 tows, run for each
# uncertain choice, and compared with the paper's Table 4 (136 tows; 32 / 23 / 27 / 54 per stratum):
#   tows    with or without 20325 (fished at the lakebed)
#   bottom  start, mean or end bottom depth of the tow
#   edge    a depth on a 20 m line goes to the cell below or above
# Writes output/adams_strata_variants.csv (one row per variant x stratum) and prints the scores.
# Score: kept tows vs 136, sum of |tows - paper| over the four strata, mean |difference| of the 6 mean/SD values x 4.
source("D:/pyprojects/cv_compare_acmt/R/adams.R")
dir.create(OUTPUT_DIR, showWarnings = FALSE)

variants <- expand_grid(with_20325 = c(TRUE, FALSE), bottom = c("beg_depth", "mean_depth", "end_depth"),
                        edge = c("lower", "upper"))
res <- pmap(variants, \(with_20325, bottom, edge) {
  tows <- adams_tows(excluded = if (with_20325) integer() else ADAMS_LAKEBED_TOW)
  st <- adams_strata(tows, bottom = bottom, edge = edge)
  tab <- adams_stratum_table(st)
  tibble(with_20325, bottom, edge, tows_in = nrow(st$tows), tows_kept = sum(!is.na(st$tows$stratum)),
         tab = list(tab))
}) %>% list_rbind()

score <- res %>%
  mutate(n_strata = map_int(tab, nrow),
         tows_diff = map_dbl(tab, \(t) if (nrow(t) != 4) NA else
           sum(abs(t$tows - ADAMS_TABLE4$tows[match(as.character(t$name), ADAMS_TABLE4$name)]))),
         value_diff = map_dbl(tab, \(t) if (nrow(t) != 4) NA else {
           y <-t %>% mutate(name = as.character(name)) %>% select(name, starts_with("mean_p"), starts_with("sd_p")) %>%
             pivot_longer(-name, names_to = "var", values_to = "ours")
           z <- ADAMS_TABLE4 %>% select(-tows) %>% pivot_longer(-name, names_to = "var", values_to = "paper")
           mean(abs(inner_join(y, z, by = c("name", "var")) %>% with(ours - paper)))
         })) %>%
  select(-tab)
print(arrange(score, tows_diff, value_diff), n = Inf, width = Inf)

out <- res %>% select(-tows_in) %>% unnest(tab)
write_csv(out, file.path(OUTPUT_DIR, "adams_strata_variants.csv"))
best <- res[which.min(score$tows_diff + 10 * coalesce(score$value_diff, 9)), ]
cat("\nBest variant:", best$bottom, best$edge, if (best$with_20325) "with 20325" else "without 20325", "\n")
print(best$tab[[1]] %>% mutate(across(where(is.numeric), \(x) round(x, 2))), width = Inf)
cat("\nPaper Table 4:\n"); print(ADAMS_TABLE4, width = Inf)
