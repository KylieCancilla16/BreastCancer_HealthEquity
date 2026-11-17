library(tidyverse)

d <- read_csv("clean_data.csv") %>%
  select(-patient_id, -patient_zip3, -Division, -aq_imputed, -aq_source,
         -female, -income_household_six_figure, -education_college_or_above) %>%
  filter(complete.cases(.)) %>%
  filter(!str_detect(breast_cancer_diagnosis_code, "^17")) %>%
  mutate(across(c(patient_race, payer_type, patient_state, Region,
                  breast_cancer_diagnosis_code, metastatic_cancer_diagnosis_code),
                as.factor))

glimpse(d)
table(d$DiagPeriodL90D)

saveRDS(d, "adaboost_data.rds")