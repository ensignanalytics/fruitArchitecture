.validate_deg_input <- function(deg_table, annotation) {
  .assert_data_frame(deg_table, "deg_table")
  .assert_data_frame(annotation, "annotation")
  .assert_columns(deg_table, c("gene_id", "log2_fold_change", "adjusted_p_value"), "deg_table")
  .assert_columns(annotation, c("gene_id"), "annotation")

  if (!any(c("module", "pathway_name") %in% names(annotation))) {
    stop(
      "`annotation` must contain either a `module` or `pathway_name` column.",
      call. = FALSE
    )
  }

  if (anyNA(deg_table$gene_id) || any(deg_table$gene_id == "")) {
    stop("`deg_table$gene_id` cannot contain missing or empty values.", call. = FALSE)
  }
  if (anyDuplicated(deg_table$gene_id)) {
    stop("`deg_table$gene_id` must contain one row per gene.", call. = FALSE)
  }

  invisible(TRUE)
}

.validate_count_input <- function(counts, design, formula, contrast) {
  if (!is.matrix(counts) && !is.data.frame(counts)) {
    stop("`counts` must be a matrix or data.frame.", call. = FALSE)
  }
  counts <- as.matrix(counts)
  storage.mode(counts) <- "numeric"

  if (is.null(rownames(counts)) || any(rownames(counts) == "")) {
    stop("`counts` must have non-empty gene identifiers as row names.", call. = FALSE)
  }
  if (anyDuplicated(rownames(counts))) {
    stop("Count-matrix gene identifiers must be unique.", call. = FALSE)
  }
  if (is.null(colnames(counts)) || any(colnames(counts) == "")) {
    stop("`counts` must have sample names as column names.", call. = FALSE)
  }
  if (any(counts < 0, na.rm = TRUE)) {
    stop("`counts` cannot contain negative values.", call. = FALSE)
  }
  if (any(abs(counts - round(counts)) > .Machine$double.eps^0.5, na.rm = TRUE)) {
    stop("DESeq2 requires integer count values.", call. = FALSE)
  }

  .assert_data_frame(design, "design")
  if (is.null(rownames(design))) {
    stop("`design` must use sample names as row names.", call. = FALSE)
  }
  if (!setequal(colnames(counts), rownames(design))) {
    stop("Count columns and design row names must contain identical samples.", call. = FALSE)
  }
  if (!inherits(formula, "formula")) {
    stop("`formula` must be an R formula, for example `~ condition`.", call. = FALSE)
  }
  if (length(contrast) != 3L) {
    stop(
      "`contrast` must contain c(variable, numerator_level, denominator_level).",
      call. = FALSE
    )
  }

  invisible(TRUE)
}
