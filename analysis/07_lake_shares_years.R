# Lake-wide shares of the variance of species density (acoustic, trawl, product) across years, from step 03's output
# for every year that has one (run steps 01-03 for each YEAR first).
source("D:/pyprojects/cv_compare_acmt/R/paths.R")
suppressMessages(library(tidyverse))
years <- as.integer(names(ACOUSTIC_FILES))
years <- years[file.exists(file.path(OUTPUT_DIR, sprintf("method1_lake_%d.csv", years)))]
d <- map_dfr(years, \(y) read_csv(file.path(OUTPUT_DIR, sprintf("method1_lake_%d.csv", y)), show_col_types = FALSE) %>%
               mutate(year = y)) %>%
  mutate(group = factor(group, c("alewife", "smelt", "bloater")),
         units = map_chr(year, \(y) if (length(ACOUSTIC_FILES[[as.character(y)]]) > 1) "ship + saildrone" else "ship"),
         year_lab = factor(paste0(year, "\n", units), unique(paste0(year, "\n", units)[order(year)])))
long <- d %>% pivot_longer(c(share_acoustic, share_trawl, share_product), names_to = "source", values_to = "share") %>%
  mutate(source = factor(str_remove(source, "share_"), c("acoustic", "trawl", "product")))
p <- ggplot(long, aes(year_lab, share, fill = source)) +
  geom_col(width = 0.7) +
  geom_text(data = d, aes(year_lab, 1.05, label = sprintf("CV %.0f%%\n%.0f/ha", 100 * cv, density)), inherit.aes = FALSE,
            size = 2.6, vjust = 0, lineheight = 0.9) +
  facet_wrap(~group, ncol = 1) +
  scale_fill_manual(values = c(acoustic = "steelblue", trawl = "darkorange", product = "grey70"), name = "Source") +
  scale_y_continuous(limits = c(0, 1.28), breaks = c(0, 0.5, 1)) +
  labs(x = NULL, y = "Share of the variance of lake-wide density",
       title = sprintf("Lake Michigan %d-%d: where the uncertainty in lake-wide species density comes from", min(years), max(years)),
       subtitle = "Relative contribution of each gear (bars sum to 1). Label = CV and lake-wide mean density, for context.",
       caption = paste0("Acoustic units per year: 2021 ship transects + saildrone drone-nights (103); other years ship transects only (20-29). No survey in 2020.\n",
                        sprintf("Trawl: each year's stratum proportions above 40 m with the between-tow SD pooled over %d-%d; ", min(TRAWL_YEARS), max(TRAWL_YEARS)),
                        "deep proportion from all years' deep tows. so 2013-2014: no upper tows, south half (sn + wn) used.")) +
  theme_bw(base_size = 11) +
  theme(strip.background = element_rect(fill = "grey92"), legend.position = "bottom", plot.caption = element_text(hjust = 0))
ggsave(file.path(OUTPUT_DIR, sprintf("lake_shares_%d_%d.png", min(years), max(years))), p, width = 12, height = 9.5, dpi = 150)
print(as.data.frame(d %>% transmute(year, group, density = round(density), cv = round(100 * cv),
  acoustic = round(100 * share_acoustic), trawl = round(100 * share_trawl), product = round(100 * share_product))))
