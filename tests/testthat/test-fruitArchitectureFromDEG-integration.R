# ============================================================
# End-to-end fruitArchitectureFromDEG() integration tests
#
# Verifies:
#   1. PHMIES + no overlay preserves legacy behavior.
#   2. paper5_frozen + no overlay returns not_evaluated.
#   3. paper5_frozen + complete overlay returns an engaged
#      autocatalytic ethylene circuit.
# ============================================================


make_paper5_integration_data <- function() {
  
  deg_table <- data.frame(
    gene_id = c(
      "circadian_1",
      "hormone_1",
      "mapk_1",
      "information_1",
      "rna_1",
      "proteostasis_1",
      "core_shared_1",
      "EIN3_1",
      "RIN_1",
      "ACS_1"
    ),
    
    log2_fold_change = c(
      2.0,
      2.1,
      2.2,
      2.3,
      2.4,
      2.5,
      2.6,
      2.7,
      2.8,
      2.9
    ),
    
    adjusted_p_value = rep(
      0.001,
      10
    ),
    
    stringsAsFactors = FALSE
  )
  
  annotation <- data.frame(
    gene_id = c(
      "circadian_1",
      "hormone_1",
      "mapk_1",
      "information_1",
      "rna_1",
      "proteostasis_1",
      
      # Triple-overlap gene used to exercise PHMIES Level 3B
      # inside the Broad6 Paper 5 architecture.
      "core_shared_1",
      "core_shared_1",
      "core_shared_1",
      
      # Embedded-circuit genes remain annotation eligible.
      "EIN3_1",
      "RIN_1",
      "ACS_1"
    ),
    
    module = c(
      "Circadian",
      "Hormone",
      "MAPK",
      "Information Exchange",
      "RNA regulation",
      "Proteostasis",
      
      "Hormone",
      "MAPK",
      "Information Exchange",
      
      "Hormone",
      "Hormone",
      "Hormone"
    ),
    
    stringsAsFactors = FALSE
  )
  
  list(
    deg_table = deg_table,
    annotation = annotation
  )
}


make_complete_ethylene_overlay <- function() {
  
  nodes <- data.frame(
    species = rep(
      "Synthetic fruit",
      3
    ),
    
    developmental_context = rep(
      "Ripening transition",
      3
    ),
    
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
      TRUE
    ),
    
    evidence_type = c(
      "functional",
      "functional",
      "functional"
    ),
    
    evidence_source = c(
      "integration_test",
      "integration_test",
      "integration_test"
    ),
    
    stringsAsFactors = FALSE
  )
  
  edges <- data.frame(
    species = rep(
      "Synthetic fruit",
      2
    ),
    
    developmental_context = rep(
      "Ripening transition",
      2
    ),
    
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
      TRUE
    ),
    
    evidence_type = c(
      "functional",
      "functional"
    ),
    
    evidence_source = c(
      "integration_test",
      "integration_test"
    ),
    
    stringsAsFactors = FALSE
  )
  
  list(
    nodes = nodes,
    edges = edges
  )
}


test_that(
  "PHMIES without an overlay preserves legacy behavior",
  {
    
    example_data <- fruitArchitectureExampleData()
    
    legacy_default <- fruitArchitectureFromDEG(
      deg_table = example_data$deg_table,
      annotation = example_data$annotation,
      species = "Synthetic legacy integration test",
      alpha = 0.05,
      log2fc_threshold = 1,
      n_permutations = 25L,
      seed = 1234L
    )
    
    legacy_explicit <- fruitArchitectureFromDEG(
      deg_table = example_data$deg_table,
      annotation = example_data$annotation,
      species = "Synthetic legacy integration test",
      alpha = 0.05,
      log2fc_threshold = 1,
      
      architecture_definition = "PHMIES",
      module_definition = "core10",
      circuit_definition = "none",
      regulatory_overlay = NULL,
      
      n_permutations = 25L,
      seed = 1234L
    )
    
    expect_s3_class(
      legacy_default,
      "fruit_architecture"
    )
    
    expect_s3_class(
      legacy_explicit,
      "fruit_architecture"
    )
    
    # The default call must remain scientifically equivalent to
    # an explicit frozen-v0.1 call.
    expect_identical(
      legacy_default$architecture_class,
      legacy_explicit$architecture_class
    )
    
    expect_identical(
      legacy_default$level3a_present,
      legacy_explicit$level3a_present
    )
    
    expect_identical(
      legacy_default$level3b_count,
      legacy_explicit$level3b_count
    )
    
    expect_equal(
      legacy_default$module_summary,
      legacy_explicit$module_summary
    )
    
    expect_equal(
      legacy_default$interface_summary,
      legacy_explicit$interface_summary
    )
    
    expect_equal(
      legacy_default$metrics,
      legacy_explicit$metrics
    )
    
    expect_identical(
      legacy_default$definition_metadata$
        architecture_definition,
      "PHMIES"
    )
    
    expect_identical(
      legacy_default$definition_metadata$
        module_definition,
      "core10"
    )
    
    expect_identical(
      legacy_default$definition_metadata$
        circuit_definition,
      "none"
    )
    
    expect_false(
      legacy_default$definition_metadata$
        regulatory_overlay_supplied
    )
    
    expect_null(
      legacy_default$regulatory_overlay
    )
    
    expect_null(
      legacy_default$embedded_circuits
    )
    
    expect_null(
      legacy_default$
        augmented_regulatory_architecture
    )
  }
)


