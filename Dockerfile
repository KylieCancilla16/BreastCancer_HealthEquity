
FROM rocker/rstudio:latest

RUN R -e "install.packages(c('matlab', 'tidyverse', 'GGally', 'janitor', 'fastDummies', 'car', 'corrplot'), repos='https://cloud.r-project.org')"


