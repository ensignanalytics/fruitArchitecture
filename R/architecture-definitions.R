# ============================================================
# Architecture definitions
#
# This file preserves the frozen fruitArchitecture v0.1 PHMIES
# definition while adding the Paper 5 frozen Broad6 definition.
# ============================================================


#' Default PHMIES architecture definition
#'
#' This definition preserves the original fruitArchitecture v0.1
#' module names, aliases, interfaces, weights, and classification
#' behavior.
#'
#' @return A named list containing module names, aliases, pairwise
#'   interfaces, Level 3A requirements, and metric weights.
#' @keywords internal
.default_architecture_definition <- function() {
  
  modules <- c(
    "Circadian rhythm",
    "Plant hormone signal transduction",
    "MAPK signaling",
    "Information exchange",
    "Protein processing in endoplasmic reticulum",
    "RNA transport",
    "RNA degradation",
    "SNARE interactions",
    "Autophagy",
    "Sulfur relay system"
  )
  
  aliases <- list(
    "Circadian rhythm" = c(
      "circadian rhythm",
      "cr"
    ),
    
    "Plant hormone signal transduction" = c(
      "plant hormone signal transduction",
      "plant hormone signaling",
      "hormone signaling",
      "phst"
    ),
    
    "MAPK signaling" = c(
      "mapk signaling",
      "mapk signalling",
      "mapk signaling pathway",
      "mapk"
    ),
    
    "Information exchange" = c(
      "information exchange",
      "plant-pathogen interaction",
      "plant pathogen interaction",
      "defense",
      "ppi"
    ),
    
    "Protein processing in endoplasmic reticulum" = c(
      "protein processing in endoplasmic reticulum",
      "protein processing in the endoplasmic reticulum",
      "protein processing in er",
      "pper"
    ),
    
    "RNA transport" = c(
      "rna transport",
      "rna_t"
    ),
    
    "RNA degradation" = c(
      "rna degradation",
      "rna_d"
    ),
    
    "SNARE interactions" = c(
      "snare interactions",
      "snare interactions in vesicular transport",
      "snare"
    ),
    
    "Autophagy" = c(
      "autophagy",
      "autophagy - other",
      "autophagy other"
    ),
    
    "Sulfur relay system" = c(
      "sulfur relay system",
      "srs"
    )
  )
  
  core <- c(
    "Plant hormone signal transduction",
    "MAPK signaling",
    "Information exchange"
  )
  
  interfaces <- data.frame(
    interface = c(
      "Hormone-MAPK",
      "Hormone-Information exchange",
      "MAPK-Information exchange"
    ),
    interface_id = c(
      "Hormone--MAPK",
      "Hormone--Information Exchange",
      "Information Exchange--MAPK"
    ),
    module_a = core[c(1, 1, 2)],
    module_b = core[c(2, 3, 3)],
    stringsAsFactors = FALSE
  )
  
  list(
    name = "PHMIES",
    
    # Preserve the original definition version.
    version = "0.1.2",
    
    definition_status = "frozen",
    module_definition = "core10",
    circuit_definition = "none",
    
    description = paste(
      "Original PHMIES architecture definition retained for complete",
      "backward compatibility with fruitArchitecture v0.1."
    ),
    
    modules = modules,
    aliases = aliases,
    core_modules = core,
    interfaces = interfaces,
    
    level3a_interface_ids = interfaces$interface_id,
    level3b_modules = core,
    
    extended_interfaces_affect_class = FALSE,
    
    weights = list(
      level1 = 0.25,
      level2 = 0.35,
      level3a = 0.20,
      level3b = 0.20
    )
  )
}


