# Share of the variance of species density from acoustics, trawl and their product, by stratum and lake-wide
# (as trawlcomp's two_gear_michigan_<year>_region_layer.png), from step 03's output.
source("D:/pyprojects/cv_compare_acmt/R/paths.R")
suppressMessages(library(tidyverse))
lv_g <- c("alewife", "smelt", "bloater")
st <- read_csv(out_file("method1_stratum"), show_col_types = FALSE) %>%
  transmute(unit = stratum, group, cv = cv_D, acoustic = share_acoustic, trawl = share_trawl, product = share_product)
lk <- read_csv(out_file("method1_lake"), show_col_types = FALSE) %>%
  transmute(unit = "Lake-wide", group, cv, acoustic = share_acoustic, trawl = share_trawl, product = share_product)
d <- bind_rows(st, lk) %>%
  mutate(unit = factor(unit, c("nn", "no", "wn", "sn", "so", "Lake-wide")), group = factor(group, lv_g))
long <- d %>% pivot_longer(c(acoustic, trawl, product), names_to = "source", values_to = "share") %>%
  mutate(source = factor(source, c("acoustic", "trawl", "product")))
p <- ggplot(long, aes(group, share, fill = source)) +
  geom_col(width = 0.7) +
  geom_text(data = d, aes(group, 1.05, label = paste0("CV ", round(100 * cv), "%")), inherit.aes = FALSE, size = 3) +
  facet_wrap(~unit, nrow = 1) +
  scale_fill_manual(values = c(acoustic = "steelblue", trawl = "darkorange", product = "grey70"), name = "Source") +
  scale_y_continuous(limits = c(0, 1.1), breaks = c(0, 0.5, 1)) +
  labs(x = NULL, y = "Share of the variance of species density",
       title = paste0("Lake Michigan ", YEAR, ": where the uncertainty in species density comes from, by stratum"),
       subtitle = "Relative contribution of each gear to the variance of each species' density (bars sum to 1). Label = CV, for context.",
       caption = paste0(toupper(substr(ACOUSTIC_DESC, 1, 1)), substring(ACOUSTIC_DESC, 2), "; trawl by stratum above 40 m, lake-wide below. Large CVs = species nearly absent from that stratum.")) +
  theme_bw(base_size = 11) +
  theme(strip.background = element_rect(fill = "grey92"), legend.position = "bottom", axis.text.x = element_text(angle = 30, hjust = 1),
        plot.caption = element_text(hjust = 0))
ggsave(out_file("shares_by_stratum", "png"), p, width = 13, height = 4.8, dpi = 150)
