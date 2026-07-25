test_that("bundled example data loader returns all required objects", {
  example_data <- fruitArchitectureExampleData()

  expect_named(
    example_data,
    c("deg_table", "annotation", "counts", "design", "directory")
  )
  expect_true(is.data.frame(example_data$deg_table))
  expect_true(is.data.frame(example_data$annotation))
  expect_true(is.matrix(example_data$counts))
  expect_true(is.data.frame(example_data$design))
  expect_true(dir.exists(example_data$directory))
})

test_that("one-command example runs without export", {
  result <- fruitArchitectureExample(
    n_permutations = 25,
    seed = 1234,
    export = FALSE
  )

  expect_s3_class(result, "fruit_architecture")
  expect_identical(result$architecture_class, "IV")
})

test_that("installed example reconstructs a complete architecture", {
  example_directory <- system.file("extdata", package = "fruitArchitecture")

  deg_table <- utils::read.csv(
    file.path(example_directory, "fruitArchitecture_example_deg.csv"),
    check.names = FALSE
  )
  annotation <- utils::read.csv(
    file.path(example_directory, "fruitArchitecture_example_annotation.csv"),
    check.names = FALSE
  )

  result <- fruitArchitectureFromDEG(
    deg_table = deg_table,
    annotation = annotation,
    species = "synthetic fruit example",
    n_permutations = 100,
    seed = 1234
  )

  expect_s3_class(result, "fruit_architecture")
  expect_identical(result$architecture_class, "IV")
  expect_true(result$level3a_present)
  expect_equal(result$level3b_count, 4L)
  expect_true(all(result$module_summary$present))
  expect_true(all(result$interface_summary$present))
  module_plot <- plot(
    result,
    type = "modules"
  )
  
  interface_plot <- plot(
    result,
    type = "interfaces"
  )
  
  null_plot <- plot(
    result,
    type = "null"
  )
  
  expect_s3_class(
    module_plot,
    "ggplot"
  )
  
  expect_s3_class(
    interface_plot,
    "ggplot"
  )
  
  expect_s3_class(
    null_plot,
    "ggplot"
  )
  
  expect_no_error(
    ggplot2::ggplot_build(
      module_plot
    )
  )
  
  expect_no_error(
    ggplot2::ggplot_build(
      interface_plot
    )
  )
  
  expect_no_error(
    ggplot2::ggplot_build(
      null_plot
    )
  )
})
