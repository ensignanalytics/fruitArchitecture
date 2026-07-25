# Contributing to fruitArchitecture

Please open an issue before making changes to architecture definitions, metric
equations, null models, or classification rules. Such changes can alter
published biological interpretations and must include regression tests and a
versioned methods note.

Code contributions should:

1. include tests;
2. preserve backward compatibility when possible;
3. document changes with roxygen2;
4. pass `devtools::check()` without errors, warnings, or notes; and
5. update `NEWS.md` when user-visible behavior changes.
