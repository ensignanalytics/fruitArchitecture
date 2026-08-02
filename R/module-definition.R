# Internal module-definition registry.
#
# Module definitions describe how genes and annotation terms are assigned to
# functional modules. They do not define architecture classes or directed
# regulatory circuits.

.fa_module_definitions <- list(
  
  core10 = list(
    id = "core10",
    version = "v0.1-frozen",
    description = paste(
      "Original fruitArchitecture pathway and module assignments used by",
      "the frozen v0.1 PHMIES implementation."
    ),
    modules = c(
      "Autophagy",
      "Circadian rhythm",
      "MAPK signaling",
      "Plant hormone signal transduction",
      "Plant-pathogen interaction",
      "Protein processing in endoplasmic reticulum",
      "RNA degradation",
      "RNA transport",
      "SNARE interactions",
      "Sulfur relay system"
    )
  ),
  
  broad6 = list(
    id = "broad6",
    version = "paper5-frozen-v1",
    description = paste(
      "Six broad functional modules used for expanded architecture",
      "reconstruction under the Paper 5 frozen rules."
    ),
    modules = c(
      "Circadian",
      "Hormone",
      "MAPK",
      "Information Exchange",
      "RNA regulation",
      "Proteostasis"
    )
  )
)
