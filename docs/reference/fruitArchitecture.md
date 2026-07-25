# Reconstruct a signaling architecture from an RNA-seq count matrix

Reconstruct a signaling architecture from an RNA-seq count matrix

## Usage

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

## Arguments

- counts:

  Integer count matrix with genes in rows and samples in columns.

- design:

  Sample metadata with sample names as row names.

- species:

  Species label.

- formula:

  Experimental design formula.

- contrast:

  DESeq2 contrast of the form
  `c(variable, numerator_level, denominator_level)`.

- annotation:

  Gene-to-module or gene-to-pathway annotation table.

- alpha:

  Adjusted P-value threshold.

- log2fc_threshold:

  Absolute log2 fold-change threshold.

- architecture_definition:

  Architecture definition.

- min_module_genes:

  Minimum significant genes per module.

- min_interface_genes:

  Minimum strict overlap genes per interface.

- n_permutations:

  Number of Level 3B permutations.

- seed:

  Random seed.

- quiet:

  Suppress DESeq2 progress output when possible.

## Value

An object of class `fruit_architecture`.
