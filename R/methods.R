#' @export
print.fruit_architecture <- function(x, ...) {
  cat("Fruit Architecture Analysis\n")
  cat(strrep("-", 46), "\n", sep = "")
  cat("Species: ", x$metadata$species, "\n", sep = "")
  cat("Architecture: ", x$metadata$architecture, "\n\n", sep = "")
  cat("Architecture Class: ", x$architecture_class, "\n", sep = "")
  cat("Weighted ISI: ", sprintf("%.3f", x$metrics$weighted_isi), "\n", sep = "")
  cat("Level 3A: ", if (x$level3a_present) "Present" else "Absent", "\n", sep = "")
  cat("Level 3B: ", if (x$level3b_count > 0) "Present" else "Absent", "\n", sep = "")
  cat("Architecture robustness: ", x$robustness$label, "\n", sep = "")
  cat("Architecture entropy: ", sprintf("%.3f", x$metrics$architecture_entropy), "\n", sep = "")
  cat("Architecture balance: ", sprintf("%.3f", x$metrics$architecture_balance), "\n\n", sep = "")
  cat("Expected Level 3B: ", sprintf("%.3f", x$null_model$expected), "\n", sep = "")
  cat("Observed Level 3B: ", x$null_model$observed, "\n", sep = "")
  cat("Empirical P-value: ", format.pval(x$null_model$p_value, digits = 3), "\n", sep = "")
  invisible(x)
}

#' @export
summary.fruit_architecture <- function(object, ...) {
  out <- list(
    species = object$metadata$species,
    architecture = object$metadata$architecture,
    architecture_class = object$architecture_class,
    weighted_isi = object$metrics$weighted_isi,
    level3a_present = object$level3a_present,
    level3b_count = object$level3b_count,
    robustness = object$robustness,
    entropy = object$metrics$architecture_entropy,
    balance = object$metrics$architecture_balance,
    null_model = object$null_model[c("method", "expected", "observed", "p_value")],
    input_audit = object$input_audit,
    module_summary = object$module_summary,
    interface_summary = object$interface_summary
  )
  class(out) <- "summary.fruit_architecture"
  out
}
