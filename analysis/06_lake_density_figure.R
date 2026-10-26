# Lake-wide mean density per species, year YEAR, with error bars from method 1 (step 03's output).
# Thick bar = +-1 SE; thin bar = approximate 95% interval (+-1.96 SE, truncated at 0).
source("D:/pyprojects/cv_compare_acmt/R/paths.R")
suppressMessages(library(tidyverse))
lk <- read_csv(out_file("method1_lake"), show_col_types = FALSE) %>%
  mutate(group = factor(group, c("alewife", "smelt", "bloater")),
         lo95 = pmax(0, density - 1.96 * se_density), hi95 = density + 1.96 * se_density,
         label = sprintf("%.0f fish/ha\nCV %.0f%%", density, 100 * cv))
p <- ggplot(lk, aes(group, density, fill = group)) +
  geom_col(width = 0.6, alpha = 0.45) +
  geom_errorbar(aes(ymin = lo95, ymax = hi95), width = 0.12, linewidth = 0.5) +
  geom_errorbar(aes(ymin = density - se_density, ymax = density + se_density), width = 0, linewidth = 1.6) +
  geom_text(aes(y = hi95, label = label), vjust = -0.3, size = 3.5) +
  scale_fill_manual(values = c(alewife = "magenta", smelt = "grey60", bloater = "grey15"), guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = NULL, y = "Lake-wide mean density (fish/ha)",
       title = paste0("Lake Michigan ", YEAR, ": lake-wide mean density by species"),
       subtitle = "Thick bar = +-1 SE; thin bar = approximate 95% interval (+-1.96 SE).\nMethod 1: acoustic + trawl uncertainty combined.",
       caption = paste0(toupper(substr(ACOUSTIC_DESC, 1, 1)), substring(ACOUSTIC_DESC, 2), "; area-weighted over the five strata. All sizes, by number.")) +
  theme_bw(base_size = 11) + theme(plot.caption = element_text(hjust = 0))
ggsave(out_file("lake_density", "png"), p, width = 6.5, height = 5, dpi = 150)
