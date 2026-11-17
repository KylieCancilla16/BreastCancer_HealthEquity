library(tidyverse)
library(caret)
library(gbm)

set.seed(2026)
dir.create("figures/adaboost", recursive = TRUE, showWarnings = FALSE)

d <- readRDS("adaboost_data.rds") %>%
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
  slice_head(n = 3) %>%
  pull(variable)

for (f in top_vars) {
  h <- if (is.factor(train[[f]])) max(4, nlevels(train[[f]]) * 0.15) else 4
  ggsave(paste0("figures/adaboost/ice_", f, ".png"), make_ice_plot(f), width = 6, height = h, dpi = 300)
}

test <- test %>%
  mutate(score = predict(gbm_fit, newdata = test, n.trees = best_iter, type = "response"),
         y = DiagPeriodL90D)

ths <- test$score %>% unique() %>% sort(decreasing = TRUE)
ths <- c(Inf, ths, -Inf)

roc <- map_dfr(ths, function(t){
  pred <- as.integer(test$score >= t)
  tp <- sum(pred == 1 & test$y == 1)
  fp <- sum(pred == 1 & test$y == 0)
  tn <- sum(pred == 0 & test$y == 0)
  fn <- sum(pred == 0 & test$y == 1)
  tibble(`False Positive Rate` = fp/(fp + tn),
         `True Positive Rate`  = tp/(tp + fn),
         threshold = t)
}) %>% arrange(threshold)

auc <- roc %>%
  arrange(`False Positive Rate`, `True Positive Rate`) %>%
  summarise(auc = sum(diff(`False Positive Rate`) *
                        (head(`True Positive Rate`, -1) + tail(`True Positive Rate`, -1)) / 2)) %>%
  pull(auc)
auc

p_roc <- ggplot(roc, aes(`False Positive Rate`, `True Positive Rate`)) +
  geom_line() +
  geom_abline(slope = 1, intercept = 0, color = "red") +
  labs(title = paste0("ROC on test set (AUC = ", round(auc, 3), ")")) +
  theme_minimal()
ggsave("figures/adaboost/roc_curve.png", p_roc, width = 6, height = 5, dpi = 300)