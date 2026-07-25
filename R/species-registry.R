#' List species planned or available in the annotation registry
#'
#' @return A data frame describing current registry status.
#' @export
supportedSpecies <- function() {
  data.frame(
    species_code = c(
      "apple", "banana", "cucumber", "grape", "melon", "papaya",
      "peach", "pear", "strawberry", "tomato", "watermelon"
    ),
    scientific_name = c(
      "Malus domestica", "Musa acuminata", "Cucumis sativus",
      "Vitis vinifera", "Cucumis melo", "Carica papaya",
      "Prunus persica", "Pyrus spp.", "Fragaria spp.",
      "Solanum lycopersicum", "Citrullus lanatus"
    ),
    built_in_annotation = FALSE,
    status = "Planned; supply `annotation` in version 0.1.0",
    stringsAsFactors = FALSE
  )
}
