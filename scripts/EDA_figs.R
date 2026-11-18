library(tidyverse)
library(gridExtra)

pdf(NULL)
dir.create("figures", showWarnings = FALSE)

eda <- read_csv("clean_data.csv") %>%
  mutate(outcome = factor(DiagPeriodL90D, levels = c(0, 1),
                          labels = c("More than 90 days", "Within 90 days")))

outcome_cols <- c("More than 90 days" = "tomato", "Within 90 days" = "steelblue")
overall_rate <- mean(eda$DiagPeriodL90D)

rate_plot <- function(data, var, title) {
  data %>%
    group_by(.data[[var]]) %>%
    summarise(n = n(), rate = mean(DiagPeriodL90D), .groups = "drop") %>%
    ggplot(aes(x = rate, y = reorder(.data[[var]], rate))) +
    geom_col(fill = "steelblue") +
    geom_vline(xintercept = overall_rate, linetype = 2) +
    geom_text(aes(label = paste0(scales::percent(rate, accuracy = 1), " (n=", n, ")")),
              hjust = -0.1, size = 3) +
    scale_x_continuous(labels = scales::percent, limits = c(0, 1.3),
                       breaks = seq(0, 1, 0.25)) +
    labs(title = title, x = "% diagnosed within 90 days", y = NULL) +
    theme_minimal()
}

p_outcome <- ggplot(eda, aes(x = outcome, fill = outcome)) +
  geom_bar() +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  scale_fill_manual(values = outcome_cols) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(title = "A. Patients by diagnosis period", x = NULL, y = "Patients") +
  theme_minimal() +
  theme(legend.position = "none")

p_age <- eda %>%
  mutate(age_group = cut(patient_age, breaks = c(17, 39, 49, 59, 69, 79, Inf),
                         labels = c("18-39", "40-49", "50-59", "60-69", "70-79", "80+"))) %>%
  group_by(age_group) %>%
  summarise(n = n(), rate = mean(DiagPeriodL90D), se = sqrt(rate * (1 - rate) / n)) %>%
  ggplot(aes(x = age_group, y = rate, group = 1)) +
  geom_hline(yintercept = overall_rate, linetype = 2, color = "grey50") +
  geom_line(color = "steelblue") +
  geom_errorbar(aes(ymin = rate - 1.96 * se, ymax = rate + 1.96 * se), width = 0.15, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  geom_text(aes(label = paste0("n=", n), y = rate + 1.96 * se), vjust = -0.6, size = 3) +
  scale_y_continuous(labels = scales::percent) +
  labs(title = "B. Diagnosed within 90 days by age group",
       x = "Patient age", y = "% diagnosed within 90 days") +
  theme_minimal()

p_payer <- rate_plot(eda, "payer_type", "C. Insurance type")

p_race <- rate_plot(eda, "patient_race", "D. Patient race")

top_states <- eda %>%
  count(patient_state, sort = TRUE) %>%
  slice_head(n = 10) %>%
  pull(patient_state)

p_state <- rate_plot(filter(eda, patient_state %in% top_states), "patient_state",
                     "E. 10 states with the most patients")

top_mets <- eda %>%
  count(metastatic_cancer_diagnosis_code, sort = TRUE) %>%
  slice_head(n = 10) %>%
  pull(metastatic_cancer_diagnosis_code)

p_met <- rate_plot(filter(eda, metastatic_cancer_diagnosis_code %in% top_mets),
                   "metastatic_cancer_diagnosis_code", "F. 10 most common metastatic codes")

eda_grid <- arrangeGrob(p_outcome, p_age, p_payer, p_race, p_state, p_met, ncol = 2)
ggsave("figures/EDA_fig.png", eda_grid, width = 12, height = 14, dpi = 300)