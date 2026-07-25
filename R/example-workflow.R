.fruit_architecture_package_version <- function() {
  tryCatch(
    as.character(utils::packageVersion("fruitArchitecture")),
    error = function(e) "development"
  )
}

#' Load the bundled fruitArchitecture example data
#'
#' Loads the synthetic differential-expression, annotation, count, and design
#' tables included with the installed package. These data are intended for
#' testing installation and demonstrating the package workflow; they are not
#' biological observations.
#'
#' @return A named list containing `deg_table`, `annotation`, `counts`, and
#'   `design`.
#' @export
fruitArchitectureExampleData <- function() {
  example_directory <- system.file("extdata", package = "fruitArchitecture")

  if (!nzchar(example_directory) || !dir.exists(example_directory)) {
    stop(
      "Bundled example data were not found. Reinstall fruitArchitecture ",
      "from a source package that contains inst/extdata.",
      call. = FALSE
    )
  }

  required_files <- c(
    deg = "fruitArchitecture_example_deg.csv",
    annotation = "fruitArchitecture_example_annotation.csv",
    counts = "fruitArchitecture_example_counts.csv",
    design = "fruitArchitecture_example_design.csv"
  )

  paths <- stats::setNames(
    file.path(example_directory, unname(required_files)),
    names(required_files)
  )
  missing <- names(paths)[!file.exists(paths)]
  if (length(missing) > 0L) {
    stop(
      "The installed package is missing example file(s): ",
      paste(missing, collapse = ", "),
      ". Reinstall the current package release.",
      call. = FALSE
    )
  }

  deg_table <- utils::read.csv(paths[["deg"]], check.names = FALSE)
  annotation <- utils::read.csv(paths[["annotation"]], check.names = FALSE)
  counts <- utils::read.csv(
    paths[["counts"]],
    row.names = 1,
    check.names = FALSE
  )
  counts <- as.matrix(counts)
  storage.mode(counts) <- "integer"

  design <- utils::read.csv(
    paths[["design"]],
    row.names = 1,
    check.names = FALSE
  )
  if ("condition" %in% names(design)) {
    design$condition <- factor(
      design$condition,
      levels = unique(design$condition)
    )
  }

  list(
    deg_table = deg_table,
    annotation = annotation,
    counts = counts,
    design = design,
    directory = example_directory
  )
}

#' Run the bundled fruitArchitecture example
#'
#' Runs architecture reconstruction using the synthetic DEG and annotation
#' tables installed with the package. Optionally exports result tables and
#' publication-ready PDF, PNG, and TIFF figures.
#'
#' @param output_directory Directory for exported example results.
#' @param n_permutations Number of permutations used by the Level 3B null model.
#' @param seed Random seed.
#' @param export Logical; export tables, an RDS object, and figures.
#' @param formats Figure formats passed to [exportFigures()].
#' @param dpi Resolution for raster figures.
#'
#' @return Invisibly returns a `fruit_architecture` object.
#' @export
fruitArchitectureExample <- function(
    output_directory = file.path(
      getwd(),
      "fruitArchitecture_example_output"
    ),
    n_permutations = 100,
    seed = 1234,
    export = FALSE,
    formats = c("pdf", "png", "tiff"),
    dpi = 600) {
  
  example_data <- fruitArchitectureExampleData()
  
  result <- fruitArchitectureFromDEG(
    deg_table = example_data$deg_table,
    annotation = example_data$annotation,
    species = "synthetic fruit example",
    alpha = 0.05,
    log2fc_threshold = 1,
    n_permutations = n_permutations,
    seed = seed
  )
  
  if (isTRUE(export)) {
    
    dir.create(
      output_directory,
      recursive = TRUE,
      showWarnings = FALSE
    )
    
    exportArchitecture(
      result,
      directory = output_directory,
      prefix = "synthetic_example"
    )
    
    exportFigures(
      result,
      directory = file.path(
        output_directory,
        "figures"
      ),
      formats = formats,
      dpi = dpi
    )
  }
  
  invisible(result)
}
