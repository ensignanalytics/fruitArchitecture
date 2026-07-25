#' Export architecture tables and metadata
#'
#' @param x A `fruit_architecture` object.
#' @param directory Output directory.
#' @param prefix Optional file prefix.
#' @return Invisibly returns the normalized output directory.
#' @export
exportArchitecture <- function(x, directory, prefix = "fruit_architecture") {
  if (!inherits(x, "fruit_architecture")) {
    stop("`x` must be a fruit_architecture object.", call. = FALSE)
  }
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)

  utils::write.csv(
    x$differential_expression,
    file.path(directory, paste0(prefix, "_differential_expression.csv")),
    row.names = FALSE
  )
  utils::write.csv(
    x$gene_membership,
    file.path(directory, paste0(prefix, "_gene_membership.csv")),
    row.names = FALSE
  )
  utils::write.csv(
    x$module_summary,
    file.path(directory, paste0(prefix, "_module_summary.csv")),
    row.names = FALSE
  )
  utils::write.csv(
    x$interface_summary,
    file.path(directory, paste0(prefix, "_interface_summary.csv")),
    row.names = FALSE
  )

  summary_row <- data.frame(
    species = x$metadata$species,
    architecture = x$metadata$architecture,
    architecture_class = x$architecture_class,
    weighted_isi = x$metrics$weighted_isi,
    level3a_present = x$level3a_present,
    level3b_count = x$level3b_count,
    architecture_entropy = x$metrics$architecture_entropy,
    architecture_balance = x$metrics$architecture_balance,
    robustness_label = x$robustness$label,
    robustness_score = x$robustness$score,
    expected_level3b = x$null_model$expected,
    level3b_p_value = x$null_model$p_value,
    stringsAsFactors = FALSE
  )
  utils::write.csv(
    summary_row,
    file.path(directory, paste0(prefix, "_summary.csv")),
    row.names = FALSE
  )

  saveRDS(x, file.path(directory, paste0(prefix, "_object.rds")))
  invisible(normalizePath(directory, winslash = "/", mustWork = TRUE))
}

#' Export standard package figures
#'
#' @param x A `fruit_architecture` object.
#' @param directory Output directory.
#' @param formats Any combination of `"pdf"`, `"png"`, and `"tiff"`.
#' @param width Figure width in inches.
#' @param height Figure height in inches.
#' @param dpi Raster resolution.
#' @return Invisibly returns generated paths.
#' @export
exportFigures <- function(
    x,
    directory,
    formats = c("pdf", "png", "tiff"),
    width = 9,
    height = 6,
    dpi = 600) {

  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  types <- c("modules", "interfaces", "null")
  paths <- character()

  for (plot_type in types) {
    if (plot_type == "null" && length(x$null_model$distribution) == 0L) next
    p <- plot(x, type = plot_type)
    for (format in formats) {
      path <- file.path(directory, paste0("fruit_architecture_", plot_type, ".", format))
      ggplot2::ggsave(
        filename = path,
        plot = p,
        width = width,
        height = height,
        units = "in",
        dpi = if (format %in% c("png", "tiff")) dpi else 300
      )
      paths <- c(paths, path)
    }
  }

  invisible(paths)
}
