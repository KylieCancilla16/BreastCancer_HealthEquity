library(tidyverse)    

df <- read_csv("source_data.csv", col_types = cols(.default=col_guess(),
                                                                   metastatic_first_novel_treatment = col_character(),
                                                                   metastatic_first_novel_treatment_type = col_character()))
df <- df |>
  mutate(across(c(N02, Ozone, PM25), ~ as.numeric(na_if(.x, "#N/A"))))

missing_summary <- df %>%
  summarise(across(everything(), ~ mean(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "pct_missing") %>%
  arrange(desc(pct_missing))

df <- df %>% select(-metastatic_first_novel_treatment)
df <- df %>% select(-metastatic_first_novel_treatment_type)

tn <- df |>
  filter(patient_state == "TN") |>
  summarise(across(c(N02, Ozone, PM25), ~mean(.x, na.rm = TRUE)))

aq_fill <- tribble(
  ~patient_state, ~PM25_fill, ~Ozone_fill, ~N02_fill, ~fill_source,
  "HI",   4.23,       27.5,        2.6,       "HI DOH 2024 annual report (Oahu SLAMS)",
  "AK",   1.34,       36.78,       22.26,     "AK DEC Chickaloon sensor, winter 2024-25",
  "TN",   tn$PM25,    tn$Ozone,    tn$N02,    "TN state mean"
)

df <- df |>
  left_join(aq_fill, by = "patient_state") |>
  mutate(
    aq_imputed = is.na(PM25) & !is.na(PM25_fill),
    aq_source  = if_else(aq_imputed, fill_source, "original"),
    PM25  = coalesce(PM25,  PM25_fill),
    Ozone = coalesce(Ozone, Ozone_fill),
    N02   = coalesce(N02,   N02_fill)
  ) |>
  select(-ends_with("_fill"), -fill_source)


cat_vars <- c("patient_race", "payer_type", "patient_state", "Region", "Division",
              "breast_cancer_diagnosis_code", "metastatic_cancer_diagnosis_code")

clean <- df %>%
  select(-any_of(c(
    "patient_gender",
    "breast_cancer_diagnosis_desc",
    "metastatic_first_novel_treatment",
    "metastatic_first_novel_treatment_type"
  ))) %>%
  mutate(
    payer_type = case_when(
      str_detect(str_to_upper(payer_type), "MEDICAID")   ~ "Medicaid",
      str_detect(str_to_upper(payer_type), "COMMERCIAL") ~ "Commercial",
      str_detect(str_to_upper(payer_type), "MEDICARE")   ~ "Medicare",
      TRUE                                               ~ NA_character_
    ),
    across(all_of(cat_vars), ~ factor(replace_na(as.character(.), "Unknown"))),
    breast_cancer_diagnosis_code     = fct_lump_min(breast_cancer_diagnosis_code,
                                                    min = 20, other_level = "Other"),
    metastatic_cancer_diagnosis_code = fct_lump_min(metastatic_cancer_diagnosis_code,
                                                    min = 20, other_level = "Other"),
    bmi_missing = as.integer(is.na(bmi))
  ) %>%
  mutate(across(where(is.numeric) & !any_of(c("patient_id", "DiagPeriodL90D")),
                ~ replace_na(., median(., na.rm = TRUE)))) %>%
  mutate(across(where(is.character), ~ replace_na(., "Unknown")))


na_counts <- colSums(is.na(clean))

stopifnot(!anyNA(clean))

write_csv(clean, "clean_data.csv")
