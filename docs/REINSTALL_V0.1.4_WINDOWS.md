# Reinstall fruitArchitecture 0.1.4 on Windows

1.  Close all R and RStudio sessions.
2.  Replace the old source directory with the extracted version 0.1.4
    package so that `C:/fruitArchitecture/DESCRIPTION` exists.
3.  Open a fresh R session and run:

``` r

package_directory <- "C:/fruitArchitecture"
user_library <- .libPaths()[1]

read.dcf(
  file.path(package_directory, "DESCRIPTION"),
  fields = c("Package", "Version")
)

if ("fruitArchitecture" %in% rownames(installed.packages())) {
  remove.packages("fruitArchitecture", lib = user_library)
}

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

manual_packages <- c("knitr", "rmarkdown")
missing_manual_packages <- manual_packages[
  !vapply(manual_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_manual_packages) > 0L) {
  install.packages(missing_manual_packages)
}

remotes::install_local(
  path = package_directory,
  lib = user_library,
  dependencies = c("Depends", "Imports", "LinkingTo"),
  upgrade = "never",
  force = TRUE,
  build_vignettes = TRUE
)
```

4.  Restart R and verify:

``` r

library(fruitArchitecture)
packageVersion("fruitArchitecture")
find.package("fruitArchitecture")
```

5.  Open the manuals:

``` r

vignette("fruitArchitecture-user-manual", package = "fruitArchitecture")
vignette("function-data-reference", package = "fruitArchitecture")
```

When vignettes were not built during installation, use the installed
static HTML copies:

``` r

browseURL(system.file(
  "manuals",
  "fruitArchitecture-user-manual.html",
  package = "fruitArchitecture"
))

browseURL(system.file(
  "manuals",
  "function-data-reference.html",
  package = "fruitArchitecture"
))
```
