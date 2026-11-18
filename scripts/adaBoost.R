library(tidyverse)
library(caret)
library(gbm)
library(gridExtra)

pdf(NULL)
set.seed(2026)
dir.create("figures/adaboost", recursive = TRUE, showWarnings = FALSE)

dat <- readRDS("adaboost_data.rds")

d <- dat$main %>%
  select(-breast_cancer_diagnosis_code)

predictors <- setdiff(names(d), "DiagPeriodL90D")

idx <- createDataPartition(d$DiagPeriodL90D, p = 0.8, list = FALSE)
train <- d[idx, ]
test  <- d[-idx, ]

gbm_fit <- gbm(
  formula = DiagPeriodL90D ~ .,
  data = train,
  distribution = "adaboost",
  n.trees = 3000,
  interaction.depth = 3,
  shrinkage = 0.01,
  bag.fraction = 0.8,
  cv.folds = 5,
  train.fraction = 1.0,
  verbose = FALSE
)

best_iter <- gbm.perf(gbm_fit, method = "cv", plot.it = FALSE)
best_iter

vi_tbl <- as_tibble(summary(gbm_fit, n.trees = best_iter, plotit = FALSE)) %>%
  rename(variable = var, rel_influence = rel.inf) %>%
  arrange(desc(rel_influence))
print(vi_tbl, n = 20)

p_vi <- ggplot(head(vi_tbl, 15), aes(x = rel_influence, y = reorder(variable, rel_influence))) +
  geom_col(fill = "steelblue") +
  labs(title = "Relative influence (top 15)", x = "Relative influence (%)", y = NULL) +
  theme_minimal()
ggsave("figures/adaboost/variable_importance.png", p_vi, width = 7, height = 5, dpi = 300)

make_ice_plot <- function(feat, sample_n = 100, grid_n = 50) {
  is_cat <- is.factor(train[[feat]])
  
  if (is_cat) {
    grid_vals <- factor(levels(train[[feat]]), levels = levels(train[[feat]]))
  } else {
    rng <- range(train[[feat]], na.rm = TRUE)
    grid_vals <- seq(rng[1], rng[2], length.out = grid_n)
  }
  
  base_rows <- train %>%
    slice_sample(n = min(sample_n, nrow(train))) %>%
    mutate(.id = row_number())
  
  grid_tbl <- tibble(!!feat := grid_vals)
  
  newd <- base_rows %>%
    select(all_of(c("DiagPeriodL90D", predictors, ".id"))) %>%
    select(-all_of(feat)) %>%
    crossing(grid_tbl)
  
  newd$pred <- predict(gbm_fit, newdata = newd, n.trees = best_iter, type = "response")
  
  if (is_cat) {
    ggplot(newd, aes(x = pred, y = reorder(.data[[feat]], pred, FUN = median))) +
      geom_boxplot(fill = "steelblue", alpha = 0.4, outlier.size = 0.5) +
      labs(title = paste("ICE:", feat), x = "P( diagnosed within 90 days )", y = feat) +
      theme_minimal()
  } else {
    ggplot(newd, aes(x = .data[[feat]], y = .data[["pred"]], group = .data[[".id"]])) +
      geom_line(alpha = 0.25) +
      labs(title = paste("ICE:", feat), y = "P( diagnosed within 90 days )", x = feat) +
      theme_minimal()
  }
}

top_vars <- vi_tbl %>%
  slice_head(n = 4) %>%
  pull(variable)

ice_plots <- map(top_vars, make_ice_plot)
ice_grid <- arrangeGrob(grobs = ice_plots, ncol = 2)
ggsave("figures/adaboost/ice_top4.png", ice_grid, width = 14, height = 12, dpi = 300)

make_roc <- function(score, y) {
  ths <- c(Inf, sort(unique(score), decreasing = TRUE), -Inf)
  map_dfr(ths, function(t){
    pred <- as.integer(score >= t)
    tp <- sum(pred == 1 & y == 1)
    fp <- sum(pred == 1 & y == 0)
    tn <- sum(pred == 0 & y == 0)
    fn <- sum(pred == 0 & y == 1)
    tibble(`False Positive Rate` = fp/(fp + tn),
           `True Positive Rate`  = tp/(tp + fn),
           threshold = t)
  }) %>% arrange(threshold)
}

get_auc <- function(roc) {
  roc %>%
    arrange(`False Positive Rate`, `True Positive Rate`) %>%
    summarise(auc = sum(diff(`False Positive Rate`) *
                          (head(`True Positive Rate`, -1) + tail(`True Positive Rate`, -1)) / 2)) %>%
    pull(auc)
}

plot_roc <- function(roc, title) {
  ggplot(roc, aes(`False Positive Rate`, `True Positive Rate`)) +
    geom_line() +
    geom_abline(slope = 1, intercept = 0, color = "red") +
    labs(title = title, subtitle = paste0("AUC = ", round(get_auc(roc), 3))) +
    theme_minimal()
}

test <- test %>%
  mutate(score = predict(gbm_fit, newdata = test, n.trees = best_iter, type = "response"))

roc <- make_roc(test$score, test$DiagPeriodL90D)
get_auc(roc)

full <- dat$full

idx_full <- createDataPartition(full$DiagPeriodL90D, p = 0.8, list = FALSE)
train_full <- full[idx_full, ]
test_full  <- full[-idx_full, ]

gbm_full <- gbm(
  formula = DiagPeriodL90D ~ .,
  data = train_full,
  distribution = "adaboost",
  n.trees = 3000,
  interaction.depth = 3,
  shrinkage = 0.01,
  bag.fraction = 0.8,
  cv.folds = 5,
  train.fraction = 1.0,
  verbose = FALSE
)

best_full <- gbm.perf(gbm_full, method = "cv", plot.it = FALSE)

test_full <- test_full %>%
  mutate(score = predict(gbm_full, newdata = test_full, n.trees = best_full, type = "response"),
         icd_version = case_when(str_detect(breast_cancer_diagnosis_code, "^17") ~ "ICD-9",
                                 breast_cancer_diagnosis_code == "Other" ~ "Other",
                                 TRUE ~ "ICD-10"),
         icd10_flag = as.numeric(icd_version != "ICD-9"))

roc_full <- make_roc(test_full$score, test_full$DiagPeriodL90D)
roc_flag <- make_roc(test_full$icd10_flag, test_full$DiagPeriodL90D)

p_a <- plot_roc(roc_full, "A. With ICD code (all patients)")
p_b <- plot_roc(roc, "B. Without ICD code (ICD-10 patients only)")
p_c <- plot_roc(roc_flag, "C. ICD-9 vs ICD-10 flag only")

p_d <- ggplot(test_full, aes(x = score, fill = icd_version)) +
  geom_histogram(bins = 40, alpha = 0.6, position = "identity") +
  scale_fill_manual(values = c("ICD-10" = "steelblue", "ICD-9" = "tomato", "Other" = "grey50")) +
  labs(title = "D. Model A predictions by ICD version",
       x = "P( diagnosed within 90 days )", y = "Patients", fill = NULL) +
  theme_minimal() +
  theme(legend.position = "bottom")

icd_grid <- arrangeGrob(p_a, p_b, p_c, p_d, ncol = 2)
ggsave("figures/adaboost/icd_roc_comparison.png", icd_grid, width = 12, height = 10, dpi = 300)