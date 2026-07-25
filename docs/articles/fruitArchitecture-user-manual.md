# fruitArchitecture User Manual

## Purpose and scope

`fruitArchitecture` reconstructs annotation-derived signaling
organization from transcriptomic evidence. It summarizes significant
genes within predefined modules, measures strict gene overlap between
core modules, identifies Level 3A and Level 3B organization, calculates
architecture metrics, performs a permutation-based Level 3B test,
assigns an architecture class, and produces standard figures and export
tables.

The package accepts either:

1.  a completed differential-expression table; or
2.  an RNA-seq count matrix and sample design analyzed internally with
    `DESeq2`.

The current default architecture is **PHMIES**, which contains the core
modules Plant hormone signal transduction, MAPK signaling, and
Information exchange. The default definition also tracks seven
additional recurrent modules: Circadian rhythm, Protein processing in
endoplasmic reticulum, RNA transport, RNA degradation, SNARE
interactions, Autophagy, and Sulfur relay system.

> **Development status.** Version 0.1.x is an early research-software
> release. The weighted ISI, entropy, balance, robustness score, and
> class thresholds are implemented reproducibly, but their scientific
> definitions remain versioned and should be treated as provisional
> until the package methods paper and validation analyses are finalized.

## Installation

### Install from an extracted source directory

