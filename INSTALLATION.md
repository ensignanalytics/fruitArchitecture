# Installing fruitArchitecture

This guide distinguishes the three file formats R users are likely to receive.

## A. Extracted package project directory

The directory contains `DESCRIPTION`, `NAMESPACE`, `R/`, and other package
files. Install it with `remotes::install_local()` or `devtools::install()`.

```r
user_library <- .libPaths()[1]

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

## B. Built source package

A built source package is normally named like
`fruitArchitecture_0.1.1.tar.gz`.

```r
install.packages(
  "C:/path/to/fruitArchitecture_0.1.1.tar.gz",
  repos = NULL,
  type = "source",
  lib = .libPaths()[1]
)
```

## C. Built Windows binary package

A Windows binary is normally named like `fruitArchitecture_0.1.1.zip`. Only a
ZIP produced as an R binary package should be installed with `win.binary`.

```r
install.packages(
  "C:/path/to/fruitArchitecture_0.1.1.zip",
  repos = NULL,
  type = "win.binary",
  lib = .libPaths()[1]
)
```

## Optional DESeq2 installation

```r
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
BiocManager::install("DESeq2", ask = FALSE, update = FALSE)
```

## Verification

```r
library(fruitArchitecture)
packageVersion("fruitArchitecture")
find.package("fruitArchitecture")
```

## Windows locked-DLL recovery

Close every R and RStudio process before updating packages that are already
loaded. After restarting R, remove stale lock directories only from the active
user library:

```r
user_library <- .libPaths()[1]
lock_directories <- list.files(
  user_library,
  pattern = "^00LOCK",
  full.names = TRUE
)
unlink(lock_directories, recursive = TRUE, force = TRUE)

install.packages(c("rlang", "glue", "cli"), lib = user_library)
```

## Install and build the manuals

For a local source install that also builds the R vignettes, use:

```r
remotes::install_local(
  path = "C:/fruitArchitecture",
  lib = .libPaths()[1],
  dependencies = c("Depends", "Imports", "LinkingTo"),
  upgrade = "never",
  force = TRUE,
  build_vignettes = TRUE
)
```

After installation:

```r
vignette("fruitArchitecture-user-manual", package = "fruitArchitecture")
vignette("function-data-reference", package = "fruitArchitecture")
```

Static HTML copies are also installed under `manuals` and can be opened with
`browseURL(system.file("manuals", "fruitArchitecture-user-manual.html",
package = "fruitArchitecture"))`.
