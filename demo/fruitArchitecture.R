library(fruitArchitecture)

result <- fruitArchitectureExample(
  n_permutations = 100,
  seed = 1234,
  export = FALSE
)

print(result)

module_plot <- plot(
  result,
  type = "modules"
)

interface_plot <- plot(
  result,
  type = "interfaces"
)

null_plot <- plot(
  result,
  type = "null"
)

print(module_plot)
print(interface_plot)
print(null_plot)