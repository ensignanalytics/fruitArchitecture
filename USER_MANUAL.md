# Purpose and scope

`fruitArchitecture` reconstructs annotation-derived signaling organization from
transcriptomic evidence. It summarizes significant genes within predefined
modules, measures strict gene overlap between core modules, identifies Level 3A
and Level 3B organization, calculates architecture metrics, performs a
permutation-based Level 3B test, assigns an architecture class, and produces
standard figures and export tables.

The package accepts either:

1. a completed differential-expression table; or
2. an RNA-seq count matrix and sample design analyzed internally with `DESeq2`.

The current default architecture is **PHMIES**, which contains the core modules
Plant hormone signal transduction, MAPK signaling, and Information exchange.
The default definition also tracks seven additional recurrent modules:
Circadian rhythm, Protein processing in endoplasmic reticulum, RNA transport,
RNA degradation, SNARE interactions, Autophagy, and Sulfur relay system.

> **Development status.** Version 0.1.x is an early research-software release.
> The weighted ISI, entropy, balance, robustness score, and class thresholds are
> implemented reproducibly, but their scientific definitions remain versioned
> and should be treated as provisional until the package methods paper and
> validation analyses are finalized.

# Installation

## Install from an extracted source directory

Extract the source package so that `DESCRIPTION`, `NAMESPACE`, and the `R/`
directory are located directly inside the package directory. Then install it
into the first local library returned by `.libPaths()`.

```r
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

Restart R after installation, then verify the installed version and location.

```r
library(fruitArchitecture)
packageVersion("fruitArchitecture")
find.package("fruitArchitecture")
```

## Optional dependency for raw-count analysis

The DEG-table workflow does not require `DESeq2`. Install `DESeq2` only when
using `fruitArchitecture()` with a count matrix.

```r
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

BiocManager::install(
  "DESeq2",
  ask = FALSE,
  update = FALSE
)
```

# Quick start

The fastest installation test is the bundled synthetic analysis.

```r
result <- fruitArchitectureExample(
  n_permutations = 100,
  seed = 1234,
  export = FALSE
)
```

The returned object has class `fruit_architecture`.

```r
class(result)
```

Printing the object reports the principal architecture results.

```r
result
```

# Bundled example data

The package includes four synthetic CSV files under `inst/extdata`. The files
are installed with the package and can be loaded together with
`fruitArchitectureExampleData()`.

```r
example_data <- fruitArchitectureExampleData()
names(example_data)
```

The example is deliberately constructed to demonstrate a complete Class IV
result. It is **not** a biological dataset and should not be used as evidence
for any species or biological process.

## Differential-expression table

```r
dim(example_data$deg_table)
head(example_data$deg_table)
```

The table contains 60 synthetic genes and the following required columns:

- `gene_id`: unique gene identifier;
- `log2_fold_change`: signed effect size;
- `adjusted_p_value`: multiple-testing-adjusted P-value.

It also includes optional fields used for inspection and export:
`base_mean`, `standard_error`, `statistic`, and `p_value`.

## Annotation table

```r
dim(example_data$annotation)
head(example_data$annotation)
```

The annotation table is in long format. A gene may occur in several rows when
it belongs to several modules. The minimum required columns are:

- `gene_id`; and
- either `module` or `pathway_name`.

The bundled annotation contains assignments to all ten default modules. Four
significant synthetic genes are assigned to all three PHMIES core modules and
therefore qualify as strict Level 3B genes.

## Count matrix

```r
dim(example_data$counts)
example_data$counts[1:5, , drop = FALSE]
```

The count matrix contains 60 genes and six samples: three immature and three
ripe synthetic replicates. Genes are rows and samples are columns.

## Sample design

```r
example_data$design
```

The design has one row per sample. Its row names must match the count-matrix
column names exactly.

# Recommended workflow: start from a DEG table

For method development and cross-platform applications, beginning with a
validated DEG table is the most direct workflow.

```r
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
```

## DEG decision rule

A gene is marked significant when both conditions are met:

```text
adjusted_p_value <= alpha
abs(log2_fold_change) >= log2fc_threshold
```

The package records significant genes as `Up` or `Down`. All other genes are
recorded as `Not significant`.

## Annotation matching

Module names may be supplied directly, or recognized aliases may be used. For
example, the default definition maps `PHST` to Plant hormone signal
transduction, `MAPK` to MAPK signaling, and `PPI` or `Defense` to Information
exchange. Annotation text that does not match a defined module or alias is not
used in reconstruction.

Inspect the mapped annotation and coverage before interpreting the architecture.

```r
deg_result$input_audit
tail(deg_result$mapped_annotation)
```

Low annotation coverage can indicate incompatible gene identifiers, genome
release mismatch, incomplete functional annotation, or a genuinely limited set
of architecture-relevant genes.

# Raw-count workflow with DESeq2

The raw-count interface runs `DESeq2`, constructs a standardized DEG table, and
passes the result to the same architecture engine used by
`fruitArchitectureFromDEG()`.

```r
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

