library(ggplot2)
df <- read_csv("clean_data.csv")

eda <- clean %>%
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

write_csv("DiagnosisPeriodDensity_fig.png", p_outcome)

age_centers <- eda %>%
  group_by(DiagPeriodL90D) %>%
  summarise(mean_age_median = mean(age_median))

p_age <- ggplot(eda, aes(x = age_median, color = DiagPeriodL90D)) +
  geom_density(linewidth = 1) +
  geom_vline(data = age_centers,
             aes(xintercept = mean_age_median, color = DiagPeriodL90D),
             linetype = 2, linewidth = 0.8) +
  facet_wrap(~ DiagPeriodL90D, labeller = as_labeller(outcome_labels)) +
  labs(title = "Median Age of Patient's Zip Code by Diagnosis Period",
       subtitle = "Dashed line = group mean",
       x = "Median age of residents (zip code)", y = "Density") +
  theme_minimal() +
  theme(legend.position = "none")

write_csv("MedianAge_fig.png", p_age)