test_that(
  paste(
    "paper5_frozen without an overlay reports",
    "the ethylene circuit as not evaluated"
  ),
  {
    
    integration_data <-
      make_paper5_integration_data()
    
    result <- fruitArchitectureFromDEG(
      deg_table =
        integration_data$deg_table,
      
      annotation =
        integration_data$annotation,
      
      species = "Synthetic fruit",
      
      alpha = 0.05,
      log2fc_threshold = 1,
      
      module_definition = "broad6",
      architecture_definition = "paper5_frozen",
      circuit_definition =
        "autocatalytic_ethylene_v1",
      
      regulatory_overlay = NULL,
      
      n_permutations = 25L,
      seed = 1234L
    )
    
    expect_s3_class(
      result,
      "fruit_architecture"
    )
    
    expect_identical(
      result$definition_metadata$
        module_definition,
      "broad6"
    )
    
    expect_identical(
      result$definition_metadata$
        architecture_definition,
      "paper5_frozen"
    )
    
    expect_identical(
      result$definition_metadata$
        circuit_definition,
      "autocatalytic_ethylene_v1"
    )
    
    expect_false(
      result$definition_metadata$
        regulatory_overlay_supplied
    )
    
    # The annotation-derived architecture is still evaluated.
    expect_type(
      result$baseline_annotation_architecture,
      "list"
    )
    
    expect_null(
      result$regulatory_overlay
    )
    
    expect_s3_class(
      result$embedded_circuits,
      "data.frame"
    )
    
    expect_equal(
      nrow(result$embedded_circuits),
      1L
    )
    
    expect_identical(
      result$embedded_circuits$
        circuit_id[[1]],
      "autocatalytic_ethylene_v1"
    )
    
    expect_identical(
      result$embedded_circuits$
        status[[1]],
      "not_evaluated"
    )
    
    expect_match(
      result$embedded_circuits$
        reason[[1]],
      "No regulatory overlay",
      fixed = TRUE
    )
    
    expect_null(
      result$augmented_regulatory_architecture
    )
  }
)


test_that(
  paste(
    "paper5_frozen with a complete overlay produces",
    "an engaged augmented ethylene circuit"
  ),
  {
    
    integration_data <-
      make_paper5_integration_data()
    
    complete_overlay <-
      make_complete_ethylene_overlay()
    
    result <- fruitArchitectureFromDEG(
      deg_table =
        integration_data$deg_table,
      
      annotation =
        integration_data$annotation,
      
      species = "Synthetic fruit",
      
      alpha = 0.05,
      log2fc_threshold = 1,
      
      module_definition = "broad6",
      architecture_definition = "paper5_frozen",
      circuit_definition =
        "autocatalytic_ethylene_v1",
      
      regulatory_overlay =
        complete_overlay,
      
      n_permutations = 25L,
      seed = 1234L
    )
    
    expect_s3_class(
      result,
      "fruit_architecture"
    )
    
    expect_true(
      result$definition_metadata$
        regulatory_overlay_supplied
    )
    
    expect_type(
      result$baseline_annotation_architecture,
      "list"
    )
    
    expect_type(
      result$regulatory_overlay,
      "list"
    )
    
    expect_s3_class(
      result$regulatory_overlay$nodes,
      "data.frame"
    )
    
    expect_s3_class(
      result$regulatory_overlay$edges,
      "data.frame"
    )
    
    expect_s3_class(
      result$embedded_circuits,
      "data.frame"
    )
    
    expect_equal(
      nrow(result$embedded_circuits),
      1L
    )
    
    expect_identical(
      result$embedded_circuits$
        path_id[[1]],
      "EIN3_1->RIN_1->ACS_1"
    )
    
    expect_true(
      result$embedded_circuits$
        all_nodes_supported[[1]]
    )
    
    expect_true(
      result$embedded_circuits$
        all_edges_supported[[1]]
    )
    
    expect_true(
      result$embedded_circuits$
        complete_path_engaged[[1]]
    )
    
    expect_identical(
      result$embedded_circuits$
        status[[1]],
      "complete"
    )
    
    expect_identical(
      result$embedded_circuits$
        evidence_level[[1]],
      "supported_directed_path"
    )
    
    expect_type(
      result$augmented_regulatory_architecture,
      "list"
    )
    
    expect_identical(
      result$augmented_regulatory_architecture$
        complete_circuit_n,
      1L
    )
    
    expect_true(
      result$augmented_regulatory_architecture$
        any_complete_circuit
    )
    
    expect_equal(
      result$augmented_regulatory_architecture$
        embedded_circuits,
      result$embedded_circuits
    )
    
    expect_equal(
      result$augmented_regulatory_architecture$
        baseline,
      result$baseline_annotation_architecture
    )
  }
)
