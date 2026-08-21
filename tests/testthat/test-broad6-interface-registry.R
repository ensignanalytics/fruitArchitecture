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
})


test_that("PHMIES and paper5_frozen Level 3A behavior is unchanged", {
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
  expect_equal(nrow(paper5$interface_summary), 3L)
  expect_true(all(paper5$interface_summary$present))
})
