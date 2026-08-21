# fruitArchitecture 0.2.0.9002

* Corrected Broad6 Level 3A reconstruction so that Level 3A is determined
  by the three declared PHMIES core interfaces rather than requiring all
  15 Broad6 pairwise interfaces.
* Broad6 module detection, all 15 interface calls, Level 3B, ISI, entropy,
  balance, null-model testing, PHMIES, and paper5_frozen behavior are unchanged.
* Added regression tests for Broad6, PHMIES, and paper5_frozen definitions.

# fruitArchitecture 0.2.0.9001

* Added Broad6 Level 3A reconstruction.
* Added ethylene biosynthesis circuitry definition based on fruitENCODE feedback loop genes/enzymes.
* Broad6 module detection, all 15 interface calls, Level 3B, ISI, entropy,
  balance, null-model testing, PHMIES, and paper5_frozen behavior are unchanged.

# fruitArchitecture 0.1.4

- Added a comprehensive package user manual vignette covering installation, input requirements, DEG-table and raw-count workflows, architecture reconstruction, metrics, null-model testing, figures, exports, custom definitions, troubleshooting, and reproducibility.
- Added a separate function and data reference vignette documenting the public API, S3 methods, example datasets, default PHMIES content, output-object structure, and package directories.
- Added top-level guide files that direct repository users to the installed vignettes.

# fruitArchitecture 0.1.3

- Fixed `fruitArchitectureExampleData()` on installed packages by preserving the names of bundled example-file paths.
- Added direct regression tests for the example-data loader and one-command example workflow.

# fruitArchitecture 0.1.2

- Adds `fruitArchitectureExampleData()` to load all installed synthetic sample files.
- Adds `fruitArchitectureExample()` as a stable one-command example workflow.
- Keeps the traditional `demo("fruitArchitecture-example")` entry point.
- Includes synthetic DEG, annotation, count, and design files under `inst/extdata`.
- Improves missing-example-file diagnostics.
- Records the installed package version dynamically in analysis provenance.

# fruitArchitecture 0.1.1

- Added installed sample DEG, annotation, count, and design files.
- Added demo and installed example scripts.
- Added sample-workflow regression tests.

# fruitArchitecture 0.1.0

- Initial package scaffold and architecture reconstruction engine.
