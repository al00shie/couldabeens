#========================#
#       The Models       #
#========================#

# Hypothesis Test
ht <- lm(prop ~ postMoneyball, data = couldabeens_t)

# Linear Models
lm1 <- lm(prop ~ Year, data = couldabeens_t)
lm2 <- lm(prop ~ Year, data = couldabeens_pre)
lm3 <- lm(prop ~ Year, data = couldabeens_post)
lm4 <- lm(prop ~ labShare, data = couldabeens_post)

#======================================#
#       Couldabeen Density Plots       #
#======================================#
# Set colors
col1 <- "salmon"   # Retirees
col2 <- "skyblue3" # Rookies
col3 <- "violet"
# Set color parameters
colors_density <- c("Retirees" = col1, "Rookies" = col2)
# Density plot of rookie and retired pitchers 
dens_pit <- ggplot() +
  geom_density(data = pit_ret, aes(x = WAR, color = "Retirees")) +
  geom_density(data = pit_rkes, aes(x = WAR, color = "Rookies")) +
  geom_vline(xintercept = mean(pit_rkes$WAR), color = col2) +
  labs(title = "Pitchers") +
  theme(legend.position = 'right') +
  scale_color_manual("Player",values = colors_density) 
# Density plot of rookie position players and retired position players 
dens_pos <- ggplot() +
  geom_density(data = pos_ret, aes(x = WAR, color = "Retirees")) +
  geom_density(data = pos_rkes, aes(x = WAR, color = "Rookies")) +
  geom_vline(xintercept = mean(pos_rkes$WAR), color = col2) +
  labs(title = "Position") +
  theme(legend.position = 'right') +
  scale_color_manual("Player",values = colors_density) 

#================================================
#         Payroll Predictor Visualization 
#================================================

plotpred1 <- ggplot() + geom_point(data = payroll, mapping = aes(x = totRev, y = labShare, color = Year))
plotpred2 <- ggplot() + geom_point(data = payroll, mapping = aes(x = totRev, y = totPayroll, color = Year))
plotpred3 <- ggplot() + geom_point(data = payroll, mapping = aes(x = totPayroll, y = labShare, color = Year))

#================================================
#         Coefficients for Linear Models 
#================================================

# Obtain linear model for all years
coefs_comp <- lm(formula = prop ~ I(Year), data = couldabeens_t)$coefficients
coefs_post <- lm(formula = prop ~ I(Year), data = couldabeens_post)$coefficients
coefs_pre <- lm(formula = prop ~ I(Year), data = couldabeens_pre)$coefficients

#===========================================
#       Proportion-Year Linear Model
#===========================================

col <- "mediumvioletred"
col1 <- "salmon"
col2 <- "forestgreen"
# Plot proportion of couldabeens in post-rule era ()
plot_lm1 <- scatter_props(couldabeens_t) +
  geom_abline(slope = coefs_comp[2], intercept = coefs_comp[1], color = col) + 
  geom_point(data = couldabeens_pre, mapping = aes(x = Year, y = prop), color = col) +
  geom_point(data = couldabeens_post, mapping = aes(x = Year, y = prop),color = col)

#=============================================
#          Hypothesis Test Boxplot
#=============================================

ht_plot <- ggplot(data = couldabeens_t, mapping = aes(x = as.factor(postMoneyball), y = prop)) +
  geom_boxplot() +
  coord_flip() + 
  annotate(geom="text", y=0.25, x=0.8,label="pre-Moneyball") + 
  annotate(geom="text", y=0.25, x=2,label="post-Moneyball") +
  labs(x = "postMoneyball", title = "Proportion of Couldabeen Retirees by Era")

#=============================================
#          Year Linear Model (Pre)
#=============================================

plot_lm2 <- ggplot(data = couldabeens_pre, mapping = aes(y = prop, x = Year)) + 
  geom_point(color = col1) +
  geom_smooth(color = col1, se = F, method = "lm")


#=============================================
#          Year Linear Model (Post)
#=============================================

