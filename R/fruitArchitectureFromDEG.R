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
#' @param module_definition Module-assignment system. Use `NULL` to select
#'   the module definition required by `architecture_definition`. Built-in
#'   values are `"core10"` and `"broad6"`.
#' @param architecture_definition Architecture rule system. The default
#'   `"PHMIES"` preserves frozen v0.1 behavior. Use `"paper5_frozen"` for
#'   the Broad6 Paper 5 rules.
#' @param circuit_definition Directed-circuit rule system. The default
#'   `"none"` preserves legacy behavior. Use
#'   `"autocatalytic_ethylene_v1"` for the frozen ethylene circuit.
#' @param regulatory_overlay Optional data frame or named list containing
#'   experimentally supported regulatory nodes and directed edges.
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
    module_definition = NULL,
    circuit_definition = "none",
    regulatory_overlay = NULL,
    min_module_genes = 1L,
    min_interface_genes = 1L,
    n_permutations = 10000L,
    seed = 1234L) {

  definitions <- .fa_resolve_definitions(
    module_definition = module_definition,
    architecture_definition = architecture_definition,
    circuit_definition = circuit_definition
  )
  
  definition <- definitions$architecture_definition
  
  resolved_module_definition <-
    definitions$module_definition
  
  resolved_circuit_definition <-
    definitions$circuit_definition
  
  validated_regulatory_overlay <-
    .fa_validate_regulatory_overlay(
      regulatory_overlay
    )

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
      mapped_genes = length(
        intersect(
          standardized_deg$gene_id,
          mapped_genes
        )
      ),
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
  
  result$definition_metadata <- list(
    module_definition =
      .fa_definition_id(
        resolved_module_definition
      ),
    
    module_definition_version =
      if (!is.null(resolved_module_definition$version)) {
        resolved_module_definition$version
      } else {
        NA_character_
      },
    
    architecture_definition =
      .fa_definition_id(definition),
    
    architecture_definition_version =
      if (!is.null(definition$version)) {
        definition$version
      } else {
        NA_character_
      },
    
    circuit_definition =
      .fa_definition_id(
        resolved_circuit_definition
      ),
    
    circuit_definition_version =
      if (!is.null(resolved_circuit_definition$version)) {
        resolved_circuit_definition$version
      } else {
        NA_character_
      },
    
    regulatory_overlay_supplied =
      !is.null(validated_regulatory_overlay),
    
    package_version =
      .fruit_architecture_package_version()
  )
  
  result$regulatory_overlay <- validated_regulatory_overlay
  
  # These are placeholders for the next implementation stage.
  result$baseline_annotation_architecture <- list(
    module_summary = reconstruction$module_summary,
    interface_summary = reconstruction$interface_summary,
    level3a_present = reconstruction$level3a_present,
    level3b_genes = reconstruction$level3b_genes,
    level3b_count = reconstruction$level3b_count,
    metrics = metrics,
    architecture_class = architecture_class
  )
  if (
    identical(
      .fa_definition_id(
        resolved_circuit_definition
      ),
      "none"
    )
  ) {
    
    result$embedded_circuits <- NULL
    result$augmented_regulatory_architecture <- NULL
    
  } else if (is.null(validated_regulatory_overlay)) {
    
    result$embedded_circuits <- data.frame(
      circuit_id =
        .fa_definition_id(
          resolved_circuit_definition
        ),
      status = "not_evaluated",
      reason = "No regulatory overlay supplied.",
      stringsAsFactors = FALSE
    )
    
    result$augmented_regulatory_architecture <- NULL
    
  } else {
    
    embedded_circuits <-
      .fa_reconstruct_embedded_circuits(
        regulatory_overlay =
          validated_regulatory_overlay,
        
        circuit_definition =
          resolved_circuit_definition
      )
    
    result$embedded_circuits <-
      embedded_circuits
    
    result$augmented_regulatory_architecture <- list(
      baseline =
        result$baseline_annotation_architecture,
      
      regulatory_nodes =
        validated_regulatory_overlay$nodes,
      
      regulatory_edges =
        validated_regulatory_overlay$edges,
      
      embedded_circuits =
        embedded_circuits,
      
      complete_circuit_n =
        sum(
          embedded_circuits$complete_path_engaged,
          na.rm = TRUE
        ),
      
      any_complete_circuit =
        any(
          embedded_circuits$complete_path_engaged,
          na.rm = TRUE
        )
    )
  } 
  class(result) <- "fruit_architecture"
  
  result
}