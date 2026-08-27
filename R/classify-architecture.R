.classify_architecture <- function(reconstruction, metrics, definition) {
  class_level2_fraction <- if (
    isTRUE(definition$extended_interfaces_affect_class)
  ) {
    metrics$level2_fraction
  } else {
    metrics$required_level2_fraction
  }

  if (reconstruction$level3a_present && reconstruction$level3b_count > 0L) {
    return("IV")
  }
  if (reconstruction$level3a_present || class_level2_fraction >= 2 / 3) {
    return("III")
  }
  if (metrics$level1_fraction >= 0.5 || class_level2_fraction > 0) {
    return("II")
  }
  "I"
}

.assess_robustness <- function(metrics, null_model, annotation_coverage) {
  score <- mean(c(
    metrics$weighted_isi,
    metrics$architecture_balance,
    metrics$architecture_entropy,
    min(1, annotation_coverage)
  ), na.rm = TRUE)

  if (!is.na(null_model$p_value) && null_model$p_value <= 0.05) {
    score <- min(1, score + 0.10)
  }

  label <- if (score >= 0.75) {
    "High"
  } else if (score >= 0.50) {
    "Moderate"
  } else {
    "Low"
  }

  list(
    method = "Composite preliminary robustness score v0.1.0",
    score = score,
    label = label
  )
}
