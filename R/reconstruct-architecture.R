.reconstruct_architecture <- function(
    deg_table,
    mapped_annotation,
    definition,
    min_module_genes = 1L,
    min_interface_genes = 1L) {

  gene_module <- merge(
    mapped_annotation,
    deg_table[, c("gene_id", "deg_status", "direction", "log2_fold_change", "adjusted_p_value")],
    by = "gene_id",
    all.x = TRUE,
    sort = FALSE
  )
  gene_module$deg_status[is.na(gene_module$deg_status)] <- FALSE

  module_split <- split(gene_module, gene_module$module)
  module_summary <- do.call(
    rbind,
    lapply(definition$modules, function(module_name) {
      x <- module_split[[module_name]]
      if (is.null(x)) {
        return(data.frame(
          module = module_name,
          annotated_genes = 0L,
          deg_genes = 0L,
          up_genes = 0L,
          down_genes = 0L,
          present = FALSE,
          stringsAsFactors = FALSE
        ))
      }
      x_deg <- x[x$deg_status, , drop = FALSE]
      data.frame(
        module = module_name,
        annotated_genes = length(unique(x$gene_id)),
        deg_genes = length(unique(x_deg$gene_id)),
        up_genes = length(unique(x_deg$gene_id[x_deg$direction == "Up"])),
        down_genes = length(unique(x_deg$gene_id[x_deg$direction == "Down"])),
        present = length(unique(x_deg$gene_id)) >= min_module_genes,
        stringsAsFactors = FALSE
      )
    })
  )
  rownames(module_summary) <- NULL

  deg_membership <- unique(gene_module[gene_module$deg_status, c("gene_id", "module"), drop = FALSE])
  membership_by_gene <- split(deg_membership$module, deg_membership$gene_id)

  interface_summary <- do.call(
    rbind,
    lapply(seq_len(nrow(definition$interfaces)), function(i) {
      row <- definition$interfaces[i, , drop = FALSE]
      overlap_genes <- names(Filter(function(z) {
        all(c(row$module_a, row$module_b) %in% z)
      }, membership_by_gene))
      data.frame(
        interface = row$interface,
        module_a = row$module_a,
        module_b = row$module_b,
        overlap_genes = length(overlap_genes),
        present = length(overlap_genes) >= min_interface_genes,
        genes = paste(overlap_genes, collapse = ";"),
        stringsAsFactors = FALSE
      )
    })
  )
  rownames(interface_summary) <- NULL

  core_rows <- module_summary$module %in% definition$core_modules

  # Level 3A is defined by the interfaces explicitly declared by the
  # architecture definition. This matters for Broad6, which reconstructs
  # all 15 pairwise interfaces while retaining only the three PHMIES-core
  # interfaces as Level 3A requirements. Definitions without an explicit
  # Level 3A interface list retain the historical all-interfaces behavior.
  required_level3a_ids <- definition$level3a_interface_ids

  # Preserve definition-supplied identifiers when present. The frozen
  # PHMIES definition intentionally uses short canonical IDs, whereas
  # Broad6 compatibility interfaces are identified from their module names.
  interface_ids <- if ("interface_id" %in% names(definition$interfaces)) {
    as.character(definition$interfaces$interface_id)
  } else {
    .fa_interface_id(
      interface_summary$module_a,
      interface_summary$module_b
    )
  }

  if (!is.null(required_level3a_ids) && length(required_level3a_ids) > 0L) {
    required_level3a_ids <- as.character(required_level3a_ids)
    required_rows <- interface_ids %in% required_level3a_ids

    level3a_interfaces_present <-
      all(required_level3a_ids %in% interface_ids) &&
      all(interface_summary$present[required_rows])
  } else {
    level3a_interfaces_present <- all(interface_summary$present)
  }

  level3a_present <-
    all(module_summary$present[core_rows]) &&
    level3a_interfaces_present

  level3b_genes <- names(Filter(function(z) {
    all(definition$core_modules %in% z)
  }, membership_by_gene))

  gene_membership <- unique(gene_module[, c(
    "gene_id", "module", "deg_status", "direction",
    "log2_fold_change", "adjusted_p_value"
  )])
  gene_membership$level3b <- gene_membership$gene_id %in% level3b_genes

  list(
    gene_membership = gene_membership,
    module_summary = module_summary,
    interface_summary = interface_summary,
    level3a_present = level3a_present,
    level3b_genes = level3b_genes,
    level3b_count = length(level3b_genes)
  )
}
