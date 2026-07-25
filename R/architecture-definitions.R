#' Default PHMIES architecture definition
#'
#' @return A named list containing module names, aliases, pairwise interfaces,
#'   Level 3A requirements, and metric weights.
#' @keywords internal
.default_architecture_definition <- function() {
  modules <- c(
    "Circadian rhythm",
    "Plant hormone signal transduction",
    "MAPK signaling",
    "Information exchange",
    "Protein processing in endoplasmic reticulum",
    "RNA transport",
    "RNA degradation",
    "SNARE interactions",
    "Autophagy",
    "Sulfur relay system"
  )

  aliases <- list(
    "Circadian rhythm" = c("circadian rhythm", "cr"),
    "Plant hormone signal transduction" = c(
      "plant hormone signal transduction", "plant hormone signaling",
      "hormone signaling", "phst"
    ),
    "MAPK signaling" = c(
      "mapk signaling", "mapk signalling", "mapk signaling pathway", "mapk"
    ),
    "Information exchange" = c(
      "information exchange", "plant-pathogen interaction",
      "plant pathogen interaction", "defense", "ppi"
    ),
    "Protein processing in endoplasmic reticulum" = c(
      "protein processing in endoplasmic reticulum",
      "protein processing in the endoplasmic reticulum",
      "protein processing in er", "pper"
    ),
    "RNA transport" = c("rna transport", "rna_t"),
    "RNA degradation" = c("rna degradation", "rna_d"),
    "SNARE interactions" = c(
      "snare interactions", "snare interactions in vesicular transport", "snare"
    ),
    "Autophagy" = c("autophagy", "autophagy - other", "autophagy other"),
    "Sulfur relay system" = c("sulfur relay system", "srs")
  )

  core <- c(
    "Plant hormone signal transduction",
    "MAPK signaling",
    "Information exchange"
  )

  interfaces <- data.frame(
    interface = c(
      "Hormone-MAPK",
      "Hormone-Information exchange",
      "MAPK-Information exchange"
    ),
    module_a = core[c(1, 1, 2)],
    module_b = core[c(2, 3, 3)],
    stringsAsFactors = FALSE
  )

  list(
    name = "PHMIES",
    version = "0.1.2",
    modules = modules,
    aliases = aliases,
    core_modules = core,
    interfaces = interfaces,
    weights = list(level1 = 0.25, level2 = 0.35, level3a = 0.20, level3b = 0.20)
  )
}

.resolve_architecture_definition <- function(x) {
  if (is.null(x) || identical(x, "PHMIES")) {
    return(.default_architecture_definition())
  }
  if (!is.list(x)) {
    stop("`architecture_definition` must be 'PHMIES' or a definition list.", call. = FALSE)
  }
  required <- c("name", "modules", "core_modules", "interfaces", "weights")
  missing <- setdiff(required, names(x))
  if (length(missing) > 0L) {
    stop(
      "Custom architecture definition is missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  x
}
