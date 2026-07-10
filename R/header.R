#============================#
#       Import Scripts       #
#============================#
# ROOT points at the repo root. Rmds knit from the root (report.Rmd,
# presentation.Rmd) can source this file directly; notebooks knit from a
# subdirectory (analysis/) set ROOT <- ".." before sourcing it.
if (!exists("ROOT")) ROOT <- "."
source(file = file.path(ROOT, "R/wrangle.R"))
source(file = file.path(ROOT, "R/model.R"))
source(file = file.path(ROOT, "R/visualization.R"))
source(file = file.path(ROOT, "R/threshold.R"))

#=============================#
#       Import Datasets       #
#=============================#
# Load rookies datasets
pit_rkes <- read_csv(file.path(ROOT, "data/rookie-pitcher.csv"))
pos_rkes <- read_csv(file.path(ROOT, "data/rookie-position.csv"))
# Load retirees datasets
pit_ret <- read_csv(file.path(ROOT, "data/retirees-pitcher.csv"))
pos_ret <- read_csv(file.path(ROOT, "data/retirees-position.csv"))
# Find number of retirees by year
num_retirees <- total_retirees_by_yr(pit_ret, pos_ret)
num_retirees <- data.frame(retirees = num_retirees$retirees)
# Aggregate datasets to compute couldabeens
ls_datasets <- list(pos_rkes, pos_ret, pit_rkes, pit_ret, num_retirees)
# Wrangle the datasets
pit_rkes <- wrangle_init(pit_rkes)
pos_rkes <- wrangle_init(pos_rkes)
pit_ret <- wrangle_init(pit_ret)
pos_ret <- wrangle_init(pos_ret)
# Get and wrangle payroll revenue data
payroll <- wrangle_payroll(read_csv(file.path(ROOT, "data/revenue-payroll.csv")))

#=======================================#
#       Obtain Generated Datasets       #
#=======================================#
# Get couldabeens
couldabeens <- read_csv(file.path(ROOT, "data-gen/couldabeens.csv"))
couldabeens_t <- read_csv(file.path(ROOT, "data-gen/couldabeens_t.csv"))
# Split data
couldabeens_pre <- couldabeens_t[which(couldabeens_t$postMoneyball == 0),]
couldabeens_post <- couldabeens_t %>% anti_join(couldabeens_pre)
# Return column with payroll data for years 1968:2018 (NA Data included)
payroll_c <- rbind(data.frame(labShare = couldabeens_pre$labShare), data.frame(labShare = couldabeens_post$labShare))
# Read coefficient array
coef_array <- read_csv(file.path(ROOT, "data-gen/coef_array.csv"))

#====================================#
#       Global Output Settings       #
#====================================#

bplot <- T
bloud <- T
bimage <- T
