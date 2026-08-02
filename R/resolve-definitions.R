.fa_resolve_definitions <- function(
    module_definition = NULL,
    architecture_definition = "PHMIES",
    circuit_definition = "none") {
  
  architecture_definition <- match.arg(
    architecture_definition,
    choices = names(.fa_architecture_definitions)
  )
  
  circuit_definition <- match.arg(
    circuit_definition,
    choices = names(.fa_circuit_definitions)
  )
  
  architecture <- .fa_architecture_definitions[
    [architecture_definition]
  ]
  
  if (is.null(module_definition)) {
    module_definition <- architecture$module_definition
  }
  
  module_definition <- match.arg(
    module_definition,
    choices = names(.fa_module_definitions)
  )
  
  expected_module_definition <- architecture$module_definition
  
  if (!identical(
    module_definition,
    expected_module_definition
  )) {
    stop(
      sprintf(
        paste0(
          "Architecture definition '%s' requires ",
          "module_definition = '%s'; received '%s'."
        ),
        architecture_definition,
        expected_module_definition,
        module_definition
      ),
      call. = FALSE
    )
  }
  
  list(
    module_definition = .fa_module_definitions[
      [module_definition]
    ],
    architecture_definition = architecture,
    circuit_definition = .fa_circuit_definitions[
      [circuit_definition]
    ]
  )
}
