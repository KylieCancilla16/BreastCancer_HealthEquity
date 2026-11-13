df <- read.csv("clean_data.csv")

drop <- c("patient_id", "patient_zip3", "DiagPeriodL90D", "bmi", "bmi_missing", "aq_imputed",
          "female", "income_household_six_figure", "education_college_or_above")
x <- df[sapply(df, is.numeric)]
x <- x[setdiff(names(x), drop)]

pca <- prcomp(x, scale. = TRUE)
pve <- pca$sdev^2 / sum(pca$sdev^2)
cor_pc <- sweep(pca$rotation, 2, pca$sdev, "*")

png("figures/scree_plot.png", width = 1800, height = 900, res = 150)
par(mfrow = c(1, 2))
barplot(100 * pve[1:20], names.arg = 1:20, col = "steelblue",
        xlab = "Principal component", ylab = "% variance explained",
        main = "Variance explained by each PC")
plot(1:20, 100 * cumsum(pve[1:20]), type = "b", pch = 19, ylim = c(0, 100),
     xlab = "Principal component", ylab = "Cumulative % variance explained",
     main = "Cumulative variance explained")
abline(h = 80, lty = 2)
dev.off()

png("figures/pc_loadings.png", width = 1800, height = 1200, res = 150)
par(mfrow = c(2, 3), mar = c(4, 11, 3, 1))
for (i in 1:6) {
  top <- cor_pc[order(abs(cor_pc[, i]), decreasing = TRUE)[1:10], i]
  top <- rev(top)
  barplot(top, horiz = TRUE, las = 1, xlim = c(-1, 1), cex.names = 0.7,
          names.arg = gsub("_", " ", names(top)),
          col = ifelse(top > 0, "tomato", "steelblue"),
          main = paste0("PC", i, " (", round(100 * pve[i], 1), "%)"))
}
dev.off()