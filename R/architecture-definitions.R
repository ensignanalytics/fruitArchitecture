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
    version = "paper5-frozen-v1.1",
    
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
    
    # Reconstruct the complete Broad6 topology. Level 3A remains
    # restricted to the three PHMIES core interfaces declared below.
    interfaces = interface_universe,
    
    # Retain an explicit copy of the complete Broad6 interface universe
    # for downstream validation and provenance.
    interface_universe = interface_universe,
    
    # Explicit PHMIES requirements used for Level 3A and PHMIES class.
    level3a_interfaces = required_pairs,
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


#' #' Broad6 architecture definition
#'
#' Constructs the six-module Broad6 architecture definition while retaining
#' the PHMIES core for Level 3A and strict Level 3B reconstruction.
#'
#' @return A Broad6 architecture-definition list.
#' @keywords internal
#' @noRd
.broad6_architecture_definition <- function() {
  
  # Begin with the frozen Paper 5 definition so that any additional
  # versioned fields, thresholds, and metric settings are retained.
  definition <- .resolve_architecture_definition("paper5_frozen")
  
  modules <- c(
    "Circadian rhythm",
    "Plant hormone signal transduction",
    "MAPK signaling",
    "Information exchange",
    "Proteostasis",
    "RNA regulation"
  )
  
  aliases <- list(
    "Circadian rhythm" = c(
      "circadian rhythm",
      "circadian",
      "cr"
    ),
    
    "Plant hormone signal transduction" = c(
      "plant hormone signal transduction",
      "plant hormone signaling",
      "plant hormone signalling",
      "hormone signaling",
      "hormone signalling",
      "hormone",
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
      "information exchange system",
      "plant-pathogen interaction",
      "plant pathogen interaction",
      "defense",
      "signaling and communication",
      "ppi"
    ),
    
    "Proteostasis" = c(
      "proteostasis",
      "protein processing in endoplasmic reticulum",
      "protein processing in the endoplasmic reticulum",
      "protein processing in er",
      "snare interactions",
      "snare interactions in vesicular transport",
      "autophagy",
      "autophagy - other",
      "autophagy other",
      "sulfur relay system",
      "pper",
      "snare",
      "srs"
    ),
    
    "RNA regulation" = c(
      "rna regulation",
      "rna transport",
      "rna degradation",
      "rna processing",
      "mrna surveillance",
      "rna_t",
      "rna_d"
    )
  )
  
  # The established PHMIES core remains the Level 3A/3B core.
  core <- c(
    "Plant hormone signal transduction",
    "MAPK signaling",
    "Information exchange"
  )
  
  # Keep the three PHMIES interfaces first. This preserves compatibility
  # with any existing rules that identify them by position 1:3.
  core_interfaces <- data.frame(
    interface = c(
      "Hormone-MAPK",
      "Hormone-Information exchange",
      "MAPK-Information exchange"
    ),
    module_a = core[c(1, 1, 2)],
    module_b = core[c(2, 3, 3)],
    stringsAsFactors = FALSE
  )
  
  module_labels <- c(
    "Circadian rhythm" = "Circadian",
    "Plant hormone signal transduction" = "Hormone",
    "MAPK signaling" = "MAPK",
    "Information exchange" = "Information exchange",
    "Proteostasis" = "Proteostasis",
    "RNA regulation" = "RNA regulation"
  )
  
  all_pairs <- utils::combn(
    modules,
    2L,
    simplify = FALSE
  )
  
  # The core-core pairs are already represented above.
  additional_pairs <- Filter(
    function(pair) !all(pair %in% core),
    all_pairs
  )
  
  additional_interfaces <- do.call(
    rbind,
    lapply(
      additional_pairs,
      function(pair) {
        data.frame(
          interface = paste(
            unname(module_labels[pair]),
            collapse = "-"
          ),
          module_a = pair[[1]],
          module_b = pair[[2]],
          stringsAsFactors = FALSE
        )
      }
    )
  )
  
  interfaces <- rbind(
    core_interfaces,
    additional_interfaces
  )
  
  rownames(interfaces) <- NULL
  
  # Canonical identifiers distinguish the three PHMIES Level 3A
  # requirements from the 12 additional Broad6 topology edges.
  core_interface_ids <- .fa_interface_id(
    core_interfaces$module_a,
    core_interfaces$module_b
  )
  
  definition$name <- "broad6"
  definition$version <- "0.2.1"
  definition$modules <- modules
  definition$aliases <- aliases
  definition$core_modules <- core
  definition$interfaces <- interfaces
  definition$level3a_interface_ids <- core_interface_ids
  
  # Preserve explicit Level 3A fields while ensuring that they continue
  # to refer only to the three PHMIES core interfaces.
  level3a_fields <- intersect(
    c(
      "level3a_interfaces",
      "level3a_required_interfaces",
      "required_interfaces",
      "level3a_requirements"
    ),
    names(definition)
  )
  
  for (field in level3a_fields) {
    current_value <- definition[[field]]
    
    if (is.character(current_value)) {
      definition[[field]] <- core_interfaces$interface
    } else if (is.numeric(current_value)) {
      definition[[field]] <- seq_len(nrow(core_interfaces))
    } else if (is.data.frame(current_value)) {
      definition[[field]] <- core_interfaces
    }
  }
  
  definition
}
#' Resolve an architecture definition
#'
#' @param x Either `NULL`, the name of a built-in architecture definition,
#'   or a custom architecture-definition list.
#'
#' @return A validated architecture-definition list.
#' @keywords internal
#' Broad6 architecture definition
#'
#' Collapses the conserved fruit-architecture pathways into six broad
#' functional modules while retaining the PHMIES core for Level 3A and
#' strict Level 3B reconstruction.
#'
#' @return A Broad6 architecture-definition list.
#' @keywords internal
.resolve_architecture_definition <- function(x = NULL) {
  # Broad6 compatibility name
  if (
    is.character(x) &&
    length(x) == 1L &&
    identical(tolower(trimws(x)), "broad6")
  ) {
    return(.broad6_architecture_definition())
  }
  
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
        "`architecture_definition` must be one of: PHMIES, broad6, paper5_frozen; or a custom definition list."
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
