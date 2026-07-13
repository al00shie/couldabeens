# v2 ingest step 3: yearly couldabeen counts under three classifiers.
# Run from the repo root:  Rscript v2/ingest/03-build-couldabeens.R
#
# PRIMARY population (v1 parity, "regulars"): rookie seasons under the
# "status" definition and retirees whose final season qualifies (G>=30 pos /
# IP>=50 pit) -- the implicit Stathead filters recovered from the v1 CSVs.
# SENSITIVITY population ("full"): debut-season rookies and all retirees.
#
# Classifiers, per year Y and class, then combined into league-year counts:
#   raw    final-season WAR >= mean rookie WAR (the v1 definition)
#   rate   WAR per 600 PA / per 180 IP >= mean rookie rate (exposure floors
#          already guaranteed in the primary population; the full population
#          applies 50 PA / 20 IP floors on both sides)
#   peak3  best single-season WAR across the final three seasons >= raw thr
# This script is the committed writer that v1's couldabeens.csv never had.

suppressMessages(library(tidyverse))

GEN <- "v2/data-gen"
YR0 <- 1969
SCALE <- c(pos = 600, pit = 180)
FLOOR_FULL <- c(pos = 50, pit = 20)

rookies  <- read_csv(file.path(GEN, "rookies.csv.gz"),  show_col_types = FALSE)
retirees <- read_csv(file.path(GEN, "retirees.csv.gz"), show_col_types = FALSE)
YR1 <- max(retirees$year)

build_series <- function(rk, rt, floor_by_class = NULL) {
  thr <- rk %>%
    filter(year >= YR0, year <= YR1) %>%
    group_by(year, class) %>%
    summarise(thr_raw = mean(WAR),
              thr_rate = mean(WAR / exposure * SCALE[first(class)]),
              n_rookies = n(), .groups = "drop")
  cls <- rt %>%
    filter(year >= YR0) %>%
    left_join(thr, by = c("year", "class")) %>%
    mutate(rate = WAR / exposure * SCALE[class],
           rate_ok = if (is.null(floor_by_class)) TRUE
                     else exposure >= floor_by_class[class],
           cb_raw   = WAR >= thr_raw,
           cb_rate  = rate_ok & rate >= thr_rate,
           cb_peak3 = WAR_peak3 >= thr_raw)
  list(
    thresholds = thr,
    classified = cls,
    yearly = cls %>%
      group_by(year) %>%
      summarise(retirees   = n(),
                cbns_raw   = sum(cb_raw),   prop_raw   = mean(cb_raw),
                cbns_rate  = sum(cb_rate),  prop_rate  = mean(cb_rate),
                cbns_peak3 = sum(cb_peak3), prop_peak3 = mean(cb_peak3),
                provisional = first(provisional), .groups = "drop"))
}

primary <- build_series(
  rookies %>% filter(definition == "status"),
  retirees %>% filter(qualifies))

full <- build_series(
  rookies %>% filter(definition == "debut",
                     exposure >= FLOOR_FULL[class] | TRUE),
  retirees,
  floor_by_class = FLOOR_FULL)

write_csv(primary$thresholds, file.path(GEN, "thresholds_v2.csv"))
write_csv(primary$classified %>%
            select(player_ID, name, class, year, age, G, exposure, WAR,
                   WAR_peak3, rate, starts_with("cb_"), provisional),
          file.path(GEN, "retirees_classified.csv.gz"))
write_csv(primary$yearly, file.path(GEN, "couldabeens_v2.csv"))
write_csv(full$yearly,    file.path(GEN, "couldabeens_v2_full.csv"))

cat("years:", YR0, "-", YR1, "(primary population: v1-parity regulars)\n")
print(as.data.frame(tail(primary$yearly, 4)), digits = 3)
