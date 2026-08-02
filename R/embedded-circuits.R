# ============================================================
# Embedded directed-circuit reconstruction
# ============================================================


#' Create an empty embedded-circuit result
#'
#' @return An empty data frame with the circuit-result schema.
#' @keywords internal
.fa_empty_circuit_result <- function() {
  
  data.frame(
    species = character(),
    developmental_context = character(),
    circuit_id = character(),
    path_id = character(),
    
    upstream_gene_id = character(),
    upstream_gene_class = character(),
    
    intermediate_gene_id = character(),
    intermediate_gene_class = character(),
    
    target_gene_id = character(),
    target_gene_class = character(),
    
    upstream_node_supported = logical(),
    intermediate_node_supported = logical(),
    target_node_supported = logical(),
    
    regulator_edge_supported = logical(),
    target_edge_supported = logical(),
    
    same_species = logical(),
    same_developmental_context = logical(),
    
    all_nodes_supported = logical(),
    all_edges_supported = logical(),
    complete_path_engaged = logical(),
    
    status = character(),
    evidence_level = character(),
    
    stringsAsFactors = FALSE
  )
}


#' Reconstruct embedded directed circuits
#'
#' @param regulatory_overlay Validated regulatory overlay.
#' @param circuit_definition Resolved circuit definition.
#'
#' @return A circuit-engagement data frame.
#' @keywords internal
.fa_reconstruct_embedded_circuits <- function(
    regulatory_overlay,
    circuit_definition) {
  
  overlay <- .fa_validate_regulatory_overlay(
    regulatory_overlay
  )
  
  if (is.null(overlay)) {
    return(.fa_empty_circuit_result())
  }
  
  circuit_id <- .fa_definition_id(
    circuit_definition
  )
  
  if (identical(circuit_id, "none")) {
    return(.fa_empty_circuit_result())
  }
  
  nodes <- overlay$nodes
  edges <- overlay$edges
  
  get_definition_field <- function(
    definition,
    primary_name,
    fallback_name = NULL) {
    
    value <- definition[[primary_name]]
    
    if (
      is.null(value) &&
      !is.null(fallback_name)
    ) {
      value <- definition[[fallback_name]]
    }
    
    value
  }
  
  upstream_classes <- toupper(
    get_definition_field(
      circuit_definition,
      primary_name = "upstream_regulator_classes",
      fallback_name = "upstream_classes"
    )
  )
  
  intermediate_classes <- toupper(
    get_definition_field(
      circuit_definition,
      primary_name = "intermediate_regulator_classes",
      fallback_name = "intermediate_classes"
    )
  )
  
  target_classes <- toupper(
    get_definition_field(
      circuit_definition,
      primary_name = "biosynthesis_target_classes",
      fallback_name = "target_classes"
    )
  )
  
  if (
    length(upstream_classes) == 0L ||
    length(intermediate_classes) == 0L ||
    length(target_classes) == 0L
  ) {
    stop(
      paste0(
        "Circuit definition must provide non-empty upstream, ",
        "intermediate, and biosynthesis-target gene classes."
      ),
      call. = FALSE
    )
  }
  
  regulator_edges <- edges[
    edges$source_gene_class %in% upstream_classes &
      edges$target_gene_class %in% intermediate_classes,
    ,
    drop = FALSE
  ]
  
  target_edges <- edges[
    edges$source_gene_class %in% intermediate_classes &
      edges$target_gene_class %in% target_classes,
    ,
    drop = FALSE
  ]
  
  if (
    nrow(regulator_edges) == 0L ||
    nrow(target_edges) == 0L
  ) {
    return(.fa_empty_circuit_result())
  }
  
  candidates <- merge(
    regulator_edges,
    target_edges,
    by.x = c(
      "species",
      "developmental_context",
      "target_gene_id",
      "target_gene_class"
    ),
    by.y = c(
      "species",
      "developmental_context",
      "source_gene_id",
      "source_gene_class"
    ),
    suffixes = c(
      "_regulator",
      "_target"
    ),
    all = FALSE,
    sort = FALSE
  )
  
  if (nrow(candidates) == 0L) {
    return(.fa_empty_circuit_result())
  }
  
  find_node_support <- function(
    species,
    developmental_context,
    gene_id,
    gene_class) {
    
    matching <- nodes[
      nodes$species == species &
        nodes$developmental_context ==
        developmental_context &
        nodes$gene_id == gene_id &
        nodes$gene_class == gene_class,
      ,
      drop = FALSE
    ]
    
    if (nrow(matching) == 0L) {
      return(FALSE)
    }
    
    any(
      matching$node_supported,
      na.rm = TRUE
    )
  }
  
  result <- data.frame(
    species = candidates$species,
    developmental_context =
      candidates$developmental_context,
    
    circuit_id = circuit_id,
    
    upstream_gene_id =
      candidates$source_gene_id,
    
    upstream_gene_class =
      candidates$source_gene_class,
    
    intermediate_gene_id =
      candidates$target_gene_id,
    
    intermediate_gene_class =
      candidates$target_gene_class,
    
    target_gene_id =
      candidates$target_gene_id_target,
    
    target_gene_class =
      candidates$target_gene_class_target,
    
    regulator_edge_supported =
      candidates$edge_supported_regulator,
    
    target_edge_supported =
      candidates$edge_supported_target,
    
    stringsAsFactors = FALSE
  )
  
  result$upstream_node_supported <- vapply(
    seq_len(nrow(result)),
    function(i) {
      find_node_support(
        result$species[[i]],
        result$developmental_context[[i]],
        result$upstream_gene_id[[i]],
        result$upstream_gene_class[[i]]
      )
    },
    logical(1)
  )
  
  result$intermediate_node_supported <- vapply(
    seq_len(nrow(result)),
    function(i) {
      find_node_support(
        result$species[[i]],
        result$developmental_context[[i]],
        result$intermediate_gene_id[[i]],
        result$intermediate_gene_class[[i]]
      )
    },
    logical(1)
  )
  
  result$target_node_supported <- vapply(
    seq_len(nrow(result)),
    function(i) {
      find_node_support(
        result$species[[i]],
        result$developmental_context[[i]],
        result$target_gene_id[[i]],
        result$target_gene_class[[i]]
      )
    },
    logical(1)
  )
  
  result$same_species <- TRUE
  result$same_developmental_context <- TRUE
  
  result$all_nodes_supported <-
    result$upstream_node_supported &
    result$intermediate_node_supported &
    result$target_node_supported
  
  result$all_edges_supported <-
    result$regulator_edge_supported &
    result$target_edge_supported
  
  result$complete_path_engaged <-
    result$all_nodes_supported &
    result$all_edges_supported &
    result$same_species &
    result$same_developmental_context
  
  any_support <-
    result$upstream_node_supported |
    result$intermediate_node_supported |
    result$target_node_supported |
    result$regulator_edge_supported |
    result$target_edge_supported
  
  result$status <- ifelse(
    result$complete_path_engaged,
    "complete",
    ifelse(
      any_support,
      "partial",
      "unsupported"
    )
  )
  
  result$evidence_level <- ifelse(
    result$complete_path_engaged,
    "supported_directed_path",
    ifelse(
      result$all_nodes_supported,
      "nodes_supported_edges_incomplete",
      "incomplete_node_support"
    )
  )
  
  result$path_id <- paste(
    result$upstream_gene_id,
    result$intermediate_gene_id,
    result$target_gene_id,
    sep = "->"
  )
  
  result <- result[
    ,
    c(
      "species",
      "developmental_context",
      "circuit_id",
      "path_id",
      
      "upstream_gene_id",
      "upstream_gene_class",
      
      "intermediate_gene_id",
      "intermediate_gene_class",
      
      "target_gene_id",
      "target_gene_class",
      
      "upstream_node_supported",
      "intermediate_node_supported",
      "target_node_supported",
      
      "regulator_edge_supported",
      "target_edge_supported",
      
      "same_species",
      "same_developmental_context",
      
      "all_nodes_supported",
      "all_edges_supported",
      "complete_path_engaged",
      
      "status",
      "evidence_level"
    )
  ]
  
  unique(result)
}
