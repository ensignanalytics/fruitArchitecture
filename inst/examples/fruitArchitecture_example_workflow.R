# fruitArchitecture installed-package example workflow

library(fruitArchitecture)

# Load and inspect the bundled synthetic data.
example_data <- fruitArchitectureExampleData()
head(example_data$deg_table)
head(example_data$annotation)
dim(example_data$counts)
example_data$design

# Run the DEG-to-architecture workflow and export tables and figures.
result <- fruitArchitectureExample(
  output_directory = file.path(getwd(), "fruitArchitecture_example_output"),
  n_permutations = 5000,
  seed = 1234,
  export = TRUE,
  formats = c("pdf", "png", "tiff"),
  dpi = 600
)

# Inspect individual analytical objects.
module_plot <- plot(
  result,
  type = "modules"
)
print(module_plot)

interface_plot <- plot(
  result,
  type = "interfaces"
)
print(interface_plot)

null_plot <- plot(
  result,
  type = "null"
)
print(null_plot)

summary(result)
result$module_summary
result$interface_summary
result$level3b_genes
result$metrics
