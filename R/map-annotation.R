.map_annotation_modules <- function(annotation, definition) {
  annotation <- annotation[!is.na(annotation$gene_id) & annotation$gene_id != "", , drop = FALSE]
  source_col <- if ("module" %in% names(annotation)) "module" else "pathway_name"
  source_text <- .clean_text(annotation[[source_col]])

  alias_lookup <- unlist(
    lapply(names(definition$aliases), function(module_name) {
      stats::setNames(
        rep(module_name, length(definition$aliases[[module_name]])),
        .clean_text(definition$aliases[[module_name]])
      )
    }),
    use.names = TRUE
  )

  resolved <- unname(alias_lookup[source_text])
  direct <- annotation[[source_col]] %in% definition$modules
  resolved[direct] <- as.character(annotation[[source_col]][direct])

  out <- data.frame(
    gene_id = as.character(annotation$gene_id),
    source_annotation = as.character(annotation[[source_col]]),
    module = resolved,
    stringsAsFactors = FALSE
  )

  out <- out[!is.na(out$module), , drop = FALSE]
  unique(out)
}
