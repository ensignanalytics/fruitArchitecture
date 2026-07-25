test_that("metrics remain within the unit interval", {
  x <- make_synthetic_architecture_data()
  result <- fruitArchitectureFromDEG(
    x$deg,
    x$annotation,
    n_permutations = 10
  )

  expect_gte(result$metrics$weighted_isi, 0)
  expect_lte(result$metrics$weighted_isi, 1)
  expect_gte(result$metrics$architecture_entropy, 0)
  expect_lte(result$metrics$architecture_entropy, 1)
  expect_gte(result$metrics$architecture_balance, 0)
  expect_lte(result$metrics$architecture_balance, 1)
})
