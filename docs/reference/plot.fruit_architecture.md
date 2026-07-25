# Plot a fruit architecture result

Creates standard visualizations for module support, pairwise interface
support, and the Level 3B permutation null distribution.

## Usage

``` r
# S3 method for class 'fruit_architecture'
plot(x, type = c("modules", "interfaces", "null"), ...)
```

## Arguments

- x:

  A `fruit_architecture` object.

- type:

  Character string specifying the plot type. Available values are
  `"modules"`, `"interfaces"`, and `"null"`.

- ...:

  Additional arguments reserved for future methods.

## Value

A `ggplot2` object.
