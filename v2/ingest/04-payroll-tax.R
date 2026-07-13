# v2 ingest step 4: CBT threshold schedule + extended labor-share table.
# Run from the repo root:  Rscript v2/ingest/04-payroll-tax.R
#
# Hand-assembled reference data, verified 2026-07-12:
#   - CBT thresholds 2003-2026: MLB.com CBT glossary + Wikipedia
#     (https://www.mlb.com/glossary/transactions/competitive-balance-tax).
#     The 1997-1999 first-regime tax (top-5 payroll midpoint mechanism) is
#     deliberately omitted: no fixed threshold existed.
#   - Revenue 2021-2024: Forbes (Maury Brown) annual reports; 2025 is the
#     ~$12.5B industry estimate pending the January 2027 Forbes figure.
#     2020 is left NA: COVID estimates range $3.4-4.0B and the season is
#     excluded from labor-share models regardless.
#   - League payroll 2021-2025: Spotrac payroll tracker season averages x 30
#     (captured 2026-07-12). Definitional splice: Spotrac's 2019 total is
#     $4.158B vs $4.008B in the v1 hand-collected series (+3.7%); the source
#     column lets models carry a splice dummy.

suppressMessages(library(tidyverse))
GEN <- "v2/data-gen"

cbt <- tribble(
  ~year, ~threshold_musd,
  2003, 117.0,  2004, 120.5,  2005, 128.0,  2006, 136.5,
  2007, 148.0,  2008, 155.0,  2009, 162.0,  2010, 170.0,
  2011, 178.0,  2012, 178.0,  2013, 178.0,  2014, 189.0,
  2015, 189.0,  2016, 189.0,  2017, 195.0,  2018, 197.0,
  2019, 206.0,  2020, 208.0,  2021, 210.0,  2022, 230.0,
  2023, 233.0,  2024, 237.0,  2025, 241.0,  2026, 244.0)
write_csv(cbt, file.path(GEN, "cbt_thresholds.csv"))

v1 <- read_csv("data/revenue-payroll.csv", show_col_types = FALSE) %>%
  rename(year = Year, revenue_musd = `Total Revenue (Millions of $)`,
         payroll_usd = `Total Payroll`) %>%
  mutate(source = "v1-hand-collected", note = NA_character_)

ext <- tribble(
  ~year, ~revenue_musd, ~payroll_usd, ~note,
  2020, NA,    NA,          "COVID 60-game season; revenue estimates 3400-4000, prorated pay; exclude",
  2021, 9560,  3938603790,  "attendance-restricted season",
  2022, 10800, 4506970470,  NA,
  2023, 11600, 4987765380,  NA,
  2024, 12100, 5099101800,  NA,
  2025, 12500, 5281263090,  "revenue is pre-Forbes industry estimate") %>%
  mutate(source = "forbes+spotrac-2026-07-12")

laborshare <- bind_rows(v1, ext) %>%
  arrange(year) %>%
  mutate(labShare = payroll_usd / (revenue_musd * 1e6))
write_csv(laborshare, file.path(GEN, "laborshare_v2.csv"))

cat("cbt_thresholds:", nrow(cbt), "rows | laborshare:", nrow(laborshare),
    "rows (", min(laborshare$year), "-", max(laborshare$year), ")\n")
print(as.data.frame(tail(laborshare, 7)), digits = 3)
