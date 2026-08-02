# ============================================================
# Interface registry helpers
#
# Interface registries are constructed lazily inside functions.
# Do not create objects at package-load time that depend on
# objects defined in another R source file.
# ============================================================


#' Create a canonical interface identifier
#'
#' Interface identifiers are orientation independent. For example,
#' Hormone--MAPK and MAPK--Hormone resolve to the same identifier.
#'
#' @param module_a First module name.
#' @param module_b Second module name.
#'
#' @return A character vector of canonical interface identifiers.
#' @keywords internal
.fa_interface_id <- function(module_a, module_b) {
  
  if (length(module_a) != length(module_b)) {
    stop(
      "`module_a` and `module_b` must have equal lengths.",
      call. = FALSE
    )
  }
  
  vapply(
    seq_along(module_a),
    function(i) {
      paste(
        sort(c(module_a[[i]], module_b[[i]])),
        collapse = "--"
      )
    },
    character(1)
  )
}


#' Construct a complete pairwise interface registry
#'
#' @param modules Character vector of unique module names.
#'
#' @return A data frame containing all pairwise module interfaces.
#' @keywords internal
.fa_make_interface_registry <- function(modules) {
  
  if (!is.character(modules)) {
    stop("`modules` must be a character vector.", call. = FALSE)
  }
  
  if (length(modules) < 2L) {
    stop("At least two modules are required.", call. = FALSE)
  }
  
  if (anyNA(modules) || any(!nzchar(modules))) {
    stop(
      "`modules` cannot contain missing or empty values.",
      call. = FALSE
    )
  }
  
  if (anyDuplicated(modules)) {
    stop("`modules` must contain unique values.", call. = FALSE)
  }
  
  pairs <- utils::combn(
    modules,
    2L,
    simplify = FALSE
  )
  
  registry <- data.frame(
    module_a = vapply(
      pairs,
      `[[`,
      character(1),
      1L
    ),
    module_b = vapply(
      pairs,
      `[[`,
      character(1),
      2L
    ),
    stringsAsFactors = FALSE
  )
  
  registry$interface_id <- .fa_interface_id(
    registry$module_a,
    registry$module_b
  )
  
  registry$interface <- paste(
    registry$module_a,
    registry$module_b,
    sep = "-"
  )
  
  registry
}


#' Return the frozen Broad6 interface registry
#'
#' The registry is generated when the function is called rather than
#' during package loading. This avoids dependencies on R file load order.
#'
#' @return A data frame containing the 15 Broad6 interfaces.
#' @keywords internal
.fa_broad6_interfaces <- function() {
  
  definition <- .resolve_architecture_definition(
    "paper5_frozen"
  )
  
  .fa_make_interface_registry(
    definition$modules
  )
}