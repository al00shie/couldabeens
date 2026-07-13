# Polished standalone figure: era-split sensitivity of the couldabeen trend
# to the WAR classification threshold.
# Run from the repo root:  Rscript analysis/figures/make-era-plot.R
suppressMessages(library(tidyverse))

ROOT <- "."
source(file.path(ROOT, "R/header.R"))
stack <- read_csv(file.path(ROOT, "data-gen/stack.csv"), show_col_types = FALSE)
coef_era <- coefs_by_stack_era(stack) %>%
  mutate(era = factor(era, levels = c("pre", "post"),
                      labels = c("Pre-tax era (1969-2002)",
                                 "Post-tax era (2003-2018)")))

# Categorical slots 1-2 (CVD-validated) + chart ink/chrome
col_pre   <- "#2a78d6"
col_post  <- "#1baf7a"
ink_1     <- "#0b0b0b"
ink_2     <- "#52514e"
ink_muted <- "#898781"
grid_col  <- "#e1e0d9"
base_col  <- "#c3c2b7"
surface   <- "#fcfcfb"

p <- ggplot(coef_era, aes(threshold, coef_yr, color = era)) +
  geom_hline(yintercept = 0, color = base_col, linewidth = 0.4) +
  geom_vline(xintercept = 0, color = ink_muted, linewidth = 0.35, linetype = "22") +
  geom_point(size = 1.6, alpha = 0.5, stroke = 0) +
  geom_smooth(se = FALSE, linewidth = 1, method = "loess", formula = y ~ x) +
  annotate("text", x = 0.07, y = 0.0072, label = "Report's headline threshold\n(mean rookie WAR)",
           family = "Helvetica", size = 2.9, color = ink_muted, hjust = 0, lineheight = 1.05) +
  annotate("text", x = 0.32, y = 0.0044, label = "Pre-tax era",
           family = "Helvetica", size = 3.3, fontface = "bold", color = ink_1, hjust = 0) +
  annotate("text", x = -1.62, y = 0.0019, label = "Post-tax era",
           family = "Helvetica", size = 3.3, fontface = "bold", color = ink_1, hjust = 0) +
  scale_color_manual(values = c(col_pre, col_post)) +
  scale_x_continuous(breaks = -2:2) +
  scale_y_continuous(breaks = seq(-0.002, 0.008, by = 0.002),
                     labels = scales::label_number(accuracy = 0.001)) +
  labs(
    title = "Couldabeens Rose Faster in the Pre-Tax Era Across Most Classification Thresholds",
    subtitle = paste0(
      "Yearly trend in the couldabeen share of retirements (slope of prop ~ Year), refit separately\n",
      "per era at each threshold defining a couldabeen, in SDs of WAR around the mean rookie"),
    x = "Classification threshold (SDs from mean rookie WAR)",
    y = "Trend in couldabeen proportion (slope per season)",
    caption = "Each point: one refit slope | curves: loess | Data: Stathead/Baseball-Reference, 1969-2018 | couldabeens243",
    color = NULL
  ) +
  theme_minimal(base_size = 11, base_family = "Helvetica") +
  theme(
    plot.background = element_rect(fill = surface, color = NA),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = grid_col, linewidth = 0.35),
    axis.title = element_text(color = ink_2, size = 9.5),
    axis.text = element_text(color = ink_muted, size = 8.5),
    plot.title = element_text(color = ink_1, face = "bold", size = 12.5),
    plot.subtitle = element_text(color = ink_2, size = 9.5, lineheight = 1.15,
                                 margin = margin(t = 2, b = 10)),
    plot.caption = element_text(color = ink_muted, size = 7.5, hjust = 0,
                                margin = margin(t = 10)),
    legend.position = "top",
    legend.justification = "left",
    legend.margin = margin(t = 0, b = -4, l = -8),
    legend.text = element_text(color = ink_2, size = 9),
    plot.margin = margin(14, 16, 10, 14)
  ) +
  guides(color = guide_legend(override.aes = list(size = 2.6, alpha = 1)))

ggsave(file.path(ROOT, "analysis/figures/era-threshold-sensitivity.pdf"), p,
       device = cairo_pdf, width = 8, height = 5.2, units = "in")
cat("WROTE: analysis/figures/era-threshold-sensitivity.pdf\n")
