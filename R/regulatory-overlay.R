# ============================================================
# Regulatory overlay validation
# ============================================================


#' Convert a supported flag to logical
#'
#' @param x Logical or binary numeric vector.
#' @param name Name used in error messages.
#'
#' @return A logical vector.
#' @keywords internal
.fa_as_logical_flag <- function(x, name) {
  
  if (is.logical(x)) {
    return(x)
  }
  
  if (is.numeric(x) && all(x %in% c(0, 1, NA))) {
    return(as.logical(x))
  }
  
  stop(
    sprintf(
      "`%s` must contain logical values or binary 0/1 values.",
      name
    ),
    call. = FALSE
  )
}


#' Validate a regulatory overlay
#'
#' @param regulatory_overlay Either `NULL` or a named list containing
#'   `nodes` and `edges` data frames.
#'
#' @return `NULL` or a validated regulatory-overlay list.
#' @keywords internal
.fa_validate_regulatory_overlay <- function(
    regulatory_overlay) {
  
  if (is.null(regulatory_overlay)) {
    return(NULL)
  }
  
  if (
    !is.list(regulatory_overlay) ||
    !all(c("nodes", "edges") %in%
         names(regulatory_overlay))
  ) {
    stop(
      paste0(
        "`regulatory_overlay` must be NULL or a named list ",
        "containing `nodes` and `edges` data frames."
      ),
      call. = FALSE
    )
  }
  
  nodes <- regulatory_overlay$nodes
  edges <- regulatory_overlay$edges
  
  if (!is.data.frame(nodes)) {
    stop(
      "`regulatory_overlay$nodes` must be a data frame.",
      call. = FALSE
    )
  }
  
  if (!is.data.frame(edges)) {
    stop(
      "`regulatory_overlay$edges` must be a data frame.",
      call. = FALSE
    )
  }
  
  required_node_columns <- c(
    "species",
    "developmental_context",
    "gene_id",
    "gene_class",
    "node_supported",
    "evidence_type",
    "evidence_source"
  )
  
  required_edge_columns <- c(
    "species",
    "developmental_context",
    "source_gene_id",
    "target_gene_id",
    "source_gene_class",
    "target_gene_class",
    "edge_supported",
    "evidence_type",
    "evidence_source"
  )
  
  missing_node_columns <- setdiff(
    required_node_columns,
    names(nodes)
  )
  
  missing_edge_columns <- setdiff(
    required_edge_columns,
    names(edges)
  )
  
  if (length(missing_node_columns) > 0L) {
    stop(
      "Regulatory node table is missing: ",
      paste(missing_node_columns, collapse = ", "),
      call. = FALSE
    )
  }
  
  if (length(missing_edge_columns) > 0L) {
    stop(
      "Regulatory edge table is missing: ",
      paste(missing_edge_columns, collapse = ", "),
      call. = FALSE
    )
  }
  
  node_key_columns <- c(
    "species",
    "developmental_context",
    "gene_id",
    "gene_class"
  )
  
  edge_key_columns <- c(
    "species",
    "developmental_context",
    "source_gene_id",
    "target_gene_id",
    "source_gene_class",
    "target_gene_class"
  )
  
  for (column in node_key_columns) {
    nodes[[column]] <- trimws(
      as.character(nodes[[column]])
    )
    
    if (
      anyNA(nodes[[column]]) ||
      any(!nzchar(nodes[[column]]))
    ) {
      stop(
        sprintf(
          "`regulatory_overlay$nodes$%s` cannot contain missing or empty values.",
          column
        ),
        call. = FALSE
      )
    }
  }
  
  for (column in edge_key_columns) {
    edges[[column]] <- trimws(
      as.character(edges[[column]])
    )
    
    if (
      anyNA(edges[[column]]) ||
      any(!nzchar(edges[[column]]))
    ) {
      stop(
        sprintf(
          "`regulatory_overlay$edges$%s` cannot contain missing or empty values.",
          column
        ),
        call. = FALSE
      )
    }
  }
  
  nodes$gene_class <- toupper(
    nodes$gene_class
  )
  
  edges$source_gene_class <- toupper(
    edges$source_gene_class
  )
  
  edges$target_gene_class <- toupper(
    edges$target_gene_class
  )
  
  nodes$node_supported <- .fa_as_logical_flag(
    nodes$node_supported,
    "node_supported"
  )
  
  edges$edge_supported <- .fa_as_logical_flag(
    edges$edge_supported,
    "edge_supported"
  )
  
  list(
    nodes = nodes,
    edges = edges
  )
}