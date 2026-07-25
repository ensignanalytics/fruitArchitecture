# Package build order

1. Open `fruitArchitecture.Rproj` in RStudio.
2. Replace the maintainer email and GitHub URLs in `DESCRIPTION`.
3. Run `source("data-raw/setup-development.R")`.
4. Resolve all `R CMD check` errors, warnings, and notes.
5. Freeze and document metric equations before treating version 0.1.0 as a
   scientific release.
6. Add audited species registries one genome release at a time.
7. Add reference-result regression tests for every validated species.
8. Run GitHub Actions checks on Windows, macOS, Linux, and R-devel.
9. Build with `devtools::build()`.
10. Release first through GitHub/Zenodo; consider CRAN or Bioconductor after the
    annotation-data distribution strategy is finalized.
