# v2 — couldabeens, next level (2026)

Extension of the 2020 Math 243 project: reproducible ingest through the 2025
season, hardened statistics, and a player-level survival design. The original
report and pipeline at the repo root are frozen as the v1 deliverable.

## Pipeline

Run from the repo root, in order:

```
Rscript v2/ingest/01-fetch-war.R          # B-R raw WAR files (snapshots committed)
Rscript v2/ingest/02-build-panels.R       # player-season panel, rookies, retirees
Rscript v2/ingest/03-build-couldabeens.R  # yearly couldabeen series, 3 classifiers
Rscript v2/ingest/04-payroll-tax.R        # CBT thresholds + labor share to 2025
Rscript v2/ingest/05-validate-v1.R        # reconciliation against the v1 series
```

Everything under `v2/data-gen/` is regenerable from the committed snapshots in
`v2/data/raw/` — unlike v1, every derived file has a committed writer.

## Populations and classifiers

The **primary population** mirrors v1's implicit Stathead filters, recovered
during reconciliation from the v1 CSVs themselves: rookie seasons are official
rookie-*status* seasons (first qualifying season while still rookie-eligible),
and both rookies and retirees must qualify with **G ≥ 30** (position players)
or **IP ≥ 50** (pitchers). A **full population** (all debuts, all final
seasons) is kept as a sensitivity series.

Classifiers per year and class (pos/pit classified separately, then combined):

| series | rule |
|---|---|
| `prop_raw` | final-season WAR ≥ mean rookie WAR (v1 definition) |
| `prop_rate` | WAR per 600 PA / 180 IP ≥ mean rookie rate |
| `prop_peak3` | best WAR of final 3 seasons ≥ raw threshold |

## v1 reconciliation (2026-07-12)

Over the 50 overlap years (1969–2018), the v2 primary `prop_raw` series vs
v1's committed `couldabeens_t.csv`: **correlation 0.876, mean |diff| 0.024,
mean bias −0.006**. Exact equality is impossible: Baseball-Reference has
recalculated WAR since the 2020 pull, Stathead's rookie query uses the 45-day
roster criterion (not observable in the WAR files), and Stathead's retiree
lists appear to exclude players who kept playing outside MLB. A naive
first-appearance/all-retirees rebuild correlates at only 0.43 — the recovered
G/IP filters are what make the series comparable.

## Data notes

- Raw WAR snapshots: `v2/data/raw/*.txt.gz` + `manifest.csv` (md5, coverage);
  the uncompressed files are gitignored and restored by step 01.
- Retiree cohorts stop one year before the in-progress season; the newest
  cohort is flagged `provisional` (mid-career players can still return).
- 2020 (COVID, 60 games): WAR-based classification is within-year consistent,
  but the season is excluded from labor-share models (revenue estimates vary
  $3.4–4.0B; payroll was prorated). Flagged in `laborshare_v2.csv`.
- League payroll 2021–2025 comes from Spotrac season averages ×30 (captured
  2026-07-12); its 2019 total runs +3.7% vs the v1 hand-collected series —
  carry a source dummy when modeling across the splice.
- CBT thresholds 2003–2026 verified against the MLB.com glossary.
