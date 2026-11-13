.PHONY: all clean

all: figures/DiagnosisPeriodDensity_fig.png figures/Age_fig.png figures/PayerTypeFig.png figures/Economic_var_corrs.png figures/corrplot.png figures/OutcomeCorrelations.png figures/scree_plot.png figures/pc_loadings.png

clean_data.csv: clean_data.R source_data.csv
	Rscript clean_data.R

figures/DiagnosisPeriodDensity_fig.png figures/Age_fig.png figures/PayerTypeFig.png: EDA_figs.R clean_data.csv
	Rscript EDA_figs.R

figures/Economic_var_corrs.png figures/corrplot.png figures/OutcomeCorrelations.png: correlation_plots.R clean_data.csv
	Rscript correlation_plots.R

figures/scree_plot.png figures/pc_loadings.png: PCA.R clean_data.csv
	Rscript PCA.R

clean:
	rm -f clean_data.csv *.png