# v2 ingest step 6: team payrolls 2003-2025, tax pressure, player-team map.
# Run from the repo root:  Rscript v2/ingest/06-team-payroll.R
#
# Sources:
#   2003-2010  Lahman::Salaries team sums (opening-day player salaries;
#              Lahman ships 1985-2016, used from 1985 for percentile ranks)
#   2011-2025  Spotrac payroll tracker (v2/data/raw/spotrac_team_payrolls.csv,
#              captured 2026-07-12); 2020 figures are COVID-prorated
# The two sources use different payroll definitions, so the primary pressure
# variable is the WITHIN-YEAR PERCENTILE of team payroll (splice- and
# proration-invariant); payroll/CBT-threshold ratio is kept for 2003+ as a
# secondary measure. Overlap years 2011-2016 validate the splice.
#
# Also emits each player's primary team per season (max-exposure stint) from
# the raw B-R WAR files, mapped to stable franchise codes.

suppressMessages({library(tidyverse); library(Lahman)})

RAW <- "v2/data/raw"; GEN <- "v2/data-gen"

to_franchise <- c(  # map any historical/source code -> stable B-R code
  ANA="LAA", CAL="LAA", FLA="MIA", FLO="MIA", MON="WSN", TBD="TBR",
  WAS="WSN", WSH="WSN", CHN="CHC", CHA="CHW", KCA="KCR", KC="KCR",
  LAN="LAD", NYA="NYY", NYN="NYM", SDN="SDP", SD="SDP", SFN="SFG",
  SF="SFG", SLN="STL", TBA="TBR", TB="TBR", ATH="OAK")
franchise <- function(x) coalesce(to_franchise[x], x)

lah <- Salaries %>%
  group_by(year = yearID, team_raw = teamID) %>%
  summarise(payroll_usd = sum(salary), .groups = "drop") %>%
  mutate(team = franchise(as.character(team_raw)), source = "lahman") %>%
  select(year, team, payroll_usd, source)

spo <- read_csv(file.path(RAW, "spotrac_team_payrolls.csv"),
                show_col_types = FALSE) %>%
  mutate(team = franchise(team_spotrac), source = "spotrac") %>%
  select(year, team, payroll_usd, source)

# splice validation on the 2011-2016 overlap
ovl <- inner_join(lah, spo, by = c("year", "team"), suffix = c("_lah", "_spo"))
cat(sprintf("splice overlap %d team-years: correlation %.3f, median ratio spo/lah %.3f\n",
            nrow(ovl), cor(ovl$payroll_usd_lah, ovl$payroll_usd_spo),
            median(ovl$payroll_usd_spo / ovl$payroll_usd_lah)))

payrolls <- bind_rows(lah %>% filter(year <= 2010), spo) %>%
  group_by(year) %>%
  mutate(pay_pctile = percent_rank(payroll_usd),
         prorated = year == 2020) %>%
  ungroup()

cbt <- read_csv(file.path(GEN, "cbt_thresholds.csv"), show_col_types = FALSE)
payrolls <- payrolls %>%
  left_join(cbt, by = "year") %>%
  mutate(tax_ratio = if_else(prorated, NA_real_,
                             payroll_usd / (threshold_musd * 1e6))) %>%
  select(-threshold_musd)
write_csv(payrolls, file.path(GEN, "team_payrolls.csv"))

# player primary team per season, from raw stints
bat <- read_csv(file.path(RAW, "war_daily_bat.txt"),
                col_types = cols_only(player_ID = "c", year_ID = "i",
                                      team_ID = "c", PA = "d", pitcher = "c"))
pit <- read_csv(file.path(RAW, "war_daily_pitch.txt"),
                col_types = cols_only(player_ID = "c", year_ID = "i",
                                      team_ID = "c", IPouts = "d"))
teams <- bind_rows(
  bat %>% filter(pitcher == "N") %>%
    transmute(player_ID, year = year_ID, team_raw = team_ID,
              w = PA, class = "pos"),
  pit %>% transmute(player_ID, year = year_ID, team_raw = team_ID,
                    w = IPouts, class = "pit")) %>%
  group_by(player_ID, class, year, team_raw) %>%
  summarise(w = sum(w, na.rm = TRUE), .groups = "drop") %>%
  group_by(player_ID, class, year) %>%
  slice_max(w, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(player_ID, class, year, team = franchise(team_raw))
write_csv(teams, file.path(GEN, "player_teams.csv.gz"))

cat("team payrolls:", nrow(payrolls), "rows (",
    min(payrolls$year), "-", max(payrolls$year),
    ") | player-team map:", nrow(teams), "rows\n")