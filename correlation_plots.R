library(ggplot2)
library(tidyverse)
library(car)
library(ggplot2)
library(corrplot)
library(GGally)
library(ggplot2)

clean <- read_csv("clean_data.csv")

plot_df <- clean[, c("income_household_median", "home_ownership",
                     "education_bachelors", "health_uninsured")]
plot_df$income_household_median <- plot_df$income_household_median / 1000

names(plot_df) <- c("Median household\nincome ($1,000s)",
                    "Home ownership (%)",
                    "Bachelor's degree (%)",
                    "Uninsured (%)")

economic_var_corrs <- ggpairs(
  plot_df,
  lower = list(continuous = wrap("smooth_loess", alpha = 0.25, size = 0.8,
                                 colour = "grey30")),
  diag  = list(continuous = wrap("densityDiag", fill = "steelblue",
                                 alpha = 0.4)),
  upper = list(continuous = wrap("cor", size = 5, method = "spearman"))
) +
  labs(title = "Pairwise relationships among socioeconomic indicators",
       subtitle = "Lower: scatterplots with loess smoother | Upper: Spearman correlations") +
  theme_bw(base_size = 11) +
  theme(strip.text = element_text(size = 9))

ggsave("Economic_var_corrs.png", economic_var_corrs)

corr_vars <- c("patient_age", "bmi", "age_median", "income_household_median",
               "home_ownership", "education_bachelors", "health_uninsured",
               "poverty", "unemployment_rate", "limited_english",
               "Ozone", "PM25", "N02")

nice_names <- c("Patient age", "BMI", "Median age (area)",
                "Median income", "Home ownership", "Bachelor's degree",
                "Uninsured", "Poverty", "Unemployment", "Limited English",
                "Ozone", "PM2.5", "NO2")

M <- cor(clean[, corr_vars], use = "pairwise.complete.obs", method = "spearman")
dimnames(M) <- list(nice_names, nice_names)

png("corrplot.png", width = 2400, height = 2400, res = 300)
corrplot.mixed(M,
               order = "hclust",
               lower = "number", upper = "circle",
               lower.col = "black", number.cex = 0.55,
               tl.col = "black", tl.pos = "lt", tl.cex = 0.75,
               tl.srt = 45)
dev.off()


nice_names <- c("Patient age", "BMI", "Median age (area)",
                "Median income", "Home ownership", "Bachelor's degree",
                "Uninsured", "Poverty", "Unemployment", "Limited English",
                "Ozone", "PM2.5", "NO2", "Diagnosed ≤ 90 days")
corr_vars <- c("patient_age", "bmi", "age_median", "income_household_median",
               "home_ownership", "education_bachelors", "health_uninsured",
               "poverty", "unemployment_rate", "limited_english",
               "Ozone", "PM25", "N02", "DiagPeriodL90D")

M <- cor(clean[, corr_vars], use = "pairwise.complete.obs", method = "spearman")

outcome_cor <- data.frame(
  variable = nice_names[-length(nice_names)],
  r = M[-nrow(M), ncol(M)]
)

outcome_corrs <- ggplot(outcome_cor, aes(x = r, y = reorder(variable, r), fill = r > 0)) +
  geom_col(show.legend = FALSE) +
  geom_vline(xintercept = 0) +
  scale_fill_manual(values = c("firebrick", "steelblue")) +
  labs(x = "Spearman correlation with timely diagnosis", y = NULL,
       title = "Which variables relate to diagnosis within 90 days?") +
  theme_bw()

ggsave("OutcomeCorrelations.png", outcome_corrs)
