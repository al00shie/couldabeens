# v2 ingest step 5: reconcile the v2 pipeline against the committed v1 data.
# Run from the repo root:  Rscript v2/ingest/05-validate-v1.R
#
# v1's couldabeens CSVs were written interactively in 2020 (no committed
# writer) from hand-pulled Stathead exports; v2 rebuilds the series from
# B-R's raw WAR files with an explicit rookie definition (first MLB season
# in class). Exact equality is not expected -- the check is that the raw-
# classifier v2 series tracks v1 closely over the overlap years, and that
# divergences are explainable (rookie-set definition, retiree censoring).

suppressMessages(library(tidyverse))
GEN <- "v2/data-gen"

v1 <- read_csv("data-gen/couldabeens_t.csv", show_col_types = FALSE)
v2 <- read_csv(file.path(GEN, "couldabeens_v2.csv"), show_col_types = FALSE)

both <- inner_join(
  v1 %>% select(year = Year, prop_v1 = prop),
  v2 %>% select(year, prop_v2 = prop_raw),
  by = "year")

r   <- cor(both$prop_v1, both$prop_v2)
mad <- mean(abs(both$prop_v1 - both$prop_v2))
bias <- mean(both$prop_v2 - both$prop_v1)

cat(sprintf("overlap years: %d (%d-%d)\n", nrow(both), min(both$year), max(both$year)))
cat(sprintf("correlation: %.3f | mean abs diff: %.4f | mean bias (v2-v1): %+.4f\n",
            r, mad, bias))

p <- both %>%
  pivot_longer(-year, names_to = "pipeline", values_to = "prop") %>%
  ggplot(aes(year, prop, color = pipeline)) +
  geom_line() + geom_point(size = 1) +
  scale_color_manual(values = c(prop_v1 = "#2a78d6", prop_v2 = "#1baf7a"),
                     labels = c("v1 (2020, Stathead)", "v2 (B-R raw WAR)")) +
  labs(title = "v1 vs v2 couldabeen proportion, raw classifier",
       x = NULL, y = "prop", color = NULL) +
  theme_minimal()
ggsave(file.path(GEN, "validation-v1-overlay.png"), p,
       width = 8, height = 4.5, dpi = 150)

writeLines(c(
  sprintf("date: %s", Sys.Date()),
  sprintf("overlap: %d years (%d-%d)", nrow(both), min(both$year), max(both$year)),
  sprintf("correlation: %.3f", r),
  sprintf("mean_abs_diff: %.4f", mad),
  sprintf("mean_bias_v2_minus_v1: %+.4f", bias)),
  file.path(GEN, "validation-v1.txt"))
