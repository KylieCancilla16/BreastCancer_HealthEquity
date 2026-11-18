library(tidyverse)
library(gridExtra)

pdf(NULL)
dir.create("figures", showWarnings = FALSE)

d <- read_csv("clean_data.csv") %>%
  filter(breast_cancer_diagnosis_code != "Other") %>%
  mutate(icd_version = if_else(str_detect(breast_cancer_diagnosis_code, "^17"),
                               "ICD-9 (before Oct 2015)", "ICD-10 (Oct 2015 or later)"))

d %>%
  group_by(icd_version) %>%
  summarise(n = n(),
            pct_within_90 = mean(DiagPeriodL90D),
            mean_age = mean(patient_age),
            pct_bmi_missing = mean(bmi_missing))

by_code <- d %>%
  group_by(breast_cancer_diagnosis_code, icd_version) %>%
  summarise(n = n(), rate = mean(DiagPeriodL90D), .groups = "drop") %>%
  filter(n >= 20)

p1 <- ggplot(by_code, aes(x = rate, y = reorder(breast_cancer_diagnosis_code, rate), fill = icd_version)) +
  geom_col() +
  geom_text(aes(label = paste0("n=", n)), hjust = -0.1, size = 2.8) +
  scale_x_continuous(labels = scales::percent, limits = c(0, 1)) +
  scale_fill_manual(values = c("steelblue", "tomato")) +
  labs(title = "Diagnosed within 90 days, by breast cancer code",
       subtitle = "Codes with at least 20 patients",
       x = "% with metastatic diagnosis within 90 days", y = NULL, fill = NULL) +
  theme_minimal() +
  theme(legend.position = "bottom")

p2 <- ggplot(by_code, aes(x = 1 - rate, y = reorder(breast_cancer_diagnosis_code, 1 - rate), fill = icd_version)) +
  geom_col() +
  geom_text(aes(label = paste0("n=", n)), hjust = -0.1, size = 2.8) +
  scale_x_continuous(labels = scales::percent, limits = c(0, 1)) +
  scale_fill_manual(values = c("steelblue", "tomato")) +
  labs(title = "Diagnosed longer than 90 days, by breast cancer code",
       subtitle = "Codes with at least 20 patients",
       x = "% with metastatic diagnosis after 90 days", y = NULL, fill = NULL) +
  theme_minimal() +
  theme(legend.position = "bottom")

combined <- arrangeGrob(p1, p2, ncol = 2)
ggsave("figures/icd_outcome_side_by_side.png", combined, width = 14, height = 7, dpi = 300)