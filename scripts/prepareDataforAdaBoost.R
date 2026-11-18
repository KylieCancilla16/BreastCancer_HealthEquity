library(tidyverse)

full <- read_csv("clean_data.csv") %>%
  select(-patient_id, -patient_zip3, -Division, -aq_imputed, -aq_source,
         -female, -income_household_six_figure, -education_college_or_above, -patient_state) %>%
  filter(complete.cases(.)) %>%
  mutate(across(c(patient_race, payer_type, Region,
                  breast_cancer_diagnosis_code, metastatic_cancer_diagnosis_code),
                as.factor))

main <- full %>%
  filter(!str_detect(breast_cancer_diagnosis_code, "^17")) %>%
  droplevels()

glimpse(main)
table(main$DiagPeriodL90D)
table(full$DiagPeriodL90D)

saveRDS(list(main = main, full = full), "adaboost_data.rds")