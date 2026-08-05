test_that("both public entry points expose definition arguments", {
  
  required_arguments <- c(
    "architecture_definition",
    "module_definition",
    "circuit_definition",
    "regulatory_overlay"
  )
  
  expect_true(
    all(
      required_arguments %in%
        names(formals(fruitArchitecture))
    )
  )
  
  expect_true(
    all(
      required_arguments %in%
        names(formals(fruitArchitectureFromDEG))
    )
  )
})


test_that("public entry-point defaults preserve legacy PHMIES behavior", {
  
  count_defaults <- formals(fruitArchitecture)
  deg_defaults <- formals(fruitArchitectureFromDEG)
  
  expect_identical(
    count_defaults$architecture_definition,
    "PHMIES"
  )
  
  expect_null(
    count_defaults$module_definition
  )
  
  expect_identical(
    count_defaults$circuit_definition,
    "none"
  )
  
  expect_null(
    count_defaults$regulatory_overlay
  )
  
  expect_identical(
    deg_defaults$architecture_definition,
    "PHMIES"
  )
  
  expect_null(
    deg_defaults$module_definition
  )
  
  expect_identical(
    deg_defaults$circuit_definition,
    "none"
  )
  
  expect_null(
    deg_defaults$regulatory_overlay
  )
})


test_that("legacy definition layers resolve correctly", {
  
  definitions <- .fa_resolve_definitions()
  
  expect_identical(
    .fa_definition_id(
      definitions$module_definition
    ),
    "core10"
  )
  
  expect_identical(
    .fa_definition_id(
      definitions$architecture_definition
    ),
    "PHMIES"
  )
  
  expect_identical(
    .fa_definition_id(
      definitions$circuit_definition
    ),
    "none"
  )
})


test_that("Paper 5 definition layers resolve correctly", {
  
  definitions <- .fa_resolve_definitions(
    module_definition = "broad6",
    architecture_definition = "paper5_frozen",
    circuit_definition = "autocatalytic_ethylene_v1"
  )
  
  expect_identical(
    .fa_definition_id(
      definitions$module_definition
    ),
    "broad6"
  )
  
  expect_identical(
    .fa_definition_id(
      definitions$architecture_definition
    ),
    "paper5_frozen"
  )
  
  expect_identical(
    .fa_definition_id(
      definitions$circuit_definition
    ),
    "autocatalytic_ethylene_v1"
  )
})


test_that("incompatible architecture and module definitions fail", {
  
  expect_error(
    .fa_resolve_definitions(
      module_definition = "core10",
      architecture_definition = "paper5_frozen"
    ),
    "requires module_definition = 'broad6'",
    fixed = TRUE
  )
})