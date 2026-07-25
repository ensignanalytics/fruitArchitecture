`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

.assert_data_frame <- function(x, name) {
  if (!is.data.frame(x)) {
    stop("`", name, "` must be a data.frame.", call. = FALSE)
  }
  invisible(TRUE)
}

.assert_columns <- function(x, columns, name) {
  missing <- setdiff(columns, names(x))
  if (length(missing) > 0L) {
    stop(
      "`", name, "` is missing required column(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

.clean_text <- function(x) {
  x <- trimws(tolower(as.character(x)))
  x <- gsub("[[:space:]]+", " ", x)
  x
}

.empirical_p_value <- function(null_values, observed) {
  (sum(null_values >= observed, na.rm = TRUE) + 1) /
    (sum(!is.na(null_values)) + 1)
}

.safe_divide <- function(numerator, denominator, default = 0) {
  ifelse(is.na(denominator) | denominator == 0, default, numerator / denominator)
}
