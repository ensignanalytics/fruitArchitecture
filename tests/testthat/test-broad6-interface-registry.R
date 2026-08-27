test_that("Broad6 creates all 15 pairwise interfaces", {
  
  registry <- .fa_broad6_interfaces()
  
  expect_s3_class(registry, "data.frame")
  expect_equal(nrow(registry), 15L)
  
  expect_equal(
    length(unique(registry$interface_id)),
    15L
  )
  
  expect_true(
    all(
      c(
        "Circadian--Hormone",
        "Circadian--Proteostasis",
        "Hormone--MAPK",
        "Hormone--Information Exchange",
        "Information Exchange--MAPK"
      ) %in% registry$interface_id
    )
  )
})


test_that("Paper 5 Level 3A interfaces exist in Broad6", {
  
  registry <- .fa_broad6_interfaces()
  
  definition <- .resolve_architecture_definition(
    "paper5_frozen"
  )

  expect_equal(nrow(definition$interfaces), 15L)
  expect_equal(nrow(definition$interface_universe), 15L)
  expect_equal(length(definition$level3a_interface_ids), 3L)
  expect_setequal(
    .fa_interface_id(definition$interfaces$module_a, definition$interfaces$module_b),
    definition$interface_universe$interface_id
  )
  
  expect_true(
    all(
      definition$level3a_interface_ids %in%
        registry$interface_id
    )
  )
})


test_that("Broad6 interface identifiers are orientation independent", {
  
  expect_identical(
    .fa_interface_id(
      "MAPK",
      "Information Exchange"
    ),
    "Information Exchange--MAPK"
  )
  
  expect_identical(
    .fa_interface_id(
      "Information Exchange",
      "MAPK"
    ),
    "Information Exchange--MAPK"
  )
})

test_that("Broad6 Level 3A uses only the three declared PHMIES interfaces", {
  definition <- .resolve_architecture_definition("broad6")

  expect_equal(nrow(definition$interfaces), 15L)
  expect_equal(length(definition$level3a_interface_ids), 3L)
  definition_interface_ids <- .fa_interface_id(
    definition$interfaces$module_a,
    definition$interfaces$module_b
  )
  expect_true(
    all(definition$level3a_interface_ids %in% definition_interface_ids)
  )

  deg <- data.frame(
    gene_id = c(
      "hm", "hi", "mi",
      "circadian_only", "rna_only", "proteostasis_only"
    ),
    log2_fold_change = rep(2, 6),
    adjusted_p_value = rep(0.001, 6),
    stringsAsFactors = FALSE
  )

  annotation <- data.frame(
    gene_id = c(
      "hm", "hm",
      "hi", "hi",
      "mi", "mi",
      "circadian_only",
      "rna_only",
      "proteostasis_only"
    ),
    module = c(
      "Plant hormone signal transduction", "MAPK signaling",
      "Plant hormone signal transduction", "Information exchange",
      "MAPK signaling", "Information exchange",
      "Circadian rhythm",
      "RNA regulation",
      "Proteostasis"
    ),
    stringsAsFactors = FALSE
  )

  result <- fruitArchitectureFromDEG(
    deg_table = deg,
    annotation = annotation,
    architecture_definition = "broad6",
    n_permutations = 0L
  )

  result_interface_ids <- .fa_interface_id(
    result$interface_summary$module_a,
    result$interface_summary$module_b
  )
  required <- result_interface_ids %in%
    result$definition$level3a_interface_ids

  expect_equal(sum(result$interface_summary$present), 3L)
  expect_true(all(result$interface_summary$present[required]))
  expect_true(any(!result$interface_summary$present[!required]))
  expect_true(result$level3a_present)
  expect_equal(result$level3b_count, 0L)
  expect_equal(result$metrics$level2_fraction, 3 / 15)
  expect_equal(result$metrics$required_level2_fraction, 1)
  expect_equal(result$metrics$weighted_isi, 0.52, tolerance = 1e-12)
  expect_identical(result$architecture_class, "III")
})


test_that("PHMIES Level 3A behavior is unchanged and paper5_frozen reconstructs 15 edges", {
  x <- make_synthetic_architecture_data()

  phmies <- fruitArchitectureFromDEG(
    x$deg,
    x$annotation,
    architecture_definition = "PHMIES",
    n_permutations = 0L
  )

  expect_true(phmies$level3a_present)
  expect_equal(nrow(phmies$interface_summary), 3L)
  expect_true(all(phmies$interface_summary$present))
  expect_identical(
    phmies$interface_summary$interface_id,
    phmies$definition$level3a_interface_ids
  )

  paper5_data <- data.frame(
    gene_id = c("g1", "g1", "g1"),
    module = c("Hormone", "MAPK", "Information Exchange"),
    stringsAsFactors = FALSE
  )
  paper5_deg <- data.frame(
    gene_id = "g1",
    log2_fold_change = 2,
    adjusted_p_value = 0.001,
    stringsAsFactors = FALSE
  )

  paper5 <- fruitArchitectureFromDEG(
    paper5_deg,
    paper5_data,
    architecture_definition = "paper5_frozen",
    n_permutations = 0L
  )

  expect_true(paper5$level3a_present)
  expect_equal(nrow(paper5$interface_summary), 15L)
  expect_equal(length(unique(paper5$interface_summary$interface_id)), 15L)

  required <- paper5$interface_summary$interface_id %in%
    paper5$definition$level3a_interface_ids

  expect_equal(sum(required), 3L)
  expect_true(all(paper5$interface_summary$present[required]))
  expect_false(any(paper5$interface_summary$present[!required]))
  expect_equal(paper5$metrics$level2_fraction, 3 / 15)
  expect_equal(paper5$metrics$required_level2_fraction, 1)
})


test_that("extended Broad6 interfaces do not independently promote PHMIES class", {
  definition <- .resolve_architecture_definition("paper5_frozen")

  reconstruction <- list(
    level3a_present = FALSE,
    level3b_count = 0L
  )

  metrics <- list(
    level1_fraction = 0.5,
    level2_fraction = 10 / 15,
    required_level2_fraction = 1 / 3
  )

  expect_false(definition$extended_interfaces_affect_class)
  expect_identical(
    .classify_architecture(reconstruction, metrics, definition),
    "II"
  )

  definition$extended_interfaces_affect_class <- TRUE
  expect_identical(
    .classify_architecture(reconstruction, metrics, definition),
    "III"
  )
})
