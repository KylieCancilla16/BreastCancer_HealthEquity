.PHONY: all clean

all: figures/DiagnosisPeriodDensity_fig.png figures/Age_fig.png figures/PayerTypeFig.png figures/Economic_var_corrs.png figures/corrplot.png figures/OutcomeCorrelations.png

clean_data.csv: clean_data.R source_data.csv
	Rscript clean_data.R

figures/DiagnosisPeriodDensity_fig.png figures/Age_fig.png figures/PayerTypeFig.png: EDA_figs.R clean_data.csv
	Rscript EDA_figs.R

figures/Economic_var_corrs.png figures/corrplot.png figures/OutcomeCorrelations.png: correlation_plots.R clean_data.csv
	Rscript correlation_plots.R

clean:
	rm -f clean_data.csv *.png