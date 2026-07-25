#' Plot a fruit architecture result
#'
#' Creates standard visualizations for module support, pairwise interface
#' support, and the Level 3B permutation null distribution.
#'
#' @param x A `fruit_architecture` object.
#' @param type Character string specifying the plot type. Available values are
#'   `"modules"`, `"interfaces"`, and `"null"`.
#' @param ... Additional arguments reserved for future methods.
#'
#' @return A `ggplot2` object.
#'
#' @importFrom rlang .data
#' @method plot fruit_architecture
#' @export
plot.fruit_architecture <- function(
    x,
    type = c("modules", "interfaces", "null"),
    ...) {
  
  if (!inherits(x, "fruit_architecture")) {
    stop(
      "`x` must be a fruit_architecture object.",
      call. = FALSE
    )
  }
  
  type <- match.arg(type)
  
  if (type == "modules") {
    
    dat <- x$module_summary
    
    required_columns <- c(
      "module",
      "deg_genes"
    )
    
    missing_columns <- setdiff(
      required_columns,
      names(dat)
    )
    
    if (length(missing_columns) > 0L) {
      stop(
        "The module summary is missing required columns: ",
        paste(missing_columns, collapse = ", "),
        call. = FALSE
      )
    }
    
    return(
      ggplot2::ggplot(
        dat,
        ggplot2::aes(
          x = stats::reorder(
            .data$module,
            .data$deg_genes
          ),
          y = .data$deg_genes
        )
      ) +
        ggplot2::geom_col() +
        ggplot2::coord_flip() +
        ggplot2::labs(
          x = NULL,
          y = "Significant genes",
          title = paste0(
            x$metadata$species,
            ": architecture module support"
          )
        ) +
        ggplot2::theme_minimal(
          base_size = 11
        )
    )
  }
  
  if (type == "interfaces") {
    
    dat <- x$interface_summary
    
    required_columns <- c(
      "interface",
      "overlap_genes"
    )
    
    missing_columns <- setdiff(
      required_columns,
      names(dat)
    )
    
    if (length(missing_columns) > 0L) {
      stop(
        "The interface summary is missing required columns: ",
        paste(missing_columns, collapse = ", "),
        call. = FALSE
      )
    }
    
    return(
      ggplot2::ggplot(
        dat,
        ggplot2::aes(
          x = stats::reorder(
            .data$interface,
            .data$overlap_genes
          ),
          y = .data$overlap_genes
        )
      ) +
        ggplot2::geom_col() +
        ggplot2::coord_flip() +
        ggplot2::labs(
          x = NULL,
          y = "Strict overlap genes",
          title = paste0(
            x$metadata$species,
            ": pairwise interface support"
          )
        ) +
        ggplot2::theme_minimal(
          base_size = 11
        )
    )
  }
  
  if (
    is.null(x$null_model$distribution) ||
    length(x$null_model$distribution) == 0L
  ) {
    stop(
      "The null model was not run for this object.",
      call. = FALSE
    )
  }
  
  dat <- data.frame(
    level3b = x$null_model$distribution
  )
  
  ggplot2::ggplot(
    dat,
    ggplot2::aes(
      x = .data$level3b
    )
  ) +
    ggplot2::geom_histogram(
      binwidth = 1,
      boundary = -0.5
    ) +
    ggplot2::geom_vline(
      xintercept = x$level3b_count,
      linetype = 2,
      linewidth = 0.8
    ) +
    ggplot2::scale_x_continuous(
      breaks = function(z) {
        seq(
          floor(min(z, na.rm = TRUE)),
          ceiling(max(z, na.rm = TRUE)),
          by = 1
        )
      }
    ) +
    ggplot2::labs(
      x = "Level 3B genes under null model",
      y = "Permutation count",
      title = "Level 3B null distribution",
      subtitle = paste(
        "Observed =",
        x$level3b_count
      )
    ) +
    ggplot2::theme_minimal(
      base_size = 11
    )
}