.PHONY: all clean

all: figures/EDA_fig.png figures/corrplot.png figures/OutcomeCorrelations.png figures/scree_plot.png figures/pc_loadings.png figures/adaboost/variable_importance.png figures/adaboost/ice_top4.png figures/adaboost/icd_roc_comparison.png

clean_data.csv: scripts/clean_data.R source_data.csv
	Rscript scripts/clean_data.R

figures/EDA_fig.png: scripts/EDA_figs.R clean_data.csv
	Rscript scripts/EDA_figs.R

figures/corrplot.png figures/OutcomeCorrelations.png: scripts/correlation_plots.R clean_data.csv
	Rscript scripts/correlation_plots.R

figures/scree_plot.png figures/pc_loadings.png: scripts/PCA.R clean_data.csv
	Rscript scripts/PCA.R

adaboost_data.rds: scripts/prepareDataforAdaBoost.R clean_data.csv
	Rscript scripts/prepareDataforAdaBoost.R

figures/adaboost/variable_importance.png figures/adaboost/ice_top4.png figures/adaboost/icd_roc_comparison.png: scripts/adaBoost.R adaboost_data.rds
	Rscript scripts/adaBoost.R

clean:
	rm -f clean_data.csv adaboost_data.rds figures/*.png figures/adaboost/*.png 