## Raw-count requirements

- Counts must be a numeric matrix with genes in rows and samples in columns.
- Count values must be nonnegative and suitable for count-based analysis.
- Gene row names and sample column names must be unique.
- Design row names must contain the same sample names as the count matrix.
- `formula` must be a valid R formula using columns in `design`.
- `contrast` must follow the DESeq2 form
  `c(variable, numerator_level, denominator_level)`.

The returned object additionally stores the fitted DESeq2 dataset and results
under `count_result$deseq2`.

# Understanding the reconstructed architecture

## Level 1: module support

A module is present when it contains at least `min_module_genes` significant
unique genes.

```r
deg_result$module_summary
```

The table reports:

- `annotated_genes`: unique input genes mapped to the module;
- `deg_genes`: significant genes mapped to the module;
- `up_genes` and `down_genes`: direction-specific counts;
- `present`: whether the module passed the selected threshold.

## Level 2: pairwise interfaces

An interface is supported by significant genes annotated to both constituent
core modules. It is present when the strict overlap contains at least
`min_interface_genes` unique genes.

```r
deg_result$interface_summary
```

The default PHMIES interfaces are:

- Hormone-MAPK;
- Hormone-Information exchange;
- MAPK-Information exchange.

## Level 3A

Level 3A is present when:

1. all three PHMIES core modules are present; and
2. all three required pairwise interfaces are present.

```r
deg_result$level3a_present
```

## Level 3B

A strict Level 3B gene is a significant gene assigned to all three PHMIES core
modules in the same analysis.

```r
deg_result$level3b_count
deg_result$level3b_genes
```

Level 3A and Level 3B are separate results. Level 3A describes recovery of the
complete three-module interface architecture; Level 3B identifies strict genes
occupying the three-way overlap.

# Architecture metrics

```r
deg_result$metrics
deg_result$robustness
```

## Weighted ISI

The current weighted ISI combines four components:

- fraction of Level 1 modules present: weight 0.25;
- fraction of Level 2 interfaces present: weight 0.35;
- Level 3A presence: weight 0.20;
- any Level 3B presence: weight 0.20.

The score ranges from 0 to 1. The implementation records a metric version so
future changes can be tracked.

For Broad6 and `paper5_frozen`, `level2_fraction` is calculated across all 15
reconstructed Broad6 interfaces and therefore contributes expanded topology to
weighted ISI. The separate `required_level2_fraction` is calculated only across
the three PHMIES core interfaces and is used for the required-interface portion
of the PHMIES Class I-IV call when extended interfaces are not allowed to affect
class.

## Architecture entropy

The current entropy statistic is normalized Shannon entropy calculated from
the significant-gene counts of the three core modules. A larger value indicates
more even distribution of core-module support.

## Architecture balance

The current balance statistic is the minimum core-module DEG count divided by
the maximum core-module DEG count. A value of 1 indicates equal counts across
the three core modules.

## Architecture class

The current rules are:

- **Class IV:** Level 3A is present and at least one strict Level 3B gene exists.
- **Class III:** Level 3A is present, or at least two-thirds of required
  interfaces are present.
- **Class II:** at least half of Level 1 modules are present, or at least one
  required interface is present.
- **Class I:** none of the preceding conditions are met.

## Robustness label

The current preliminary score averages weighted ISI, balance, entropy, and
annotation coverage, then adds 0.10 when the Level 3B permutation P-value is at
most 0.05. Scores are labeled High at 0.75 or greater, Moderate at 0.50 to less
than 0.75, and Low below 0.50.

This score is an analytical summary, not yet a substitute for sample
bootstrapping, annotation sensitivity analysis, or independent biological
validation.

# Level 3B permutation test

```r
deg_result$null_model[c(
  "method",
  "n_permutations",
  "expected",
  "observed",
  "p_value"
)]
```

