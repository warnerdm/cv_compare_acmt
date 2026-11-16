# Step 10: compare five ways of assigning trawl composition (nearest tow, slice mean, GAM all years, GAM within year, tree per year and layer) by how
# well each predicts a tow it did not see (R/apportion_cv.R). Reads inputs/version_of_record (step 09).
# Writes output/apportion_cv/: tows.csv (one row per tow: observed, the four predictions' scores), summary tables,
# and figures.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2) })
source("R/apportion_cv.R")
out <- "output/apportion_cv"; dir.create(out, recursive = TRUE, showWarnings = FALSE)
years <- c(2004:2019, 2021:2024)
t <- do.call(rbind, lapply(years, tow_table))
cat("tows with >=", MIN_FISH, "fish:", nrow(t), "| by slice type:", table(t$slice == "deep"), "\n")
obs <- props(t)
ns <- pred_nearest_slice(t)
gm <- pred_gam(t)
gy <- pred_gam_year(t); cat("within-year GAM: fits failing all three forms (year mean used):", attr(gy, "failed"), "\n")
tr <- pred_tree(t)                                   # per year and layer, fish, cp 0.05, minbucket 5 (Yule et al.)
tw <- pred_tree(t, minbucket = 1, weight = "tow")    # sensitivity: every tow equal
sc <- data.frame(t[, c("year", "OP_ID", "TRANSECT", "slice", "FISHING_DEPTH", "bottom", "total")], neighbours = ns$source,
                 nearest = tad(ns$nearest, obs), slice_mean = tad(ns$slice, obs), gam = tad(gm, obs), gam_year = tad(gy, obs),
                 tree = tad(tr, obs), tree_tow = tad(tw, obs))
sc <- sc[!is.na(sc$nearest) & !is.na(sc$tree), ]   # tows with no other tow in their year and layer cannot be scored
write.csv(sc, file.path(out, "tows.csv"), row.names = FALSE)
cat("tree, every tow equal (sensitivity): mean TAD", round(mean(sc$tree_tow), 3), "\n")
m <- c("nearest", "slice_mean", "gam", "gam_year", "tree")
overall <- data.frame(method = m, mean_tad = round(colMeans(sc[m]), 3), median_tad = round(apply(sc[m], 2, median), 3),
                      share_misassigned = round(colMeans(sc[m]) / 2, 3),
                      best_on_tows = as.vector(table(factor(m[apply(sc[m], 1, which.min)], m))))
print(overall, row.names = FALSE); write.csv(overall, file.path(out, "overall.csv"), row.names = FALSE)
by_year <- sc %>% group_by(year) %>% summarise(tows = n(), across(all_of(m), ~ round(mean(.x), 3)), .groups = "drop")
by_layer <- sc %>% mutate(layer = ifelse(slice == "deep", "deep (>= 40 m)", "upper (< 40 m)")) %>% group_by(layer) %>%
  summarise(tows = n(), across(all_of(m), ~ round(mean(.x), 3)), .groups = "drop")
write.csv(by_year, file.path(out, "by_year.csv"), row.names = FALSE); write.csv(by_layer, file.path(out, "by_layer.csv"), row.names = FALSE)
print(as.data.frame(by_layer), row.names = FALSE); print(as.data.frame(by_year), row.names = FALSE)
long <- tidyr::pivot_longer(by_year, all_of(m), names_to = "method", values_to = "mean_tad")
long$method <- factor(long$method, m, c("Nearest tow", "Slice mean", "GAM (all years)", "GAM (within year)", "Tree (per year and layer)"))
p <- ggplot(long, aes(year, mean_tad / 2, colour = method, shape = method, group = interaction(method, year > 2020))) +
  geom_line(linewidth = 0.7) + geom_point(size = 2.2) +
  scale_colour_manual(values = c("#2a78d6", "#eb6834", "#1baf7a", "#0b6b4a", "#6250d6"), name = NULL) + scale_shape_manual(values = c(16, 17, 15, 0, 18), name = NULL) +
  scale_y_continuous(labels = scales::percent, limits = c(0, NA)) + scale_x_continuous(breaks = seq(2004, 2024, 2)) +
  labs(title = "Predicting an unseen tow's composition: share of fish misassigned", x = NULL, y = "mean share misassigned",
       caption = "Lake Michigan, tows with >= 5 fish; six groups (alewife, rainbow smelt, bloater x small/large). Lower is better. No 2020 survey.") +
  theme_minimal(base_size = 11) + theme(legend.position = "top", legend.justification = "left", plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(), plot.caption = element_text(hjust = 0, colour = "#6b6a63"))
ggsave(file.path(out, "misassigned_by_year.png"), p, width = 10, height = 5, dpi = 150, bg = "white")
cat("wrote", out, "\n")
