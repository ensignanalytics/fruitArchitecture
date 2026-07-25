# Public API at a glance

| Function or method | Purpose | Principal return value |
|----|----|----|
| [`fruitArchitectureFromDEG()`](https://ensignanalytics.github.io/fruitArchitecture/reference/fruitArchitectureFromDEG.md) | Reconstruct an architecture from a completed DEG table and annotation | `fruit_architecture` object |
| [`fruitArchitecture()`](https://ensignanalytics.github.io/fruitArchitecture/reference/fruitArchitecture.md) | Run DESeq2 from raw counts, then reconstruct the architecture | `fruit_architecture` object containing DESeq2 results |
| [`fruitArchitectureExampleData()`](https://ensignanalytics.github.io/fruitArchitecture/reference/fruitArchitectureExampleData.md) | Load all bundled synthetic example objects | Named list |
| [`fruitArchitectureExample()`](https://ensignanalytics.github.io/fruitArchitecture/reference/fruitArchitectureExample.md) | Run and optionally export the complete bundled example | Invisible `fruit_architecture` object |
| [`supportedSpecies()`](https://ensignanalytics.github.io/fruitArchitecture/reference/supportedSpecies.md) | List planned species-registry entries and built-in annotation status | Data frame |
| [`plot()`](https://rdrr.io/r/graphics/plot.default.html) | Draw module, interface, or null-distribution figures | `ggplot` object |
| [`summary()`](https://rdrr.io/r/base/summary.html) | Return a compact structured summary | `summary.fruit_architecture` list |
| [`print()`](https://rdrr.io/r/base/print.html) | Print the main analysis results | Invisibly returns the input object |
| [`exportArchitecture()`](https://ensignanalytics.github.io/fruitArchitecture/reference/exportArchitecture.md) | Export result tables and the full RDS object | Output directory, invisibly |
| [`exportFigures()`](https://ensignanalytics.github.io/fruitArchitecture/reference/exportFigures.md) | Export standard PDF, PNG, and TIFF figures | Generated file paths, invisibly |

# Analysis functions

## `fruitArchitectureFromDEG()`

``` r

fruitArchitectureFromDEG(
  deg_table,
  annotation,
  species = NULL,
  gene_id_col = "gene_id",
  log2fc_col = "log2_fold_change",
  padj_col = "adjusted_p_value",
  alpha = 0.05,
  log2fc_threshold = 1,
  architecture_definition = "PHMIES",
  min_module_genes = 1L,
  min_interface_genes = 1L,
  n_permutations = 10000L,
  seed = 1234L
)
```

Use this function when differential-expression analysis has already been
completed. It is also the recommended entry point when integrating
results from methods other than DESeq2.

### Required data

`deg_table` must have one unique row per gene and contain the columns
named by `gene_id_col`, `log2fc_col`, and `padj_col`.

`annotation` must be long format and contain the same gene-identifier
column plus either `module` or `pathway_name`.

### Main controls

- `alpha`: adjusted P-value cutoff;
- `log2fc_threshold`: absolute fold-change cutoff;
- `min_module_genes`: significant genes required for Level 1 presence;
- `min_interface_genes`: strict overlap genes required for interface
  presence;
- `n_permutations`: Level 3B null-model iterations;
- `seed`: random seed used by the null model.

## `fruitArchitecture()`

``` r

fruitArchitecture(
  counts,
  design,
  species,
  formula,
  contrast,
  annotation,
  alpha = 0.05,
  log2fc_threshold = 1,
  architecture_definition = "PHMIES",
  min_module_genes = 1L,
  min_interface_genes = 1L,
  n_permutations = 10000L,
  seed = 1234L,
  quiet = FALSE
)
```

This function requires the suggested Bioconductor package `DESeq2`. It
fits the DESeq2 model, constructs a standardized DEG table, and calls
[`fruitArchitectureFromDEG()`](https://ensignanalytics.github.io/fruitArchitecture/reference/fruitArchitectureFromDEG.md).

### Additional returned content

The result includes:

``` text
result$deseq2$dds
result$deseq2$results
```

The formula and contrast are recorded under `result$metadata`.

# Example and discovery functions

## `fruitArchitectureExampleData()`

``` r

example_data <- fruitArchitectureExampleData()
```

Returns a named list:

| Element | Class | Dimensions | Description |
|----|---:|---:|----|
| `deg_table` | data frame | 60 rows | Synthetic differential-expression statistics |
| `annotation` | data frame | 74 rows | Long-format gene-to-module assignments |
| `counts` | integer matrix | 60 x 6 | Synthetic immature-versus-ripe count matrix |
| `design` | data frame | 6 rows | Sample condition metadata |
| `directory` | character | length 1 | Installed `extdata` directory |

The data are synthetic and intended only for installation testing,
examples, and regression tests.

## `fruitArchitectureExample()`

``` r

fruitArchitectureExample(
  output_directory = file.path(
    getwd(),
    "fruitArchitecture_example_output"
  ),
  n_permutations = 5000L,
  seed = 1234L,
  export = TRUE,
  formats = c("pdf", "png", "tiff"),
  dpi = 600
)
```

Runs the DEG-table example. With `export = TRUE`, it writes tables, an
RDS object, and all standard figures.

## `supportedSpecies()`

``` r

supportedSpecies()
```

The current table lists planned crop support. In version 0.1.x all
`built_in_annotation` values are `FALSE`; users must supply
`annotation`.

# S3 methods

## `print()`

``` r

print(result)
```

Reports species, architecture name, class, weighted ISI, Level 3A and
Level 3B status, robustness label, entropy, balance, expected Level 3B,
observed Level 3B, and empirical P-value.

## `summary()`

``` r

summary_result <- summary(result)
```

Returns a list containing metadata, primary metrics, null-model summary,
input audit, module summary, and interface summary.

## `plot()`

``` r

plot(result, type = "modules")
plot(result, type = "interfaces")
plot(result, type = "null")
```

Available plot types:

- `modules`: significant genes per Level 1 module;
- `interfaces`: strict overlap genes per required pairwise interface;
- `null`: permutation distribution with observed Level 3B marked.

# Export functions

## `exportArchitecture()`

``` r

exportArchitecture(
  x = result,
  directory = "results",
  prefix = "fruit_architecture"
)
```

Generated files:

``` text
<prefix>_differential_expression.csv
<prefix>_gene_membership.csv
<prefix>_module_summary.csv
<prefix>_interface_summary.csv
<prefix>_summary.csv
<prefix>_object.rds
```

## `exportFigures()`

``` r

exportFigures(
  x = result,
  directory = "results/figures",
  formats = c("pdf", "png", "tiff"),
  width = 9,
  height = 6,
  dpi = 600
)
```

The function exports module, interface, and null-distribution figures.
The null figure is skipped when the null model was not run.

# Bundled files

The installed package contains these example data files:

``` r

example_directory <- system.file(
  "extdata",
  package = "fruitArchitecture"
)
list.files(example_directory)
```

## `fruitArchitecture_example_deg.csv`

One row per synthetic gene.

| Column             | Meaning                              |
|--------------------|--------------------------------------|
| `gene_id`          | Unique synthetic identifier          |
| `base_mean`        | Synthetic mean expression            |
| `log2_fold_change` | Ripe-versus-immature effect size     |
| `standard_error`   | Synthetic coefficient standard error |
| `statistic`        | Synthetic test statistic             |
| `p_value`          | Synthetic raw P-value                |
| `adjusted_p_value` | Synthetic adjusted P-value           |

## `fruitArchitecture_example_annotation.csv`

Long-format assignment table.

| Column    | Meaning                                              |
|-----------|------------------------------------------------------|
| `gene_id` | Synthetic identifier matching the DEG and count data |
| `module`  | Default architecture module assignment               |

A gene can occur more than once because multi-module assignment is
required to represent interfaces and Level 3B overlap.

## `fruitArchitecture_example_counts.csv`

Synthetic integer counts. The first column is `gene_id`; the remaining
columns are six samples:

``` text
Immature_1
Immature_2
Immature_3
Ripe_1
Ripe_2
Ripe_3
```

## `fruitArchitecture_example_design.csv`

| Column      | Meaning                                          |
|-------------|--------------------------------------------------|
| `sample_id` | Sample identifier used as row names after import |
| `condition` | `immature` or `ripe`                             |

# Default PHMIES content

## Modules

1.  Circadian rhythm
2.  Plant hormone signal transduction
3.  MAPK signaling
4.  Information exchange
5.  Protein processing in endoplasmic reticulum
6.  RNA transport
7.  RNA degradation
8.  SNARE interactions
9.  Autophagy
10. Sulfur relay system

## Core modules

1.  Plant hormone signal transduction
2.  MAPK signaling
3.  Information exchange

## Required pairwise interfaces

1.  Hormone-MAPK
2.  Hormone-Information exchange
3.  MAPK-Information exchange

## Default metric weights

| Component                  | Weight |
|----------------------------|-------:|
| Level 1 module fraction    |   0.25 |
| Level 2 interface fraction |   0.35 |
| Level 3A presence          |   0.20 |
| Level 3B presence          |   0.20 |

# `fruit_architecture` object reference

| Component | Content |
|----|----|
| `call` | Matched analysis call |
| `metadata` | Species label, architecture name/version, thresholds, seed, and count-workflow details when applicable |
| `input_audit` | Input genes, significant genes, mapped genes, and annotation coverage |
| `differential_expression` | Standardized DEG table with `deg_status` and `direction` |
| `mapped_annotation` | Recognized gene-module assignments |
| `gene_membership` | Gene-module membership, DEG statistics, and Level 3B flag |
| `module_summary` | Annotated, DEG, up, and down counts by module, plus presence |
| `interface_summary` | Pairwise overlap counts, presence, and gene identifiers |
| `level3a_present` | Logical result |
| `level3b_genes` | Character vector of strict triple-overlap genes |
| `level3b_count` | Number of strict Level 3B genes |
| `metrics` | Metric version, weighted ISI, component fractions, entropy, and balance |
| `null_model` | Method, permutations, expectation, observation, P-value, and distribution |
| `architecture_class` | Character value `I`, `II`, `III`, or `IV` |
| `robustness` | Preliminary method description, score, and label |
| `definition` | Complete architecture definition used for the analysis |
| `provenance` | Package version, R version, and analysis timestamp |
| `deseq2` | Present only for the raw-count workflow; fitted dataset and result object |

# Package directory content

| Source directory | Purpose |
|----|----|
| `R/` | Package functions and methods |
| `man/` | Function help pages generated from roxygen comments |
| `vignettes/` | Long-form user manual and references |
| `inst/extdata/` | Installed example CSV files |
| `inst/examples/` | Installed complete workflow script |
| `demo/` | R [`demo()`](https://rdrr.io/r/utils/demo.html) entry point |
| `data-raw/` | Developer scripts used to create example resources; not used by installed-package workflows |
| `tests/testthat/` | Unit and regression tests |
| `inst/CITATION` | Package citation metadata |

# Finding help in R

``` r

help(package = "fruitArchitecture")
?fruitArchitecture
?fruitArchitectureFromDEG
?fruitArchitectureExample
?fruitArchitectureExampleData
?exportArchitecture
?exportFigures
?supportedSpecies
vignette(package = "fruitArchitecture")
vignette("fruitArchitecture-user-manual")
vignette("function-data-reference")
```