Extract the source package so that `DESCRIPTION`, `NAMESPACE`, and the
`R/` directory are located directly inside the package directory. Then
install it into the first local library returned by
[`.libPaths()`](https://rdrr.io/r/base/libPaths.html).

``` r

user_library <- .libPaths()[1]

dir.create(
  user_library,
  recursive = TRUE,
  showWarnings = FALSE
)

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

remotes::install_local(
  path = "C:/fruitArchitecture",
  lib = user_library,
  dependencies = c("Depends", "Imports", "LinkingTo"),
  upgrade = "never",
  force = TRUE
)
```

Restart R after installation, then verify the installed version and
location.

``` r

library(fruitArchitecture)
packageVersion("fruitArchitecture")
find.package("fruitArchitecture")
```

### Optional dependency for raw-count analysis

The DEG-table workflow does not require `DESeq2`. Install `DESeq2` only
when using
[`fruitArchitecture()`](https://ensignanalytics.github.io/fruitArchitecture/reference/fruitArchitecture.md)
with a count matrix.

``` r

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

BiocManager::install(
  "DESeq2",
  ask = FALSE,
  update = FALSE
)
```

## Quick start

The fastest installation test is the bundled synthetic analysis.

``` r

result <- fruitArchitectureExample(
  n_permutations = 100,
  seed = 1234,
  export = FALSE
)
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
#> Expected Level 3B: 1.260
#> Observed Level 3B: 4
#> Empirical P-value: 0.0198
```

The returned object has class `fruit_architecture`.

``` r

class(result)
#> [1] "fruit_architecture"
```

Printing the object reports the principal architecture results.

``` r

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
#> Expected Level 3B: 1.260
#> Observed Level 3B: 4
#> Empirical P-value: 0.0198
```

## Bundled example data

The package includes four synthetic CSV files under `inst/extdata`. The
files are installed with the package and can be loaded together with
[`fruitArchitectureExampleData()`](https://ensignanalytics.github.io/fruitArchitecture/reference/fruitArchitectureExampleData.md).

``` r

example_data <- fruitArchitectureExampleData()
names(example_data)
#> [1] "deg_table"  "annotation" "counts"     "design"     "directory"
```

The example is deliberately constructed to demonstrate a complete Class
IV result. It is **not** a biological dataset and should not be used as
evidence for any species or biological process.

### Differential-expression table

``` r

dim(example_data$deg_table)
#> [1] 60  7
head(example_data$deg_table)
#>   gene_id base_mean log2_fold_change standard_error statistic  p_value
#> 1 FA_G001     103.7             3.35           0.22   15.2273 5.25e-07
#> 2 FA_G002     107.4             3.50           0.22   15.9091 5.50e-07
#> 3 FA_G003     111.1             3.20           0.22   14.5455 5.75e-07
#> 4 FA_G004     114.8             3.35           0.22   15.2273 6.00e-07
#> 5 FA_G005     118.5             3.50           0.22   15.9091 6.25e-07
#> 6 FA_G006     122.2             3.20           0.22   14.5455 6.50e-07
#>   adjusted_p_value
#> 1         1.05e-06
#> 2         1.10e-06
#> 3         1.15e-06
#> 4         1.20e-06
#> 5         1.25e-06
#> 6         1.30e-06
```

The table contains 60 synthetic genes and the following required
columns:

- `gene_id`: unique gene identifier;
- `log2_fold_change`: signed effect size;
- `adjusted_p_value`: multiple-testing-adjusted P-value.

It also includes optional fields used for inspection and export:
`base_mean`, `standard_error`, `statistic`, and `p_value`.

### Annotation table

``` r

dim(example_data$annotation)
#> [1] 74  2
head(example_data$annotation)
#>   gene_id                            module
#> 1 FA_G001 Plant hormone signal transduction
#> 2 FA_G001                    MAPK signaling
#> 3 FA_G001              Information exchange
#> 4 FA_G002 Plant hormone signal transduction
#> 5 FA_G002                    MAPK signaling
#> 6 FA_G002              Information exchange
```

The annotation table is in long format. A gene may occur in several rows
when it belongs to several modules. The minimum required columns are:

- `gene_id`; and
- either `module` or `pathway_name`.

The bundled annotation contains assignments to all ten default modules.
Four significant synthetic genes are assigned to all three PHMIES core
modules and therefore qualify as strict Level 3B genes.

### Count matrix

``` r

dim(example_data$counts)
#> [1] 60  6
example_data$counts[1:5, , drop = FALSE]
#>         Immature_1 Immature_2 Immature_3 Ripe_1 Ripe_2 Ripe_3
#> FA_G001         58         62         55    522    539    508
#> FA_G002         61         65         58    549    566    535
#> FA_G003         64         68         61    576    593    562
#> FA_G004         67         71         64    603    620    589
#> FA_G005         70         74         67    630    647    616
```

The count matrix contains 60 genes and six samples: three immature and
three ripe synthetic replicates. Genes are rows and samples are columns.

### Sample design

``` r

example_data$design
#>            condition
#> Immature_1  immature
#> Immature_2  immature
#> Immature_3  immature
#> Ripe_1          ripe
#> Ripe_2          ripe
#> Ripe_3          ripe
```

The design has one row per sample. Its row names must match the
count-matrix column names exactly.

## Recommended workflow: start from a DEG table

For method development and cross-platform applications, beginning with a
validated DEG table is the most direct workflow.

``` r

deg_result <- fruitArchitectureFromDEG(
  deg_table = example_data$deg_table,
  annotation = example_data$annotation,
  species = "synthetic fruit example",
  gene_id_col = "gene_id",
  log2fc_col = "log2_fold_change",
  padj_col = "adjusted_p_value",
  alpha = 0.05,
  log2fc_threshold = 1,
  architecture_definition = "PHMIES",
  min_module_genes = 1,
  min_interface_genes = 1,
  n_permutations = 100,
  seed = 1234
)

deg_result
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
#> Expected Level 3B: 1.260
#> Observed Level 3B: 4
#> Empirical P-value: 0.0198
```

### DEG decision rule

A gene is marked significant when both conditions are met:

``` text
adjusted_p_value <= alpha
abs(log2_fold_change) >= log2fc_threshold
```

The package records significant genes as `Up` or `Down`. All other genes
are recorded as `Not significant`.

### Annotation matching

Module names may be supplied directly, or recognized aliases may be
used. For example, the default definition maps `PHST` to Plant hormone
signal transduction, `MAPK` to MAPK signaling, and `PPI` or `Defense` to
Information exchange. Annotation text that does not match a defined
module or alias is not used in reconstruction.

Inspect the mapped annotation and coverage before interpreting the
architecture.

``` r

deg_result$input_audit
#> $input_genes
#> [1] 60
#> 
#> $significant_genes
#> [1] 20
#> 
#> $mapped_genes
#> [1] 60
#> 
#> $annotation_coverage
#> [1] 1
tail(deg_result$mapped_annotation)
#>    gene_id                           source_annotation
#> 69 FA_G055 Protein processing in endoplasmic reticulum
#> 70 FA_G056                               RNA transport
#> 71 FA_G057                             RNA degradation
#> 72 FA_G058                          SNARE interactions
#> 73 FA_G059                                   Autophagy
#> 74 FA_G060                         Sulfur relay system
#>                                         module
#> 69 Protein processing in endoplasmic reticulum
#> 70                               RNA transport
#> 71                             RNA degradation
#> 72                          SNARE interactions
#> 73                                   Autophagy
#> 74                         Sulfur relay system
```

Low annotation coverage can indicate incompatible gene identifiers,
genome release mismatch, incomplete functional annotation, or a
genuinely limited set of architecture-relevant genes.

## Raw-count workflow with DESeq2

The raw-count interface runs `DESeq2`, constructs a standardized DEG
table, and passes the result to the same architecture engine used by
[`fruitArchitectureFromDEG()`](https://ensignanalytics.github.io/fruitArchitecture/reference/fruitArchitectureFromDEG.md).

``` r

count_result <- fruitArchitecture(
  counts = example_data$counts,
  design = example_data$design,
  species = "synthetic fruit example",
  formula = ~ condition,
  contrast = c("condition", "ripe", "immature"),
  annotation = example_data$annotation,
  alpha = 0.05,
  log2fc_threshold = 1,
  architecture_definition = "PHMIES",
  min_module_genes = 1,
  min_interface_genes = 1,
  n_permutations = 5000,
  seed = 1234
)

count_result
```

### Raw-count requirements

- Counts must be a numeric matrix with genes in rows and samples in
  columns.
- Count values must be nonnegative and suitable for count-based
  analysis.
- Gene row names and sample column names must be unique.
- Design row names must contain the same sample names as the count
  matrix.
- `formula` must be a valid R formula using columns in `design`.
- `contrast` must follow the DESeq2 form
  `c(variable, numerator_level, denominator_level)`.

The returned object additionally stores the fitted DESeq2 dataset and
results under `count_result$deseq2`.

## Understanding the reconstructed architecture

### Level 1: module support

A module is present when it contains at least `min_module_genes`
significant unique genes.

``` r

deg_result$module_summary
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
```

The table reports:

- `annotated_genes`: unique input genes mapped to the module;
- `deg_genes`: significant genes mapped to the module;
- `up_genes` and `down_genes`: direction-specific counts;
- `present`: whether the module passed the selected threshold.

### Level 2: pairwise interfaces

An interface is supported by significant genes annotated to both
constituent core modules. It is present when the strict overlap contains
at least `min_interface_genes` unique genes.

``` r

deg_result$interface_summary
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
```

The default PHMIES interfaces are:

- Hormone-MAPK;
- Hormone-Information exchange;
- MAPK-Information exchange.

### Level 3A

Level 3A is present when:

1.  all three PHMIES core modules are present; and
2.  all three required pairwise interfaces are present.

``` r

deg_result$level3a_present
#> [1] TRUE
```

### Level 3B

A strict Level 3B gene is a significant gene assigned to all three
PHMIES core modules in the same analysis.

``` r

deg_result$level3b_count
#> [1] 4
deg_result$level3b_genes
#> [1] "FA_G001" "FA_G002" "FA_G003" "FA_G004"
```

Level 3A and Level 3B are separate results. Level 3A describes recovery
of the complete three-module interface architecture; Level 3B identifies
strict genes occupying the three-way overlap.

## Architecture metrics

``` r

deg_result$metrics
#> $metric_version
#> [1] "0.1.0"
#> 
#> $weighted_isi
#> [1] 1
#> 
#> $level1_fraction
#> [1] 1
#> 
#> $level2_fraction
#> [1] 1
#> 
#> $architecture_entropy
#> [1] 1
#> 
#> $architecture_balance
#> [1] 1
deg_result$robustness
#> $method
#> [1] "Composite preliminary robustness score v0.1.0"
#> 
#> $score
#> [1] 1
#> 
#> $label
#> [1] "High"
```

### Weighted ISI

The current weighted ISI combines four components:

- fraction of Level 1 modules present: weight 0.25;
- fraction of Level 2 interfaces present: weight 0.35;
- Level 3A presence: weight 0.20;
- any Level 3B presence: weight 0.20.

The score ranges from 0 to 1. The implementation records a metric
version so future changes can be tracked.

### Architecture entropy

The current entropy statistic is normalized Shannon entropy calculated
from the significant-gene counts of the three core modules. A larger
value indicates more even distribution of core-module support.

### Architecture balance

The current balance statistic is the minimum core-module DEG count
divided by the maximum core-module DEG count. A value of 1 indicates
equal counts across the three core modules.

### Architecture class

The current rules are:

- **Class IV:** Level 3A is present and at least one strict Level 3B
  gene exists.
- **Class III:** Level 3A is present, or at least two-thirds of required
  interfaces are present.
- **Class II:** at least half of Level 1 modules are present, or at
  least one required interface is present.
- **Class I:** none of the preceding conditions are met.

### Robustness label

The current preliminary score averages weighted ISI, balance, entropy,
and annotation coverage, then adds 0.10 when the Level 3B permutation
P-value is at most 0.05. Scores are labeled High at 0.75 or greater,
Moderate at 0.50 to less than 0.75, and Low below 0.50.

This score is an analytical summary, not yet a substitute for sample
bootstrapping, annotation sensitivity analysis, or independent
biological validation.

## Level 3B permutation test

``` r

deg_result$null_model[c(
  "method",
  "n_permutations",
  "expected",
  "observed",
  "p_value"
)]
#> $method
#> [1] "Random DEG-label assignment preserving DEG count and annotation membership"
#> 
#> $n_permutations
#> [1] 100
#> 
#> $expected
#> [1] 1.26
#> 
#> $observed
#> [1] 4
#> 
#> $p_value
#> [1] 0.01980198
```

The default null model randomly assigns the observed number of DEG
labels among input genes while preserving the annotation memberships.
For each permutation, the package counts how many strict
triple-annotated genes receive a DEG label. The empirical P-value uses a
finite-permutation correction and therefore cannot be zero.

For final analyses, use a substantially larger number of permutations
than the 100 used in this vignette, for example:

``` r

n_permutations = 10000
```

## Inspecting the returned object

The main components are:

``` r

names(deg_result)
#>  [1] "call"                    "metadata"               
#>  [3] "input_audit"             "differential_expression"
#>  [5] "mapped_annotation"       "gene_membership"        
#>  [7] "module_summary"          "interface_summary"      
#>  [9] "level3a_present"         "level3b_genes"          
#> [11] "level3b_count"           "metrics"                
#> [13] "null_model"              "architecture_class"     
#> [15] "robustness"              "definition"             
#> [17] "provenance"
```

- `call`: reconstructed function call;
- `metadata`: species, architecture version, thresholds, and seed;
- `input_audit`: gene counts and annotation coverage;
- `differential_expression`: standardized DEG table;
- `mapped_annotation`: recognized gene-module assignments;
- `gene_membership`: gene-level architecture membership and Level 3B
  status;
- `module_summary`: Level 1 support;
- `interface_summary`: Level 2 support;
- `level3a_present`: logical Level 3A result;
- `level3b_genes` and `level3b_count`: strict Level 3B result;
- `metrics`: weighted ISI, entropy, balance, and component fractions;
- `null_model`: permutation method, expectation, P-value, and
  distribution;
- `architecture_class`: Class I-IV;
- `robustness`: current composite score and label;
- `definition`: full architecture definition used;
- `provenance`: package version, R version, and analysis time.

Use [`summary()`](https://rdrr.io/r/base/summary.html) for a compact
structured view.

``` r

summary(deg_result)
#> $species
#> [1] "synthetic fruit example"
#> 
#> $architecture
#> [1] "PHMIES"
#> 
#> $architecture_class
#> [1] "IV"
#> 
#> $weighted_isi
#> [1] 1
#> 
#> $level3a_present
#> [1] TRUE
#> 
#> $level3b_count
#> [1] 4
#> 
#> $robustness
#> $robustness$method
#> [1] "Composite preliminary robustness score v0.1.0"
#> 
#> $robustness$score
#> [1] 1
#> 
#> $robustness$label
#> [1] "High"
#> 
#> 
#> $entropy
#> [1] 1
#> 
#> $balance
#> [1] 1
#> 
#> $null_model
#> $null_model$method
#> [1] "Random DEG-label assignment preserving DEG count and annotation membership"
#> 
#> $null_model$expected
#> [1] 1.26
#> 
#> $null_model$observed
#> [1] 4
#> 
#> $null_model$p_value
#> [1] 0.01980198
#> 
#> 
#> $input_audit
#> $input_audit$input_genes
#> [1] 60
#> 
#> $input_audit$significant_genes
#> [1] 20
#> 
#> $input_audit$mapped_genes
#> [1] 60
#> 
#> $input_audit$annotation_coverage
#> [1] 1
#> 
#> 
#> $module_summary
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
#> 
#> $interface_summary
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
#> 
#> attr(,"class")
#> [1] "summary.fruit_architecture"
```

## Figures

[`plot()`](https://rdrr.io/r/graphics/plot.default.html) returns a
`ggplot` object and supports three standard types.

### Module-support plot

``` r


print(
  plot(
    deg_result,
    type = "modules"
  )
)
```

![Horizontal bar chart showing the number of significant genes assigned
to each fruit architecture
module.](fruitArchitecture-user-manual_files/figure-html/module-plot-1.png)

### Interface-support plot

``` r

print(
  plot(
    deg_result,
    type = "interfaces"
  )
)
```

![Horizontal bar chart showing strict gene overlap across the three
pairwise PHMIES module
interfaces.](fruitArchitecture-user-manual_files/figure-html/interface-plot,%20-1.png)

### Level 3B null distribution

``` r

print(
  plot(
    deg_result,
    type = "null"
  )
)
```

![Histogram of Level 3B gene counts from the permutation null model with
the observed Level 3B count marked by a vertical dashed
line.](fruitArchitecture-user-manual_files/figure-html/null-plot,%20-1.png)

Because the returned plots are `ggplot2` objects, users can add labels,
themes, or other layers before saving them.

``` r

p <- plot(deg_result, type = "modules")
p + ggplot2::labs(subtitle = "Custom analysis subtitle")
```

## Exporting results

### Export tables and the complete object

``` r

output_directory <- file.path(
  getwd(),
  "fruitArchitecture_results"
)

exportArchitecture(
  deg_result,
  directory = output_directory,
  prefix = "my_contrast"
)
```

This writes:

- standardized differential-expression table;
- gene-level architecture membership table;
- module summary;
- interface summary;
- one-row architecture summary;
- complete `fruit_architecture` object as an RDS file.

Reload the complete object with:

``` r

restored_result <- readRDS(
  file.path(output_directory, "my_contrast_object.rds")
)
```

### Export figures

``` r

exportFigures(
  deg_result,
  directory = file.path(output_directory, "figures"),
  formats = c("pdf", "png", "tiff"),
  width = 9,
  height = 6,
  dpi = 600
)
```

PDF is vector output. PNG and TIFF are raster outputs. Use TIFF at 600
dpi when required by a journal, and retain PDF for editing and
archiving.

## Using custom column names

A DEG table may use different field names. Supply the relevant names
explicitly.

``` r

result <- fruitArchitectureFromDEG(
  deg_table = my_results,
  annotation = my_annotation,
  species = "Malus domestica",
  gene_id_col = "gene",
  log2fc_col = "logFC",
  padj_col = "FDR"
)
```

The annotation gene-identifier column must have the same name passed in
`gene_id_col`. Annotation must also include either `module` or
`pathway_name`.

## Using a custom architecture definition

Advanced users may pass a list instead of `"PHMIES"`. A custom
definition must contain:

- `name`;
- `modules`;
- `core_modules`;
- `interfaces`;
- `weights`.

For reliable annotation matching, it should also contain `aliases`.

``` r

custom_definition <- list(
  name = "MyArchitecture",
  version = "1.0.0",
  modules = c("Module A", "Module B", "Module C"),
  aliases = list(
    "Module A" = c("module a", "a"),
    "Module B" = c("module b", "b"),
    "Module C" = c("module c", "c")
  ),
  core_modules = c("Module A", "Module B", "Module C"),
  interfaces = data.frame(
    interface = c("A-B", "A-C", "B-C"),
    module_a = c("Module A", "Module A", "Module B"),
    module_b = c("Module B", "Module C", "Module C"),
    stringsAsFactors = FALSE
  ),
  weights = list(
    level1 = 0.25,
    level2 = 0.35,
    level3a = 0.20,
    level3b = 0.20
  )
)

custom_result <- fruitArchitectureFromDEG(
  deg_table = my_results,
  annotation = my_annotation,
  architecture_definition = custom_definition
)
```

## Species support

``` r

supportedSpecies()
#>    species_code      scientific_name built_in_annotation
#> 1         apple      Malus domestica               FALSE
#> 2        banana       Musa acuminata               FALSE
#> 3      cucumber      Cucumis sativus               FALSE
#> 4         grape       Vitis vinifera               FALSE
#> 5         melon         Cucumis melo               FALSE
#> 6        papaya        Carica papaya               FALSE
#> 7         peach       Prunus persica               FALSE
#> 8          pear           Pyrus spp.               FALSE
#> 9    strawberry        Fragaria spp.               FALSE
#> 10       tomato Solanum lycopersicum               FALSE
#> 11   watermelon    Citrullus lanatus               FALSE
#>                                           status
#> 1  Planned; supply `annotation` in version 0.1.0
#> 2  Planned; supply `annotation` in version 0.1.0
#> 3  Planned; supply `annotation` in version 0.1.0
#> 4  Planned; supply `annotation` in version 0.1.0
#> 5  Planned; supply `annotation` in version 0.1.0
#> 6  Planned; supply `annotation` in version 0.1.0
#> 7  Planned; supply `annotation` in version 0.1.0
#> 8  Planned; supply `annotation` in version 0.1.0
#> 9  Planned; supply `annotation` in version 0.1.0
#> 10 Planned; supply `annotation` in version 0.1.0
#> 11 Planned; supply `annotation` in version 0.1.0
```

In version 0.1.x, the registry lists planned species, but built-in
genome-release annotations are not yet distributed. Users must supply an
annotation table. The `species` argument is currently a label stored in
the result; it does not select a built-in annotation resource.

## Common problems

### `No annotation rows matched`

Check that:

- the annotation contains `gene_id` and `module` or `pathway_name`;
- gene identifiers match those in the DEG table;
- module names or aliases match the selected architecture definition;
- no genome-build or annotation-release mismatch is present.

### Annotation coverage is unexpectedly low

Inspect:

``` r

result$input_audit
head(result$mapped_annotation)
```

Low coverage should be resolved before comparing species or experiments.

### `DESeq2` is required

Install `DESeq2`, or analyze differential expression separately and use
[`fruitArchitectureFromDEG()`](https://ensignanalytics.github.io/fruitArchitecture/reference/fruitArchitectureFromDEG.md).

### No null plot is available

The null plot is unavailable when `n_permutations = 0`. Re-run the
analysis with at least one permutation; use thousands for inferential
work.

### Windows package reinstall warnings

Close all R and RStudio sessions before updating packages that contain
loaded DLL files. Remove stale `00LOCK` directories only after all R
processes have closed.

## Reproducibility checklist

For a reportable analysis, retain:

1.  the original counts or DEG table;
2.  the sample design and contrast definition;
3.  the full annotation table and its source/version;
4.  package and architecture-definition versions;
5.  `alpha`, fold-change threshold, overlap thresholds, permutations,
    and seed;
6.  the exported RDS result object;
7.  [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) output.

``` r

sessionInfo()
#> R version 4.5.0 (2025-04-11 ucrt)
#> Platform: x86_64-w64-mingw32/x64
#> Running under: Windows 11 x64 (build 26200)
#> 
#> Matrix products: default
#>   LAPACK version 3.12.1
#> 
#> locale:
#> [1] LC_COLLATE=English_United States.utf8 
#> [2] LC_CTYPE=English_United States.utf8   
#> [3] LC_MONETARY=English_United States.utf8
#> [4] LC_NUMERIC=C                          
#> [5] LC_TIME=English_United States.utf8    
#> 
#> time zone: America/Los_Angeles
#> tzcode source: internal
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] fruitArchitecture_0.1.4
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6       jsonlite_2.0.0     dplyr_1.2.1        compiler_4.5.0    
#>  [5] tidyselect_1.2.1   jquerylib_0.1.4    systemfonts_1.2.2  scales_1.4.0      
#>  [9] textshaping_1.0.0  yaml_2.3.10        fastmap_1.2.0      ggplot2_4.0.3     
#> [13] R6_2.6.1           labeling_0.4.3     generics_0.1.3     knitr_1.51        
#> [17] htmlwidgets_1.6.4  tibble_3.3.1       desc_1.4.3         bslib_0.9.0       
#> [21] pillar_1.10.2      RColorBrewer_1.1-3 rlang_1.2.0        cachem_1.1.0      
#> [25] xfun_0.52          fs_1.6.5           sass_0.4.9         S7_0.2.2          
#> [29] cli_3.6.4          pkgdown_2.2.1      withr_3.0.3        magrittr_2.0.3    
#> [33] digest_0.6.37      grid_4.5.0         rstudioapi_0.17.1  lifecycle_1.0.5   
#> [37] vctrs_0.7.3        evaluate_1.0.3     glue_1.8.0         farver_2.1.2      
#> [41] ragg_1.4.0         rmarkdown_2.31     tools_4.5.0        pkgconfig_2.0.3   
#> [45] htmltools_0.5.8.1
```
