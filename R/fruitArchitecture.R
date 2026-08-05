#' Reconstruct a signaling architecture from an RNA-seq count matrix
#'
#' @param counts Integer count matrix with genes in rows and samples in columns.
#' @param design Sample metadata with sample names as row names.
#' @param species Species label.
#' @param formula Experimental design formula.
#' @param contrast DESeq2 contrast of the form
#'   `c(variable, numerator_level, denominator_level)`.
#' @param annotation Gene-to-module or gene-to-pathway annotation table.
#' @param alpha Adjusted P-value threshold.
#' @param log2fc_threshold Absolute log2 fold-change threshold.
#' @param architecture_definition Architecture rule system. The default
#'   `"PHMIES"` preserves frozen v0.1 behavior. Use `"paper5_frozen"` for
#'   the Broad6 Paper 5 rules. A custom definition list is also accepted.
#' @param module_definition Module-assignment system. Use `NULL` to select
#'   the module definition required by `architecture_definition`. Built-in
#'   values are `"core10"` and `"broad6"`.
#' @param circuit_definition Directed-circuit rule system. The default
#'   `"none"` preserves legacy behavior. Use
#'   `"autocatalytic_ethylene_v1"` for the frozen ethylene circuit.
#' @param regulatory_overlay Optional data frame or named list containing
#'   experimentally supported regulatory nodes and directed edges.
#' @param min_module_genes Minimum significant genes per module.
#' @param min_interface_genes Minimum strict overlap genes per interface.
#' @param n_permutations Number of Level 3B permutations.
#' @param seed Random seed.
#' @param quiet Suppress DESeq2 progress output when possible.
#'
#' @return An object of class `fruit_architecture`.
#' @export
fruitArchitecture <- function(
    counts,
    design,
    species,
    formula,
    contrast,
    annotation,
    alpha = 0.05,
    log2fc_threshold = 1,
    architecture_definition = "PHMIES",
    module_definition = NULL,
    circuit_definition = "none",
    regulatory_overlay = NULL,
    min_module_genes = 1L,
    min_interface_genes = 1L,
    n_permutations = 10000L,
    seed = 1234L,
    quiet = FALSE) {

  if (!requireNamespace("DESeq2", quietly = TRUE)) {
    stop(
      "Package `DESeq2` is required for count-based analysis. ",
      "Install it with BiocManager::install('DESeq2').",
      call. = FALSE
    )
  }

  .validate_count_input(counts, design, formula, contrast)
  counts <- as.matrix(counts)
  counts <- counts[, rownames(design), drop = FALSE]

  dds <- DESeq2::DESeqDataSetFromMatrix(
    countData = round(counts),
    colData = design,
    design = formula
  )
  dds <- DESeq2::DESeq(dds, quiet = quiet)
  res <- DESeq2::results(dds, contrast = contrast, alpha = alpha)

  deg_table <- data.frame(
    gene_id = rownames(res),
    base_mean = res$baseMean,
    log2_fold_change = res$log2FoldChange,
    standard_error = res$lfcSE,
    statistic = res$stat,
    p_value = res$pvalue,
    adjusted_p_value = res$padj,
    stringsAsFactors = FALSE
  )

  out <- fruitArchitectureFromDEG(
    deg_table = deg_table,
    annotation = annotation,
    species = species,
    alpha = alpha,
    log2fc_threshold = log2fc_threshold,
    architecture_definition = architecture_definition,
    module_definition = module_definition,
    circuit_definition = circuit_definition,
    regulatory_overlay = regulatory_overlay,
    min_module_genes = min_module_genes,
    min_interface_genes = min_interface_genes,
    n_permutations = n_permutations,
    seed = seed
  )

  out$metadata$formula <- deparse(formula)
  out$metadata$contrast <- contrast
  out$deseq2 <- list(dds = dds, results = res)
  out
}
