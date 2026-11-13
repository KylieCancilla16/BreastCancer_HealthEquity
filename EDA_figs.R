library(ggplot2)
library(tidyverse)
library(car)
library(ggplot2)
library(corrplot)
library(GGally)
library(ggplot2)

df <- read_csv("clean_data.csv")
dir.create("figures", showWarnings = FALSE, recursive = TRUE)

eda <- df %>%
  mutate(DiagPeriodL90D = factor(DiagPeriodL90D, levels = c(0, 1)))

outcome_labels <- c(`0` = "DiagPeriodL90D = 0 (more than 90 days)",
                    `1` = "DiagPeriodL90D = 1 (within 90 days)")

p_outcome <- ggplot(eda, aes(x = DiagPeriodL90D, fill = DiagPeriodL90D)) +
  geom_bar() +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  scale_x_discrete(labels = c(`0` = "More than 90 days (0)",
                              `1` = "Within 90 days (1)")) +
  labs(title = "Patients by Diagnosis Period",
       x = "DiagPeriodL90D", y = "Number of patients") +
  theme_minimal()

  theme(legend.position = "none")

ggsave("figures/DiagnosisPeriodDensity_fig.png", p_outcome)

age_centers <- eda %>%
  group_by(DiagPeriodL90D) %>%
  summarise(mean_age = mean(patient_age))

p_age <- ggplot(eda, aes(x = patient_age, color = DiagPeriodL90D)) +
  geom_density(linewidth = 1) +
  geom_vline(data = age_centers,
             aes(xintercept = mean_age, color = DiagPeriodL90D),
             linetype = 2, linewidth = 0.8) +
  facet_wrap(~ DiagPeriodL90D, labeller = as_labeller(outcome_labels)) +
  labs(title = "Mean Age of Patient's by Diagnosis Period",
       subtitle = "Dashed line = group mean",
       x = "Median age", y = "Density") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("figures/Age_fig.png", p_age)


sum(eda$payer_type == "Unknown")

payer_plot_df <- eda %>%
  filter(payer_type != "Unknown") %>%
  mutate(payer_type = factor(payer_type, levels = c("Medicaid", "Commercial", "Medicare")))

payer_pct <- payer_plot_df %>%
  count(DiagPeriodL90D, payer_type) %>%
  group_by(DiagPeriodL90D) %>%
  mutate(pct = n / sum(n)) %>%
  ungroup()

p_payer <- ggplot(payer_pct, aes(x = payer_type, y = pct, fill = payer_type)) +
  geom_col() +
  geom_text(aes(label = scales::percent(pct, accuracy = 0.1)),
            vjust = -0.4, size = 3.5) +
  facet_wrap(~ DiagPeriodL90D, labeller = as_labeller(outcome_labels)) +
  scale_y_continuous(labels = scales::percent,
                     expand = expansion(mult = c(0, 0.08))) +
  labs(title = "Insurance Type by Diagnosis Period",
       x = "Insurance type", y = "Percent of patients") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("figures/PayerTypeFig.png", p_payer)

