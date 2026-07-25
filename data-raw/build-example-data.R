# Rebuild the installed synthetic example files.
# Run this script from the package root.

genes <- sprintf("FA_G%03d", seq_len(60))

example_deg <- data.frame(
  gene_id = genes,
  base_mean = 100 + seq_len(60) * 3.7,
  log2_fold_change = c(
    3.2 + (seq_len(10) %% 3) * 0.15,
    -(3.0 + (11:20 %% 4) * 0.12),
    rep(c(0.08, -0.12, 0.21, -0.18, 0.05), 8)
  ),
  standard_error = c(rep(0.22, 20), rep(0.35, 40)),
  adjusted_p_value = c(
    1e-6 * (1 + seq_len(10) / 20),
    2e-6 * (1 + 11:20 / 30),
    rep(c(0.61, 0.73, 0.82, 0.55, 0.91), 8)
  ),
  stringsAsFactors = FALSE
)
example_deg$statistic <- example_deg$log2_fold_change / example_deg$standard_error
example_deg$p_value <- pmin(0.99, example_deg$adjusted_p_value * 0.8)
example_deg <- example_deg[c(
  "gene_id", "base_mean", "log2_fold_change", "standard_error",
  "statistic", "p_value", "adjusted_p_value"
)]

utils::write.csv(
  example_deg,
  "inst/extdata/fruitArchitecture_example_deg.csv",
  row.names = FALSE
)

# The annotation and count files are retained in version control because their
# explicit multi-module memberships are part of the example specification.