#' Paper 5 frozen Broad6 architecture definition
#'
#' This definition expands architecture reconstruction to six broad
#' organizational modules and all 15 possible pairwise interfaces.
#' The established PHMIES interfaces remain the requirements for
#' Level 3A and the PHMIES Class I-IV system.
#'
#' @return A named list containing Broad6 modules, aliases, the full
#'   interface universe, Level 3A requirements, Level 3B requirements,
#'   and metric weights.
#' @keywords internal
.paper5_architecture_definition <- function() {
  
  modules <- c(
    "Circadian",
    "Hormone",
    "MAPK",
    "Information Exchange",
    "RNA regulation",
    "Proteostasis"
  )
  
  aliases <- list(
    "Circadian" = c(
      "circadian",
      "circadian rhythm",
      "cr"
    ),
    
    "Hormone" = c(
      "hormone",
      "hormone signaling",
      "plant hormone signaling",
      "plant hormone signal transduction",
      "phst"
    ),
    
    "MAPK" = c(
      "mapk",
      "mapk signaling",
      "mapk signalling",
      "mapk signaling pathway"
    ),
    
    "Information Exchange" = c(
      "information exchange",
      "information exchange system",
      "plant-pathogen interaction",
      "plant pathogen interaction",
      "defense",
      "cellular communication",
      "environmental sensing",
      "ppi"
    ),
    
    "RNA regulation" = c(
      "rna regulation",
      "rna transport",
      "rna degradation",
      "rna_t",
      "rna_d"
    ),
    
    "Proteostasis" = c(
      "proteostasis",
      "protein processing in endoplasmic reticulum",
      "protein processing in the endoplasmic reticulum",
      "protein processing in er",
      "autophagy",
      "snare interactions",
      "snare interactions in vesicular transport",
      "sulfur relay system",
      "pper",
      "snare",
      "srs"
    )
  )
  
  core <- c(
    "Hormone",
    "MAPK",
    "Information Exchange"
  )
  
  # Generate all 15 possible pairwise interfaces among six modules.
  interface_pairs <- utils::combn(
    modules,
    2L,
    simplify = FALSE
  )
  
  interface_universe <- data.frame(
    module_a = vapply(
      interface_pairs,
      `[[`,
      character(1),
      1L
    ),
    module_b = vapply(
      interface_pairs,
      `[[`,
      character(1),
      2L
    ),
    stringsAsFactors = FALSE
  )
  
  # Create orientation-independent canonical identifiers.
  interface_universe$interface_id <- vapply(
    seq_len(nrow(interface_universe)),
    function(i) {
      paste(
        sort(
          c(
            interface_universe$module_a[[i]],
            interface_universe$module_b[[i]]
          )
        ),
        collapse = "--"
      )
    },
    character(1)
  )
  
  interface_universe$interface <- paste(
    interface_universe$module_a,
    interface_universe$module_b,
    sep = "-"
  )
  
  # The three PHMIES interfaces remain the Level 3A requirements.
  required_pairs <- data.frame(
    interface = c(
      "Hormone-MAPK",
      "Hormone-Information Exchange",
      "MAPK-Information Exchange"
    ),
    module_a = core[c(1, 1, 2)],
    module_b = core[c(2, 3, 3)],
    stringsAsFactors = FALSE
  )
  
  required_pairs$interface_id <- vapply(
    seq_len(nrow(required_pairs)),
    function(i) {
      paste(
        sort(
          c(
            required_pairs$module_a[[i]],
            required_pairs$module_b[[i]]
          )
        ),
        collapse = "--"
      )
    },
    character(1)
  )
  
  list(
    name = "paper5_frozen",
    version = "paper5-frozen-v1",
    
    definition_status = "frozen",
    module_definition = "broad6",
    circuit_definition = "autocatalytic_ethylene_v1",
    
    description = paste(
      "Frozen Paper 5 architecture definition using Broad6 modules,",
      "all 15 possible pairwise interfaces, and PHMIES-centered",
      "Level 3A and Level 3B classification."
    ),
    
    modules = modules,
    aliases = aliases,
    core_modules = core,
    
    # Required PHMIES interfaces used for Level 3A classification.
    interfaces = required_pairs,
    
    # Complete Broad6 interface universe used for expanded topology.
    interface_universe = interface_universe,
    
    level3a_interface_ids = required_pairs$interface_id,
    level3b_modules = core,
    
    # Additional interfaces describe expanded organization but do not
    # independently change the established PHMIES Class I-IV call.
    extended_interfaces_affect_class = FALSE,
    
    weights = list(
      level1 = 0.25,
      level2 = 0.35,
      level3a = 0.20,
      level3b = 0.20
    )
  )
}


# Registry of built-in architecture definitions.
#
# Constructor functions are stored rather than evaluated list objects so
# each call receives a fresh definition object.
.fa_architecture_definitions <- list(
  PHMIES = .default_architecture_definition,
  paper5_frozen = .paper5_architecture_definition
)


#' Resolve an architecture definition
#'
#' @param x Either `NULL`, the name of a built-in architecture definition,
#'   or a custom architecture-definition list.
#'
#' @return A validated architecture-definition list.
#' @keywords internal
.resolve_architecture_definition <- function(x = NULL) {
  
  if (is.null(x)) {
    x <- "PHMIES"
  }
  
  if (is.character(x)) {
    
    if (length(x) != 1L || is.na(x) || !nzchar(x)) {
      stop(
        "`architecture_definition` must be one non-empty value.",
        call. = FALSE
      )
    }
    
    supported <- names(.fa_architecture_definitions)
    
    if (!x %in% supported) {
      stop(
        "`architecture_definition` must be one of: ",
        paste(supported, collapse = ", "),
        "; or a custom definition list.",
        call. = FALSE
      )
    }
    
    return(
      .fa_architecture_definitions[[x]]()
    )
  }
  
  if (!is.list(x)) {
    stop(
      paste0(
        "`architecture_definition` must be 'PHMIES', ",
        "'paper5_frozen', or a definition list."
      ),
      call. = FALSE
    )
  }
  
  # Retain the original custom-definition requirements so existing
  # user-supplied definitions continue to work.
  required <- c(
    "name",
    "modules",
    "core_modules",
    "interfaces",
    "weights"
  )
  
  missing <- setdiff(
    required,
    names(x)
  )
  
  if (length(missing) > 0L) {
    stop(
      "Custom architecture definition is missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  
  # Add new metadata fields to older custom definitions without making
  # those fields mandatory.
  if (is.null(x$module_definition)) {
    x$module_definition <- "custom"
  }
  
  if (is.null(x$circuit_definition)) {
    x$circuit_definition <- "none"
  }
  
  if (is.null(x$level3b_modules)) {
    x$level3b_modules <- x$core_modules
  }
  
  if (is.null(x$extended_interfaces_affect_class)) {
    x$extended_interfaces_affect_class <- FALSE
  }
  
  x
}
