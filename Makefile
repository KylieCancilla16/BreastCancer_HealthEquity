 .PHONY: all clean

all: DiagnosisPeriodDensity_fig.png MedianAge_fig.png PayerTypeFig.png

clean_data.csv: clean_data.R source_data.csv
	Rscript clean_data.R

DiagnosisPeriodDensity_fig.png MedianAge_fig.png PayerTypeFig.png: EDA_figs.R clean_data.csv
	Rscript EDA_figs.R

clean:
	rm -f clean_data.csv *.png