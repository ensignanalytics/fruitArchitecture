# ============================================================
# Combined definition resolver
#
# Resolves the module, architecture, and circuit definitions
# selected through the public fruitArchitecture() API.
# ============================================================


#' Materialize a stored definition
#'
#' Definition registries may contain either a definition list or a
#' constructor function that returns a fresh definition list.
#'
#' @param x A definition list or constructor function.
#'
#' @return A definition list.
#' @keywords internal
.fa_materialize_definition <- function(x) {
  
  if (is.function(x)) {
    return(x())
  }
  
  x
}


#' Return a definition identifier
#'
#' @param definition A definition list.
#' @param fallback Value returned when neither `id` nor `name` exists.
#'
#' @return A single character identifier.
#' @keywords internal
.fa_definition_id <- function(
    definition,
    fallback = NA_character_) {
  
  if (!is.null(definition$id)) {
    return(as.character(definition$id))
  }
  
  if (!is.null(definition$name)) {
    return(as.character(definition$name))
  }
  
  fallback
}


#' Resolve fruitArchitecture definition layers
#'
#' @param module_definition Either `NULL`, `"core10"`, or `"broad6"`.
#' @param architecture_definition Either `"PHMIES"`,
#'   `"paper5_frozen"`, or a custom architecture-definition list.
#' @param circuit_definition Either `"none"` or a supported directed
#'   circuit definition.
#'
#' @return A named list containing the resolved module,
#'   architecture, and circuit definitions.
#' @keywords internal
.fa_resolve_definitions <- function(
    module_definition = NULL,
    architecture_definition = "PHMIES",
    circuit_definition = "none") {
  
  # Use the established architecture resolver because the architecture
  # registry stores constructor functions rather than static lists.
  architecture <- .resolve_architecture_definition(
    architecture_definition
  )
  
  expected_module_definition <- architecture$module_definition
  
  if (is.null(expected_module_definition)) {
    expected_module_definition <- "custom"
  }
  
  if (is.null(module_definition)) {
    module_definition <- expected_module_definition
  }
  
  if (
    !is.character(module_definition) ||
    length(module_definition) != 1L ||
    is.na(module_definition) ||
    !nzchar(module_definition)
  ) {
    stop(
      "`module_definition` must be one non-empty character value.",
      call. = FALSE
    )
  }
  
  # Preserve support for custom architecture-definition lists.
  if (identical(module_definition, "custom")) {
    
    module <- list(
      id = "custom",
      version = if (!is.null(architecture$version)) {
        architecture$version
      } else {
        NA_character_
      },
      modules = architecture$modules,
      aliases = if (!is.null(architecture$aliases)) {
        architecture$aliases
      } else {
        list()
      }
    )
    
  } else {
    
    supported_module_definitions <- names(
      .fa_module_definitions
    )
    
    if (!module_definition %in% supported_module_definitions) {
      stop(
        "`module_definition` must be one of: ",
        paste(
          supported_module_definitions,
          collapse = ", "
        ),
        ".",
        call. = FALSE
      )
    }
    
    if (
      !identical(expected_module_definition, "custom") &&
      !identical(
        module_definition,
        expected_module_definition
      )
    ) {
      stop(
        sprintf(
          paste0(
            "Architecture definition '%s' requires ",
            "module_definition = '%s'; received '%s'."
          ),
          .fa_definition_id(
            architecture,
            fallback = "custom"
          ),
          expected_module_definition,
          module_definition
        ),
        call. = FALSE
      )
    }
    
    module <- .fa_materialize_definition(
      .fa_module_definitions[[module_definition]]
    )
  }
  
  supported_circuit_definitions <- names(
    .fa_circuit_definitions
  )
  
  if (
    !is.character(circuit_definition) ||
    length(circuit_definition) != 1L ||
    is.na(circuit_definition) ||
    !nzchar(circuit_definition) ||
    !circuit_definition %in% supported_circuit_definitions
  ) {
    stop(
      "`circuit_definition` must be one of: ",
      paste(
        supported_circuit_definitions,
        collapse = ", "
      ),
      ".",
      call. = FALSE
    )
  }
  
  circuit <- .fa_materialize_definition(
    .fa_circuit_definitions[[circuit_definition]]
  )
  
  list(
    module_definition = module,
    architecture_definition = architecture,
    circuit_definition = circuit
  )
}
