clean_data.csv: clean_data.R source_data.csv
	Rscript clean_data.R

ranks.csv rank_pairs.csv: preprocess-data.R nuforc_sightings.csv regions.csv
	Rscript preprocess-data.R 