# Export standard package figures

Export standard package figures

## Usage

``` r
exportFigures(
  x,
  directory,
  formats = c("pdf", "png", "tiff"),
  width = 9,
  height = 6,
  dpi = 600
)
```

## Arguments

- x:

  A `fruit_architecture` object.

- directory:

  Output directory.

- formats:

  Any combination of `"pdf"`, `"png"`, and `"tiff"`.

- width:

  Figure width in inches.

- height:

  Figure height in inches.

- dpi:

  Raster resolution.

## Value

Invisibly returns generated paths.
