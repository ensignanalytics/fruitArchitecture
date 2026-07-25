#' Reconstruct a signaling architecture from a differential-expression table
#'
#' @param deg_table A data frame containing one row per gene.
#' @param annotation A long-format data frame containing gene-to-module or
#'   gene-to-pathway assignments.
#' @param species Optional species label.
#' @param gene_id_col Name of the gene identifier column in `deg_table`.
#' @param log2fc_col Name of the log2 fold-change column.
#' @param padj_col Name of the adjusted P-value column.
#' @param alpha Adjusted P-value threshold.
#' @param log2fc_threshold Absolute log2 fold-change threshold.
#' @param architecture_definition Either `"PHMIES"` or a custom definition list.
#' @param min_module_genes Minimum number of significant genes required for a
#'   module to be considered present.
#' @param min_interface_genes Minimum number of strict overlap genes required
#'   for a pairwise interface to be considered present.
#' @param n_permutations Number of permutations for the Level 3B null model.
#' @param seed Random seed.
#'
#' @return An object of class `fruit_architecture`.
#' @export
fruitArchitectureFromDEG <- function(
    deg_table,
    annotation,
    species = NULL,
    gene_id_col = "gene_id",
    log2fc_col = "log2_fold_change",
    padj_col = "adjusted_p_value",
    alpha = 0.05,
    log2fc_threshold = 1,
    architecture_definition = "PHMIES",
    min_module_genes = 1L,
    min_interface_genes = 1L,
    n_permutations = 10000L,
    seed = 1234L) {

  definition <- .resolve_architecture_definition(architecture_definition)

  standardized_deg <- .standardize_deg_table(
    deg_table = deg_table,
    alpha = alpha,
    log2fc_threshold = log2fc_threshold,
    gene_id_col = gene_id_col,
    log2fc_col = log2fc_col,
    padj_col = padj_col
  )

  annotation_copy <- annotation
  names(annotation_copy)[names(annotation_copy) == gene_id_col] <- "gene_id"
  .validate_deg_input(standardized_deg, annotation_copy)

  mapped_annotation <- .map_annotation_modules(annotation_copy, definition)
  if (nrow(mapped_annotation) == 0L) {
    stop("No annotation rows matched the selected architecture definition.", call. = FALSE)
  }

  reconstruction <- .reconstruct_architecture(
    deg_table = standardized_deg,
    mapped_annotation = mapped_annotation,
    definition = definition,
    min_module_genes = as.integer(min_module_genes),
    min_interface_genes = as.integer(min_interface_genes)
  )

  metrics <- .calculate_architecture_metrics(reconstruction, definition)
  null_model <- .run_level3b_null_model(
    deg_table = standardized_deg,
    mapped_annotation = mapped_annotation,
    definition = definition,
    observed = reconstruction$level3b_count,
    n_permutations = as.integer(n_permutations),
    seed = as.integer(seed)
  )

  mapped_genes <- unique(mapped_annotation$gene_id)
  annotation_coverage <- length(intersect(standardized_deg$gene_id, mapped_genes)) /
    nrow(standardized_deg)

  architecture_class <- .classify_architecture(reconstruction, metrics)
  robustness <- .assess_robustness(metrics, null_model, annotation_coverage)

  result <- list(
    call = match.call(),
    metadata = list(
      species = species %||% "unspecified",
      architecture = definition$name,
      architecture_version = definition$version,
      alpha = alpha,
      log2fc_threshold = log2fc_threshold,
      seed = seed
    ),
    input_audit = list(
      input_genes = nrow(standardized_deg),
      significant_genes = sum(standardized_deg$deg_status),
      mapped_genes = length(intersect(standardized_deg$gene_id, mapped_genes)),
      annotation_coverage = annotation_coverage
    ),
    differential_expression = standardized_deg,
    mapped_annotation = mapped_annotation,
    gene_membership = reconstruction$gene_membership,
    module_summary = reconstruction$module_summary,
    interface_summary = reconstruction$interface_summary,
    level3a_present = reconstruction$level3a_present,
    level3b_genes = reconstruction$level3b_genes,
    level3b_count = reconstruction$level3b_count,
    metrics = metrics,
    null_model = null_model,
    architecture_class = architecture_class,
    robustness = robustness,
    definition = definition,
    provenance = list(
      package = "fruitArchitecture",
      package_version = .fruit_architecture_package_version(),
      r_version = R.version.string,
      analysis_time = Sys.time()
    )
  )

  class(result) <- "fruit_architecture"
  result
}
