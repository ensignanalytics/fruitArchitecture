# Run from the fruitArchitecture package root.

required_cran <- c(
  "devtools", "roxygen2", "testthat", "knitr", "rmarkdown", "ggplot2", "withr"
)
missing_cran <- required_cran[!vapply(required_cran, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_cran) > 0L) {
  install.packages(missing_cran)
}

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
if (!requireNamespace("DESeq2", quietly = TRUE)) {
  BiocManager::install("DESeq2")
}

devtools::document()
devtools::test()
devtools::check()
