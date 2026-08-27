.calculate_architecture_metrics <- function(reconstruction, definition) {
  module_summary <- reconstruction$module_summary
  interface_summary <- reconstruction$interface_summary

  level1_fraction <- mean(module_summary$present)
  level2_fraction <- mean(interface_summary$present)

  required_level3a_ids <- definition$level3a_interface_ids

  if (is.null(required_level3a_ids) || length(required_level3a_ids) == 0L) {
    required_level2_fraction <- level2_fraction
  } else {
    required_level3a_ids <- as.character(required_level3a_ids)
    present_interface_ids <- as.character(
      interface_summary$interface_id[interface_summary$present]
    )

    required_level2_fraction <- mean(
      required_level3a_ids %in% present_interface_ids
    )
  }

  level3a_score <- as.numeric(reconstruction$level3a_present)
  level3b_score <- as.numeric(reconstruction$level3b_count > 0L)

  weights <- unlist(definition$weights[c("level1", "level2", "level3a", "level3b")])
  weights <- weights / sum(weights)

  weighted_isi <- sum(
    weights * c(level1_fraction, level2_fraction, level3a_score, level3b_score)
  )

  core_counts <- module_summary$deg_genes[
    match(definition$core_modules, module_summary$module)
  ]
  core_counts[is.na(core_counts)] <- 0

  if (sum(core_counts) == 0) {
    entropy <- 0
    balance <- 0
  } else {
    probabilities <- core_counts / sum(core_counts)
    nonzero <- probabilities[probabilities > 0]
    entropy <- -sum(nonzero * log(nonzero)) / log(length(core_counts))
    balance <- if (max(core_counts) == 0) 0 else min(core_counts) / max(core_counts)
  }

  list(
    metric_version = "0.1.1",
    weighted_isi = unname(weighted_isi),
    level1_fraction = level1_fraction,
    level2_fraction = level2_fraction,
    required_level2_fraction = required_level2_fraction,
    architecture_entropy = unname(entropy),
    architecture_balance = unname(balance)
  )
}
