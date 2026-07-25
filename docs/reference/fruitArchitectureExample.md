# Run the bundled fruitArchitecture example

Runs architecture reconstruction using the synthetic DEG and annotation
tables installed with the package. Optionally exports result tables and
publication-ready PDF, PNG, and TIFF figures.

## Usage

``` r
fruitArchitectureExample(
  output_directory = file.path(getwd(), "fruitArchitecture_example_output"),
  n_permutations = 100,
  seed = 1234,
  export = FALSE,
  formats = c("pdf", "png", "tiff"),
  dpi = 600
)
```

## Arguments

- output_directory:

  Directory for exported example results.

- n_permutations:

  Number of permutations used by the Level 3B null model.

- seed:

  Random seed.

- export:

  Logical; export tables, an RDS object, and figures.

- formats:

  Figure formats passed to
  [`exportFigures()`](https://ensignanalytics.github.io/fruitArchitecture/reference/exportFigures.md).

- dpi:

  Resolution for raster figures.

## Value

Invisibly returns a `fruit_architecture` object.
