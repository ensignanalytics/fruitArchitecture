# Reconstruct a signaling architecture from a differential-expression table

Reconstruct a signaling architecture from a differential-expression
table

## Usage

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

## Arguments

- deg_table:

  A data frame containing one row per gene.

- annotation:

  A long-format data frame containing gene-to-module or gene-to-pathway
  assignments.

- species:

  Optional species label.

- gene_id_col:

  Name of the gene identifier column in `deg_table`.

- log2fc_col:

  Name of the log2 fold-change column.

- padj_col:

  Name of the adjusted P-value column.

- alpha:

  Adjusted P-value threshold.

- log2fc_threshold:

  Absolute log2 fold-change threshold.

- architecture_definition:

  Either `"PHMIES"` or a custom definition list.

- min_module_genes:

  Minimum number of significant genes required for a module to be
  considered present.

- min_interface_genes:

  Minimum number of strict overlap genes required for a pairwise
  interface to be considered present.

- n_permutations:

  Number of permutations for the Level 3B null model.

- seed:

  Random seed.

## Value

An object of class `fruit_architecture`.
