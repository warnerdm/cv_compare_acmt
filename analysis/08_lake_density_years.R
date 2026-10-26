# Lake-wide mean density per species across years, with error bars from method 1 (step 03's output for every year
# that has one; run steps 01-03 for each YEAR first). Thick bar = +-1 SE; thin bar = approximate 95% interval
# (+-1.96 SE, truncated at 0).
source("D:/pyprojects/cv_compare_acmt/R/paths.R")
suppressMessages(library(tidyverse))
years <- as.integer(names(ACOUSTIC_FILES))
years <- years[file.exists(file.path(OUTPUT_DIR, sprintf("method1_lake_%d.csv", years)))]
d <- map_dfr(years, \(y) read_csv(file.path(OUTPUT_DIR, sprintf("method1_lake_%d.csv", y)), show_col_types = FALSE) %>%
               mutate(year = y)) %>%
  mutate(group = factor(group, c("alewife", "smelt", "bloater")),
         lo95 = pmax(0, density - 1.96 * se_density), hi95 = density + 1.96 * se_density,
         platform = if_else(map_int(year, \(y) length(ACOUSTIC_FILES[[as.character(y)]])) > 1, "ship + saildrone", "ship"))
p <- ggplot(d, aes(year, density, fill = group)) +
  geom_col(width = 0.7, alpha = 0.45) +
  geom_errorbar(aes(ymin = lo95, ymax = hi95), width = 0.25, linewidth = 0.4) +
  geom_errorbar(aes(ymin = pmax(0, density - se_density), ymax = density + se_density), width = 0, linewidth = 1.3) +
  geom_text(aes(y = hi95, label = sprintf("%.0f%%", 100 * cv)), vjust = -0.4, size = 2.7) +
  facet_wrap(~group, ncol = 1, scales = "free_y") +
  scale_fill_manual(values = c(alewife = "magenta", smelt = "grey60", bloater = "grey15"), guide = "none") +
  scale_x_continuous(breaks = years, minor_breaks = NULL) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = NULL, y = "Lake-wide mean density (fish/ha)",
       title = sprintf("Lake Michigan %d-%d: lake-wide mean density by species", min(years), max(years)),
       subtitle = "Thick bar = +-1 SE; thin bar = approximate 95% interval (+-1.96 SE, truncated at 0). Label = CV.\nMethod 1: acoustic + trawl uncertainty combined.",
       caption = paste0("Area-weighted over the five strata; all sizes, by number. Acoustics: 2021 ship + saildrone, other years ship transects. ",
                        "No survey in 2020.\n", sprintf("Trawl spread pooled over %d-%d; deep proportion from all years' deep tows.", min(TRAWL_YEARS), max(TRAWL_YEARS)))) +
  theme_bw(base_size = 11) +
  theme(strip.background = element_rect(fill = "grey92"), plot.caption = element_text(hjust = 0))
ggsave(file.path(OUTPUT_DIR, sprintf("lake_density_%d_%d.png", min(years), max(years))), p, width = 10, height = 9, dpi = 150)
