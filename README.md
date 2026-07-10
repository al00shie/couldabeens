# Couldabeens: Effects of the MLB Luxury Tax on Early Retirement

Final project for Math 243 (Statistical Learning) at Reed College, Fall 2020.
Authors: Grant Dunlavey, William Ren, Ali Taqi.

**Deliverables:** [`report.pdf`](report.pdf) (technical report), [`presentation.pdf`](presentation.pdf) (slides), [`proposal.pdf`](proposal.pdf) (project proposal).

## Abstract

Major League Baseball's "competitive balance tax," first implemented in 2002, has become a favorite subject of outrage among players and fans alike in recent years. On paper, the policy was meant to make the sport more competitive and boost salaries for players on lower-revenue teams. Any team that wanted to spend beyond that cap would pay a "tax" (a share of their excess payroll) to be redistributed to the poorer teams. In practice the policy has effectively become a salary cap. In conjunction with research from Bradbury, this paper seeks to methodically explore the rates of lost potential players — premature retirees, or "couldabeens" — along the years, in addition to labor share as a predictor.

## Repository layout

| Path | Contents |
|---|---|
| `report.Rmd`, `presentation.Rmd`, `proposal.Rmd` | Sources of the three deliverable PDFs; knit from the repo root |
| `R/` | Shared code. `header.R` sources the four function libraries (`wrangle.R`, `model.R`, `visualization.R`, `threshold.R`) and loads every dataset; `report.R` / `presentation.R` build the models and plots each deliverable renders |
| `analysis/` | Runnable generators: `resampling.Rmd` (bootstrap distributions of the model coefficients), `threshold.Rmd` (couldabeen stack + coefficient array under a varying classification threshold) |
| `data/` | Hand-collected source data (Stathead/Baseball-Reference player exports; revenue & payroll tables). Not regenerable — treat as read-only |
| `data-gen/` | Generated datasets consumed by the pipeline (provenance below) |
| `images/` | Static figures used by the presentation |
| `archive/` | Superseded drafts and abandoned explorations — see [`archive/README.md`](archive/README.md) |

## Reproducing

Knit the deliverables from the repo root (paths in `R/header.R` resolve
against the working directory; `ROOT` defaults to `.`):

```r
rmarkdown::render("report.Rmd")
rmarkdown::render("presentation.Rmd")
```

The notebooks in `analysis/` knit with their own directory as the working
directory and set `ROOT <- ".."` before sourcing the header.

Requires R (tested with 4.4) with `tidyverse`, `knitr`, `gridExtra`,
`patchwork`, `moderndive`, `ggrepel`, and `ISLR`, plus a LaTeX distribution
for the PDF output (the presentation uses beamer).

## Data provenance

- **`data/`** — source of truth, collected by hand in 2020: the four player
  tables (`rookie-*`, `retirees-*`), `revenue-payroll.csv` (drives the
  labor-share variable), and `payroll.csv` (a fuller salary table kept for
  reference; not read by any script).
- **`data-gen/couldabeens.csv`, `couldabeens_t.csv`** — the classified
  couldabeen counts the report reads. Derived from `data/` interactively in
  2020; no committed script rewrites them, so treat them as source-tier.
- **`data-gen/boot_{YR,LB}{1,2,3}.csv`** — bootstrap generations written by
  `analysis/resampling.Rmd` (100 resamples each). `boot_YR.csv` and
  `boot_LB.csv` are the row-concatenations of generations 1–3 and are what
  the report's resampling histograms read.
- **`data-gen/stack.csv`, `coef_array.csv`** — written by
  `analysis/threshold.Rmd` (set `run_stack <- T` to regenerate; the default
  `F` reads the committed copies).
