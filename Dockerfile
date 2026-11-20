
FROM rocker/rstudio:latest

RUN R -e "pkgs <- c('matlab', 'tidyverse', 'GGally', 'janitor', 'fastDummies', 'car', 'corrplot', 'caret', 'gbm', 'gridExtra'); \
  install.packages(pkgs); \
  missing <- setdiff(pkgs, rownames(installed.packages())); \
  if (length(missing) > 0) stop('Failed to install: ', paste(missing, collapse = ', '))"

