# v2 ingest step 1: fetch Baseball-Reference WAR files.
# Run from the repo root:  Rscript v2/ingest/01-fetch-war.R [--refresh]
#
# Sources (full-history, updated daily by B-R):
#   https://www.baseball-reference.com/data/war_daily_bat.txt
#   https://www.baseball-reference.com/data/war_daily_pitch.txt
#
# The committed artifacts are the gzipped snapshots in v2/data/raw/ plus
# manifest.csv (download date, md5, coverage). The unzipped .txt files are
# gitignored; this script restores them from the snapshots when present, so
# the pipeline reproduces offline from the repo alone. --refresh re-downloads
# and overwrites the snapshots.

suppressMessages(library(tidyverse))

RAW   <- "v2/data/raw"
FILES <- c(bat = "war_daily_bat.txt", pitch = "war_daily_pitch.txt")
BASE  <- "https://www.baseball-reference.com/data"
refresh <- "--refresh" %in% commandArgs(trailingOnly = TRUE)

dir.create(RAW, recursive = TRUE, showWarnings = FALSE)

for (f in FILES) {
  txt <- file.path(RAW, f)
  gz  <- paste0(txt, ".gz")
  if (refresh || (!file.exists(txt) && !file.exists(gz))) {
    message("downloading ", f)
    download.file(file.path(BASE, f), txt, quiet = TRUE)
    if (file.exists(gz)) file.remove(gz)
    system2("gzip", c("-k", txt))
  } else if (!file.exists(txt)) {
    message("restoring ", f, " from snapshot")
    system2("gunzip", c("-k", gz))
  } else {
    message(f, " already present")
  }
}

manifest <- map_dfr(FILES, function(f) {
  txt <- file.path(RAW, f)
  yrs <- read_csv(txt, col_select = "year_ID", show_col_types = FALSE)$year_ID
  tibble(file = f,
         url = file.path(BASE, f),
         downloaded = format(file.info(txt)$mtime, "%Y-%m-%d"),
         md5 = unname(tools::md5sum(txt)),
         rows = length(yrs),
         min_year = min(yrs), max_year = max(yrs))
})
write_csv(manifest, file.path(RAW, "manifest.csv"))
print(as.data.frame(manifest))
