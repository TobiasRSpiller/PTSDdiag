## Submission

This is an update of the CRAN package PTSDdiag (current CRAN version: 0.1.0;
this submission: 0.3.5). Highlights since 0.1.0:

* Multi-scenario optimization (`compare_optimizations()`) with summary
  tables, a symptom-frequency heatmap, and ICD-11 / CAPS-5 benchmarks.
* Portable symptom-definition workflows (JSON export/import,
  `extract_definitions()` / `evaluate_definitions()`) for multi-site studies.
* New `score_by = "balanced_accuracy"` optimization criterion, now the
  default; balanced accuracy is reported in all performance tables.
* Error messaging migrated to cli, an expanded test suite, and five
  rewritten vignettes that build quickly on small subsets of the bundled
  data.

See NEWS.md for the complete changelog.

## R CMD check results

0 errors | 0 warnings | 1 note

* checking for future file timestamps ... NOTE
  unable to verify current time

  This NOTE appears only in the local check environment, which has no
  network access to a time server. It is unrelated to the package.

## Test environments

* local macOS (aarch64-apple-darwin20), R 4.5.2
* win-builder (devel and release)

## Downstream dependencies

There are no reverse dependencies on CRAN.
