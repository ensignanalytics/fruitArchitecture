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
