make_test_overlay <- function(
    second_edge_supported = TRUE,
    target_supported = TRUE) {
  
  list(
    nodes = data.frame(
      species = rep("Tomato", 3),
      developmental_context =
        rep("Ripening", 3),
      
      gene_id = c(
        "EIN3_1",
        "RIN_1",
        "ACS_1"
      ),
      
      gene_class = c(
        "EIN3",
        "RIN",
        "ACS"
      ),
      
      node_supported = c(
        TRUE,
        TRUE,
        target_supported
      ),
      
      evidence_type = rep(
        "functional",
        3
      ),
      
      evidence_source = rep(
        "test",
        3
      ),
      
      stringsAsFactors = FALSE
    ),
    
    edges = data.frame(
      species = rep("Tomato", 2),
      developmental_context =
        rep("Ripening", 2),
      
      source_gene_id = c(
        "EIN3_1",
        "RIN_1"
      ),
      
      target_gene_id = c(
        "RIN_1",
        "ACS_1"
      ),
      
      source_gene_class = c(
        "EIN3",
        "RIN"
      ),
      
      target_gene_class = c(
        "RIN",
        "ACS"
      ),
      
      edge_supported = c(
        TRUE,
        second_edge_supported
      ),
      
      evidence_type = rep(
        "functional",
        2
      ),
      
      evidence_source = rep(
        "test",
        2
      ),
      
      stringsAsFactors = FALSE
    )
  )
}

test_that("edges from different contexts do not form a circuit", {
  
  overlay <- make_test_overlay()
  
  overlay$edges$developmental_context[[2]] <-
    "Different context"
  
  definition <-
    .fa_circuit_definitions[["autocatalytic_ethylene_v1"]]
  
  result <-
    .fa_reconstruct_embedded_circuits(
      regulatory_overlay = overlay,
      circuit_definition = definition
    )
  
  expect_equal(nrow(result), 0L)
})


test_that("edges from different species do not form a circuit", {
  
  overlay <- make_test_overlay()
  
  overlay$edges$species[[2]] <- "Papaya"
  
  definition <-
    .fa_circuit_definitions[["autocatalytic_ethylene_v1"]]
  
  result <-
    .fa_reconstruct_embedded_circuits(
      regulatory_overlay = overlay,
      circuit_definition = definition
    )
  
  expect_equal(nrow(result), 0L)
})

test_that("complete ethylene circuit is engaged", {
  
  definition <-
    .fa_circuit_definitions[["autocatalytic_ethylene_v1"]]
  
  result <-
    .fa_reconstruct_embedded_circuits(
      regulatory_overlay =
        make_test_overlay(),
      
      circuit_definition =
        definition
    )
  
  expect_equal(
    nrow(result),
    1L
  )
  
  expect_true(
    result$complete_path_engaged[[1]]
  )
  
  expect_identical(
    result$status[[1]],
    "complete"
  )
})


test_that("missing directed edge prevents engagement", {
  
  definition <-
    .fa_circuit_definitions[["autocatalytic_ethylene_v1"]]
  
  result <-
    .fa_reconstruct_embedded_circuits(
      regulatory_overlay =
        make_test_overlay(
          second_edge_supported = FALSE
        ),
      
      circuit_definition =
        definition
    )
  
  expect_false(
    result$complete_path_engaged[[1]]
  )
  
  expect_identical(
    result$status[[1]],
    "partial"
  )
})


test_that("unsupported target prevents engagement", {
  
  definition <-
    .fa_circuit_definitions[["autocatalytic_ethylene_v1"]]
  
  result <-
    .fa_reconstruct_embedded_circuits(
      regulatory_overlay =
        make_test_overlay(
          target_supported = FALSE
        ),
      
      circuit_definition =
        definition
    )
  
  expect_false(
    result$complete_path_engaged[[1]]
  )
})