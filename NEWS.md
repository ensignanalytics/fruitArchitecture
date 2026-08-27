# fruitArchitecture 0.2.0.9003

* Corrected `paper5_frozen` reconstruction so the frozen Broad6 architecture
  now reports all 15 pairwise interfaces, while Level 3A remains restricted
  to the three declared PHMIES core interfaces.
* Added `required_level2_fraction` to distinguish PHMIES required-interface
  support from the full 15-edge Broad6 Level 2 topology.
* Corrected Class I-IV evaluation when `extended_interfaces_affect_class = FALSE`:
  extended Broad6 interfaces no longer independently promote PHMIES class.
* Added definition-stable `interface_id` values to `interface_summary` for
  auditable, orientation-independent interface matching. Frozen PHMIES v0.1
  identifiers remain unchanged; Broad6-compatible definitions use canonical
  module-pair identifiers.
* Weighted ISI continues to use the complete reconstructed Level 2 topology;
  therefore `paper5_frozen` ISI values can change relative to 0.2.0.9002 because
  the implementation now evaluates the documented 15-interface universe.
* The scientific PHMIES requirements are unchanged: Level 3A requires all
  three Hormone-MAPK-Information Exchange pairwise interfaces, and strict
  Level 3B requires a DEG gene assigned to all three PHMIES core modules.

# fruitArchitecture 0.2.0.9002

* Corrected Broad6 Level 3A reconstruction so that Level 3A is determined
  by the three declared PHMIES core interfaces rather than requiring all
  15 Broad6 pairwise interfaces.
* Broad6 module detection, all 15 interface calls, Level 3B, entropy, balance,
  null-model testing, PHMIES, and paper5_frozen behavior are unchanged. The
  weighted-ISI formula is unchanged, but Broad6 ISI and class can change when
  the corrected Level 3A call changes.
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
