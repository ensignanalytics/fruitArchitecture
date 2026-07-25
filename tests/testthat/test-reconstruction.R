test_that("strict triple membership produces Level 3B", {
  x <- make_synthetic_architecture_data()
  result <- fruitArchitectureFromDEG(
    x$deg,
    x$annotation,
    species = "synthetic",
    n_permutations = 100,
    seed = 1
  )

  expect_s3_class(result, "fruit_architecture")
  expect_true(result$level3a_present)
  expect_equal(sort(result$level3b_genes), c("g1", "g4"))
  expect_equal(result$level3b_count, 2L)
  expect_equal(result$architecture_class, "IV")
})

test_that("duplicate DEG identifiers are rejected", {
  x <- make_synthetic_architecture_data()
  bad <- rbind(x$deg, x$deg[1, ])
  expect_error(
    fruitArchitectureFromDEG(bad, x$annotation, n_permutations = 0),
    "one row per gene"
  )
})

test_that("empirical P values cannot equal zero", {
  x <- make_synthetic_architecture_data()
  result <- fruitArchitectureFromDEG(
    x$deg,
    x$annotation,
    n_permutations = 25,
    seed = 2
  )
  expect_gt(result$null_model$p_value, 0)
})
