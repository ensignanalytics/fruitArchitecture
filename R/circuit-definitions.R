.fa_circuit_definitions <- list(
  
  none = list(
    id = "none",
    version = "1",
    description = "No directed regulatory circuit reconstruction."
  ),
  
  autocatalytic_ethylene_v1 = list(
    id = "autocatalytic_ethylene_v1",
    version = "paper5-frozen-v1",
    description = paste(
      "Directed autocatalytic ethylene biosynthesis circuits linking",
      "ethylene signaling, ripening regulators, ACS or ACO targets,",
      "and renewed ethylene production."
    ),
    
    upstream_regulator_classes = c(
      "EIN3",
      "EIL"
    ),
    
    intermediate_regulator_classes = c(
      "RIN",
      "NAC",
      "TAGL1",
      "MADS"
    ),
    
    biosynthesis_target_classes = c(
      "ACS",
      "ACO"
    ),
    
    terminal_process = "Ethylene biosynthesis",
    
    engagement_requirements = c(
      "upstream_regulator_supported",
      "intermediate_regulator_supported",
      "biosynthesis_target_supported",
      "regulator_edge_supported",
      "target_edge_supported",
      "same_species",
      "same_developmental_context"
    )
  )
)
