.run_level3b_null_model <- function(
    deg_table,
    mapped_annotation,
    definition,
    observed,
    n_permutations,
    seed) {

  if (n_permutations < 1L) {
    return(list(
      method = "Not run",
      n_permutations = 0L,
      expected = NA_real_,
      observed = observed,
      p_value = NA_real_,
      distribution = numeric()
    ))
  }

  genes <- unique(deg_table$gene_id)
  observed_deg <- stats::setNames(deg_table$deg_status, deg_table$gene_id)
  number_deg <- sum(observed_deg, na.rm = TRUE)

  membership <- split(mapped_annotation$module, mapped_annotation$gene_id)
  strict_genes <- names(Filter(function(z) {
    all(definition$core_modules %in% unique(z))
  }, membership))
  strict_genes <- intersect(strict_genes, genes)

  set.seed(seed)
  null_values <- replicate(n_permutations, {
    permuted_deg <- sample(genes, size = number_deg, replace = FALSE)
    sum(strict_genes %in% permuted_deg)
  })

  list(
    method = "Random DEG-label assignment preserving DEG count and annotation membership",
    n_permutations = n_permutations,
    expected = mean(null_values),
    observed = observed,
    p_value = .empirical_p_value(null_values, observed),
    distribution = as.numeric(null_values)
  )
}
