.standardize_deg_table <- function(
    deg_table,
    alpha,
    log2fc_threshold,
    gene_id_col = "gene_id",
    log2fc_col = "log2_fold_change",
    padj_col = "adjusted_p_value") {

  .assert_columns(deg_table, c(gene_id_col, log2fc_col, padj_col), "deg_table")

  out <- data.frame(
    gene_id = as.character(deg_table[[gene_id_col]]),
    log2_fold_change = as.numeric(deg_table[[log2fc_col]]),
    adjusted_p_value = as.numeric(deg_table[[padj_col]]),
    stringsAsFactors = FALSE
  )

  optional <- intersect(
    c("base_mean", "standard_error", "statistic", "p_value"),
    names(deg_table)
  )
  for (nm in optional) out[[nm]] <- deg_table[[nm]]

  out$deg_status <- !is.na(out$adjusted_p_value) &
    out$adjusted_p_value <= alpha &
    !is.na(out$log2_fold_change) &
    abs(out$log2_fold_change) >= log2fc_threshold

  out$direction <- ifelse(
    !out$deg_status,
    "Not significant",
    ifelse(out$log2_fold_change > 0, "Up", "Down")
  )

  out
}
