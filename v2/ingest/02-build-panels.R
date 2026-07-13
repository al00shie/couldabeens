# v2 ingest step 2: build player-season panels and rookie/retiree tables.
# Run from the repo root:  Rscript v2/ingest/02-build-panels.R
#
# From the raw B-R WAR files (full history, 1871-present):
#   - player_seasons.csv.gz  one row per player x season x class, stints
#                            aggregated; class = "pos" (bat file, pitcher=="N")
#                            or "pit" (pitch file). Two-way players appear in
#                            both classes, matching the v1 design. Carries G,
#                            AB/IP and cumulative-prior exposure so step 3 can
#                            apply rookie-status logic.
#   - rookies.csv.gz         rookie seasons under two definitions:
#                            "debut" (first season in class) and "status"
#                            (first qualifying season -- G>=30 pos / IP>=50
#                            pit -- while still rookie-eligible: prior career
#                            AB<130 / IP<50). The status definition mirrors
#                            the Stathead queries behind the v1 CSVs, whose
#                            implicit filters (min G=30 / min IP=50 on both
#                            rookie and retiree files) were recovered in the
#                            v1 reconciliation.
#   - retirees.csv.gz        each player's LAST season in class, with
#                            final-season WAR, a 3-season peak, a qualifies
#                            flag (G>=30 / IP>=50, the v1-parity population),
#                            and a provisional flag for the newest cohort
#
# Censoring: the raw files include the in-progress season, so retiree
# cohorts stop at max_year - 1 and that last cohort is flagged provisional.

suppressMessages(library(tidyverse))

RAW <- "v2/data/raw"
GEN <- "v2/data-gen"
dir.create(GEN, recursive = TRUE, showWarnings = FALSE)

bat <- read_csv(file.path(RAW, "war_daily_bat.txt"),
                col_types = cols_only(name_common = "c", player_ID = "c",
                                      year_ID = "i", age = "i", G = "d",
                                      PA = "d", WAR = "d", salary = "d",
                                      pitcher = "c")) %>%
  mutate(AB = NA_real_)
# AB isn't in the WAR file; rookie-status eligibility uses PA<145 as the
# 130-AB proxy (PA ~ 1.11*AB for typical walk/HBP rates)

pit <- read_csv(file.path(RAW, "war_daily_pitch.txt"),
                col_types = cols_only(name_common = "c", player_ID = "c",
                                      year_ID = "i", age = "i", G = "d",
                                      IPouts = "d", WAR = "d", salary = "d"))

max_year  <- max(bat$year_ID)
last_full <- max_year - 1

seasons <- bind_rows(
  bat %>% filter(pitcher == "N") %>%
    group_by(player_ID, name = name_common, year = year_ID) %>%
    summarise(age = max(age), G = sum(G, na.rm = TRUE),
              exposure = sum(PA, na.rm = TRUE),
              WAR = sum(WAR, na.rm = TRUE),
              salary = sum(salary, na.rm = TRUE), .groups = "drop") %>%
    mutate(class = "pos"),
  pit %>%
    group_by(player_ID, name = name_common, year = year_ID) %>%
    summarise(age = max(age), G = sum(G, na.rm = TRUE),
              exposure = sum(IPouts, na.rm = TRUE) / 3,
              WAR = sum(WAR, na.rm = TRUE),
              salary = sum(salary, na.rm = TRUE), .groups = "drop") %>%
    mutate(class = "pit")
)
# exposure: plate appearances (pos) / innings pitched (pit)

seasons <- seasons %>%
  group_by(player_ID, class) %>%
  arrange(year, .by_group = TRUE) %>%
  mutate(first_year = min(year), last_year = max(year),
         prior_exposure = lag(cumsum(exposure), default = 0)) %>%
  ungroup()

# season "qualifies" under the recovered v1 Stathead filters
qual <- function(class, G, exposure) {
  if_else(class == "pos", G >= 30, exposure >= 50)
}
# still rookie-eligible entering the season (130 AB ~ 145 PA / 50 IP)
eligible <- function(class, prior_exposure) {
  if_else(class == "pos", prior_exposure < 145, prior_exposure < 50)
}

rookies <- bind_rows(
  seasons %>% filter(year == first_year) %>% mutate(definition = "debut"),
  seasons %>%
    filter(qual(class, G, exposure), eligible(class, prior_exposure)) %>%
    group_by(player_ID, class) %>%
    slice_min(year, n = 1, with_ties = FALSE) %>%
    ungroup() %>% mutate(definition = "status")
)

peak3 <- seasons %>%
  filter(year >= last_year - 2) %>%
  group_by(player_ID, class) %>%
  summarise(WAR_peak3 = max(WAR), .groups = "drop")

retirees <- seasons %>%
  filter(year == last_year, year <= last_full) %>%
  left_join(peak3, by = c("player_ID", "class")) %>%
  mutate(qualifies = qual(class, G, exposure),
         provisional = year == last_full)

write_csv(seasons %>% select(-first_year, -last_year),
          file.path(GEN, "player_seasons.csv.gz"))
write_csv(rookies,  file.path(GEN, "rookies.csv.gz"))
write_csv(retirees, file.path(GEN, "retirees.csv.gz"))

cat("seasons:", nrow(seasons),
    "| rookies (status):", sum(rookies$definition == "status"),
    "| retirees:", nrow(retirees),
    "of which qualifying:", sum(retirees$qualifies),
    "| cohorts through", last_full, "\n")
