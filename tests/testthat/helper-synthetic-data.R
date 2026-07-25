make_synthetic_architecture_data <- function() {
  deg <- data.frame(
    gene_id = paste0("g", 1:12),
    log2_fold_change = c(2, 2, 2, 2, -2, -2, 1.5, -1.5, rep(0.1, 4)),
    adjusted_p_value = c(rep(0.001, 8), rep(0.8, 4)),
    stringsAsFactors = FALSE
  )

  annotation <- data.frame(
    gene_id = c(
      "g1", "g1", "g1",
      "g2", "g2",
      "g3", "g3",
      "g4", "g4", "g4",
      "g5", "g6", "g7", "g8"
    ),
    module = c(
      "Plant hormone signal transduction", "MAPK signaling", "Information exchange",
      "Plant hormone signal transduction", "MAPK signaling",
      "Plant hormone signal transduction", "Information exchange",
      "Plant hormone signal transduction", "MAPK signaling", "Information exchange",
      "Circadian rhythm", "RNA transport", "RNA degradation", "Autophagy"
    ),
    stringsAsFactors = FALSE
  )

  list(deg = deg, annotation = annotation)
}