The default null model randomly assigns the observed number of DEG labels among
input genes while preserving the annotation memberships. For each permutation,
the package counts how many strict triple-annotated genes receive a DEG label.
The empirical P-value uses a finite-permutation correction and therefore cannot
be zero.

For final analyses, use a substantially larger number of permutations than the
100 used in this vignette, for example:

```r
n_permutations = 10000
```

# Inspecting the returned object

The main components are:

```r
names(deg_result)
```

- `call`: reconstructed function call;
- `metadata`: species, architecture version, thresholds, and seed;
- `input_audit`: gene counts and annotation coverage;
- `differential_expression`: standardized DEG table;
- `mapped_annotation`: recognized gene-module assignments;
- `gene_membership`: gene-level architecture membership and Level 3B status;
- `module_summary`: Level 1 support;
- `interface_summary`: Level 2 support;
- `level3a_present`: logical Level 3A result;
- `level3b_genes` and `level3b_count`: strict Level 3B result;
- `metrics`: weighted ISI, entropy, balance, and component fractions;
- `null_model`: permutation method, expectation, P-value, and distribution;
- `architecture_class`: Class I-IV;
- `robustness`: current composite score and label;
- `definition`: full architecture definition used;
- `provenance`: package version, R version, and analysis time.

Use `summary()` for a compact structured view.

```r
summary(deg_result)
```

# Figures

`plot()` returns a `ggplot` object and supports three standard types.

## Module-support plot

```r
plot(deg_result, type = "modules")
```

## Interface-support plot

```r
plot(deg_result, type = "interfaces")
```

## Level 3B null distribution

```r
plot(deg_result, type = "null")
```

Because the returned plots are `ggplot2` objects, users can add labels, themes,
or other layers before saving them.

```r
p <- plot(deg_result, type = "modules")
p + ggplot2::labs(subtitle = "Custom analysis subtitle")
```

# Exporting results

## Export tables and the complete object

```r
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

```r
restored_result <- readRDS(
  file.path(output_directory, "my_contrast_object.rds")
)
```

## Export figures

```r
exportFigures(
  deg_result,
  directory = file.path(output_directory, "figures"),
  formats = c("pdf", "png", "tiff"),
  width = 9,
  height = 6,
  dpi = 600
)
```

PDF is vector output. PNG and TIFF are raster outputs. Use TIFF at 600 dpi when
required by a journal, and retain PDF for editing and archiving.

# Using custom column names

A DEG table may use different field names. Supply the relevant names explicitly.

```r
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
`gene_id_col`. Annotation must also include either `module` or `pathway_name`.

# Using a custom architecture definition

Advanced users may pass a list instead of `"PHMIES"`. A custom definition must
contain:

- `name`;
- `modules`;
- `core_modules`;
- `interfaces`;
- `weights`.

For reliable annotation matching, it should also contain `aliases`.

```r
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

# Species support

```r
supportedSpecies()
```

In version 0.1.x, the registry lists planned species, but built-in genome-release
annotations are not yet distributed. Users must supply an annotation table.
The `species` argument is currently a label stored in the result; it does not
select a built-in annotation resource.

# Common problems

## `No annotation rows matched`

Check that:

- the annotation contains `gene_id` and `module` or `pathway_name`;
- gene identifiers match those in the DEG table;
- module names or aliases match the selected architecture definition;
- no genome-build or annotation-release mismatch is present.

## Annotation coverage is unexpectedly low

Inspect:

```r
result$input_audit
head(result$mapped_annotation)
```

Low coverage should be resolved before comparing species or experiments.

## `DESeq2` is required

Install `DESeq2`, or analyze differential expression separately and use
`fruitArchitectureFromDEG()`.

## No null plot is available

The null plot is unavailable when `n_permutations = 0`. Re-run the analysis with
at least one permutation; use thousands for inferential work.

## Windows package reinstall warnings

Close all R and RStudio sessions before updating packages that contain loaded
DLL files. Remove stale `00LOCK` directories only after all R processes have
closed.

# Reproducibility checklist

For a reportable analysis, retain:

1. the original counts or DEG table;
2. the sample design and contrast definition;
3. the full annotation table and its source/version;
4. package and architecture-definition versions;
5. `alpha`, fold-change threshold, overlap thresholds, permutations, and seed;
6. the exported RDS result object;
7. `sessionInfo()` output.

```r
sessionInfo()
```
