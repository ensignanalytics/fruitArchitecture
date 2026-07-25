# Getting started with fruitArchitecture

## Overview

`fruitArchitecture` separates differential-expression analysis from
architecture reconstruction. Users can begin with either a validated DEG
table or a raw RNA-seq count matrix.

## Installation into the user library

``` r

user_library <- .libPaths()[1]
dir.create(user_library, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes", lib = user_library)
}

remotes::install_local(
  "C:/path/to/fruitArchitecture",
  lib = user_library,
  dependencies = c("Depends", "Imports", "LinkingTo"),
  upgrade = "never",
  force = TRUE
)
```

Install DESeq2 only when raw counts will be analyzed:

``` r

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
BiocManager::install("DESeq2", ask = FALSE, update = FALSE)
```

## Included example files

``` r

example_directory <- system.file("extdata", package = "fruitArchitecture")
list.files(example_directory)
#> [1] "fruitArchitecture_example_annotation.csv"
#> [2] "fruitArchitecture_example_counts.csv"    
#> [3] "fruitArchitecture_example_deg.csv"       
#> [4] "fruitArchitecture_example_design.csv"
```

## Recommended DEG-table workflow

``` r

deg_table <- utils::read.csv(
  file.path(example_directory, "fruitArchitecture_example_deg.csv"),
  check.names = FALSE
)

annotation <- utils::read.csv(
  file.path(example_directory, "fruitArchitecture_example_annotation.csv"),
  check.names = FALSE
)

result <- fruitArchitectureFromDEG(
  deg_table = deg_table,
  annotation = annotation,
  species = "synthetic fruit example",
  n_permutations = 1000,
  seed = 1234
)

result
#> Fruit Architecture Analysis
#> ----------------------------------------------
#> Species: synthetic fruit example
#> Architecture: PHMIES
#> 
#> Architecture Class: IV
#> Weighted ISI: 1.000
#> Level 3A: Present
#> Level 3B: Present
#> Architecture robustness: High
#> Architecture entropy: 1.000
#> Architecture balance: 1.000
#> 
#> Expected Level 3B: 1.334
#> Observed Level 3B: 4
#> Empirical P-value: 0.016
```

``` r

result$module_summary
#>                                         module annotated_genes deg_genes
#> 1                             Circadian rhythm               5         1
#> 2            Plant hormone signal transduction              13         9
#> 3                               MAPK signaling              13         9
#> 4                         Information exchange              13         9
#> 5  Protein processing in endoplasmic reticulum               5         1
#> 6                                RNA transport               5         1
#> 7                              RNA degradation               5         1
#> 8                           SNARE interactions               5         1
#> 9                                    Autophagy               5         1
#> 10                         Sulfur relay system               5         1
#>    up_genes down_genes present
#> 1         0          1    TRUE
#> 2         8          1    TRUE
#> 3         8          1    TRUE
#> 4         8          1    TRUE
#> 5         0          1    TRUE
#> 6         0          1    TRUE
#> 7         0          1    TRUE
#> 8         0          1    TRUE
#> 9         0          1    TRUE
#> 10        0          1    TRUE
result$interface_summary
#>                      interface                          module_a
#> 1                 Hormone-MAPK Plant hormone signal transduction
#> 2 Hormone-Information exchange Plant hormone signal transduction
#> 3    MAPK-Information exchange                    MAPK signaling
#>               module_b overlap_genes present
#> 1       MAPK signaling             6    TRUE
#> 2 Information exchange             6    TRUE
#> 3 Information exchange             6    TRUE
#>                                             genes
#> 1 FA_G001;FA_G002;FA_G003;FA_G004;FA_G005;FA_G006
#> 2 FA_G001;FA_G002;FA_G003;FA_G004;FA_G007;FA_G008
#> 3 FA_G001;FA_G002;FA_G003;FA_G004;FA_G009;FA_G010
result$level3b_genes
#> [1] "FA_G001" "FA_G002" "FA_G003" "FA_G004"
```

## Figures

``` r

print(
  plot(
    result,
    type = "modules"
  )
)
```

![Horizontal bar chart summarizing significant gene support across the
default fruit architecture
modules.](getting-started_files/figure-html/module-figure-1.png)

``` r

print(
  plot(
    result,
    type = "interfaces"
  )
)
```

![Horizontal bar chart summarizing strict gene overlap for each pairwise
PHMIES
interface.](getting-started_files/figure-html/interface-figure-1.png)

``` r

print(
  plot(
    result,
    type = "null"
  )
)
```

![Permutation null distribution for the number of Level 3B genes, with
the observed value shown as a dashed vertical
line.](getting-started_files/figure-html/null-figure-1.png)

## Export a complete example analysis

``` r

output_directory <- file.path(getwd(), "fruitArchitecture_example_output")

exportArchitecture(
  result,
  directory = output_directory,
  prefix = "synthetic_example"
)

exportFigures(
  result,
  directory = file.path(output_directory, "figures"),
  formats = c("pdf", "png", "tiff"),
  width = 9,
  height = 6,
  dpi = 600
)
```

## Raw-count workflow

``` r

counts_data <- utils::read.csv(
  file.path(example_directory, "fruitArchitecture_example_counts.csv"),
  row.names = 1,
  check.names = FALSE
)
counts <- as.matrix(counts_data)
storage.mode(counts) <- "integer"

design <- utils::read.csv(
  file.path(example_directory, "fruitArchitecture_example_design.csv"),
  row.names = 1,
  check.names = FALSE
)
design$condition <- factor(design$condition, levels = c("immature", "ripe"))

count_result <- fruitArchitecture(
  counts = counts,
  design = design,
  species = "synthetic fruit example",
  formula = ~ condition,
  contrast = c("condition", "ripe", "immature"),
  annotation = annotation,
  n_permutations = 1000,
  seed = 1234
)

count_result
```

## Input requirements

The DEG table must contain unique gene identifiers, log2 fold changes,
and adjusted P-values. Annotation must be long format, with one row for
each gene-module assignment. A strict Level 3B member is a significant
gene assigned to all three PHMIES core modules in the selected
architecture definition.
