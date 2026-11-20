# Breast Cancer Health Equity: Predicting Timely Metastatic Diagnosis

This project explores a dataset from the Women in Data Science Wordwide (WiDs) 2024 datathon. The dataset includes 10000 patients, their geo coded (zip level) demographic data (income, education, race, uninsured, etc), characteristics (age, bmi, race) and metastatic cancer diagnosis code. 

## Getting Started

### Dependencies

* [Docker](https://www.docker.com/products/docker-desktop/). The Docker image includes R and every package the analysis needs (tidyverse, caret, gbm, gridExtra, corrplot, etc.), so nothing else has to be installed.
* Git, to clone the repository.
* Works on Windows, macOS, or Linux, wherever Docker runs.

### Installing

1. Clone the repository:
```
git clone https://github.com/KylieCancilla16/BreastCancer_HealthEquity.git
cd BreastCancer_HealthEquity
```

2. Make sure `source_data.csv` is in the main project folder. The data was downloaded from the WiDs [kaggle competition page](https://www.kaggle.com/competitions/widsdatathon2024-challenge1/data?select=training.csv)

3. Build the Docker image (the first build may take several minutes):
```
docker build -t <image-name> .
```

### Executing program

1. Start the container. Use the command that matches your system:

   **macOS / Linux (Terminal):**
   ```
   docker run --rm -p 8787:8787 -e PASSWORD=yourpassword -v "$(pwd)":/home/rstudio/project rocker/rstudio <image-name> .
   ```

   **Windows (PowerShell):**
   ```
   docker run --rm -p 8787:8787 -e PASSWORD=yourpassword -v "${PWD}:/home/rstudio/project" rocker/rstudio <image-name> .
   ```

   **Windows (Command Prompt):**
   ```
   docker run --rm -p 8787:8787 -e PASSWORD=yourpassword -v "%cd%":/home/rstudio/project rocker/rstudio <image-name> . 
   ```

2. Open a browser and go to `http://localhost:8787`
3. Log in with username `rstudio` and the password you set above
4. In the RStudio **Terminal** tab (not the Console), run:

```
cd ~/project
make
```
This cleans the raw data, makes all figures in `figures/`, and builds the final report. The AdaBoost step fits two models with cross-validation and takes about 8–10 minutes.

3. To build only the final report:
```
make <report.html>
```

4. To delete all generated files and start over:
```
make clean
```

### Project Structure

```
├── Dockerfile
├── Makefile
├── source_data.csv         raw data
├── scripts/                all R scripts
│   ├── clean_data.R
│   ├── EDA_figs.R
│   ├── correlation_plots.R
│   ├── PCA.R
│   ├── explore_icd.R
│   ├── prepareDataforAdaBoost.R
│   └── adaBoost.R
├── figures/                generated figures
│   └── adaboost/           AdaBoost figures
└── <report.Rmd>            final report
```