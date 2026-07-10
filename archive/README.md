# Archive

Superseded drafts and abandoned explorations, kept for the record. Everything
here is frozen: relative paths inside these notebooks still assume the
pre-refactor layout (e.g. `../R/header_D.R`, since unified into
`R/header.R`), and several source an `R/null_threshold.R` that was never
committed — so most of them no longer knit as-is.

## Analysis that exists nowhere else

Four legacy notebooks hold abandoned branches whose work never made it into
the final report; they are the only record of it:

- `legacy/Rearranged-data.Rmd` — regression **tree** on WAR
  (`tree`/`cv.tree`/`prune.tree`).
- `legacy/supplementary.Rmd` — **predictive WAR** multiple regression with a
  train/test split and test MSE.
- `legacy/modeling_v1.Rmd` — **PCA** (`prcomp`) on the couldabeens data.
- `legacy/modeling.Rmd` — the **logistic-classification** approach; also the
  writer of `legacy/pit_ret_classified.csv` / `pos_ret_classified.csv`
  (read only by the legacy report/presentation drafts).

## Contents

- `legacy/` — the draft lineage of the final report and presentation
  (`modeling_v1/v2`, `modeling_subsets`, `smoothing`, early `report.Rmd` and
  `presentation.Rmd`, EDA in `data_analysis.Rmd`) plus the two legacy-only
  generated CSVs noted above.
- `drafts/` — superseded standalone notebooks: `model.Rmd`/`model.pdf`
  (modeling narrative folded into the final report), `smoothing.Rmd`
  (threshold smoothing — abandoned; its helpers survive, commented out, in
  `R/threshold.R`), `data_analysis.pdf` (render of the early EDA; its source
  is `legacy/data_analysis.Rmd`), and `coef.jpeg` (unused figure).
- `outdated-data/` — earlier scrapes superseded by `data/`
  (`_retirees-*`, `_w_retirees-*`, `old-revenue-payroll.csv`,
  `total_retirees.csv`) and two 200-row early sample pulls
  (`rookies-pitchers.csv` — mislabeled: it actually holds position-player
  columns — and `rookies-positions.csv`).
- `esports/` — the abandoned first project idea (e-sports earnings
  proposal), fully self-contained.
