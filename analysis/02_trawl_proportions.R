# 2021 tows: catch, rules applied, tows per stratum x layer, mean proportions.
source("D:/pyprojects/cv_compare_acmt/R/trawl.R")
options(width = 200)
tc <- tow_catch()
cat("tows:", nrow(tc), " without catch rows:", sum(!tc$OP_ID %in% read_catch()$OP_ID),
    " alewife removed (> 40 m):", sum(tc$alewife_removed), "fish in", sum(tc$alewife_removed > 0), "tows",
    " n < 5:", sum(tc$n < MIN_FISH), "\n")
tp <- tow_props(tc)
cat("used:", nrow(tp), "\n")
s <- tp %>% summarise(.by = c(stratum, layer), tows = n(), alewife = mean(p_alewife), smelt = mean(p_smelt), bloater = mean(p_bloater)) %>%
  arrange(stratum, layer) %>% mutate(across(c(alewife, smelt, bloater), \(x) round(x, 2)))
print(as.data.frame(s))
write_csv(tp, file.path(OUTPUT_DIR, "tow_props_2021.csv"))