plot_lm3 <- ggplot(data = couldabeens_post, mapping = aes(y = prop, x = Year)) + 
  geom_point(color = col2) +
  geom_smooth(color = col2, se = F, method = "lm")

#=============================================
#       Labor Share Linear Model (Post)
#=============================================

plot_lm4 <- ggplot(data = couldabeens_post, mapping = aes(y = prop, x = labShare)) + 
  geom_point(color = col1) +
  geom_smooth(color = col1, se = F, method = "lm")

#=====================================
#       Simpson's Paradox Plot
#=====================================

# Plot proportion of couldabeens in post-rule era ()
plot_simpsons <- scatter_props(couldabeens, title = "") +
  geom_abline(slope = coefs_comp[2], intercept = coefs_comp[1], color = "violet") + 
  geom_point(data = couldabeens_pre, mapping = aes(x = Year, y = prop), color = col1) +
  geom_abline(slope = coefs_pre[2], intercept = coefs_pre[1], color = col1) +
  geom_point(data = couldabeens_post, mapping = aes(x = Year, y = prop),color = col2) +
  geom_abline(slope = coefs_post[2], intercept = coefs_post[1], color = col2) + 
  labs(y = "Proportion")

#=====================================
#       Labor Share Year Plot
#=====================================

scatter_labShare <- ggplot(data = payroll, mapping = aes(x = Year, y = labShare)) + 
  geom_point(color = col3) +
  geom_smooth(se = F, method = "lm", color = col3)

#=======================================
#       Labor Share Proportion Plot
#=======================================

col2 <- "skyblue3"
plot_labShare <- ggplot(data = couldabeens_post, mapping = aes(y = prop, x = labShare)) + 
  geom_point(color = col2) +
  geom_smooth(color = col2, se = F, method = "lm")

#=======================================
#       Threshold Analysis Results
#=======================================

# Split arrays
coef_arrayYR <- coef_array[which(coef_array$model == "year"),]
coef_arrayLB <- coef_array %>% anti_join(coef_arrayYR)

# Choose colors
col1 <- 'violet'
col2 <- 'deepskyblue2'
col_crit <- "red"

# Plot the coefficients against the varying thresholds
coef_plotYR <- ggplot(data = coef_arrayYR) + 
  geom_smooth(mapping = aes(x = threshold, y = coef), color = col1, se = F) +
  geom_point(mapping = aes(x = threshold, y = coef), color = col1) +
  labs(title = "Coefficients of the Year Parameter versus Threshold") +
  geom_vline(xintercept = 0, color = col_crit) +
  geom_vline(xintercept = 1, color = col_crit)

coef_plotLB <- ggplot(data = coef_arrayLB) + 
  geom_smooth(mapping = aes(x = threshold, y = coef), color = col2, se = F) +
  geom_point(mapping = aes(x = threshold, y = coef), color = col2) +
  labs(title = "Coefficients of the Labor Share Parameter versus Threshold") +
  geom_vline(xintercept = 0, color = col_crit) +
  geom_vline(xintercept = 1, color = col_crit)

#==================================
#       Resampling Results
#==================================

boot_YR <- read.csv(file = file.path(ROOT, "data-gen/boot_YR.csv"))
boot_LB <- read.csv(file = file.path(ROOT, "data-gen/boot_LB.csv"))

# Histogram of bootstrapped coef_yr
BOOT_coefYR <- ggplot() + 
  geom_histogram(data = boot_YR, aes(x=x), color = col1, fill = col1) +
  labs(title = "Bootstraped Coefficient of the Year Parameter")+
  geom_vline(xintercept = mean(boot_YR$x), color = "red")

# Histogram of bootstrapped coef_LS
BOOT_coefLB <- ggplot() + 
  geom_histogram(data = boot_LB, aes(x=x), color = col2, fill = col2) +
  labs(title = "Bootstraped Coefficient of the Labor Share Parameter") +
  geom_vline(xintercept = mean(boot_LB$x), color = "navy")

