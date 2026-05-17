# Changelog

## PTSDdiag 0.2.7

### New features

- [`rename_ptsd_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)
  and
  [`rename_caps5_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_caps5_columns.md)
  gain an `id_col` argument: a character vector of column name(s) to
  preserve through the workflow as participant identifiers. When
  supplied, the named columns are prepended to the renamed dataframe and
  propagate automatically through
  [`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md),
  [`optimize_combinations_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md),
  [`apply_symptom_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md),
  [`holdout_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/holdout_validation.md),
  [`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md),
  [`create_icd11_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md),
  and
  [`create_caps5_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_caps5_diagnosis.md).
  The result of each per-row function (`diagnosis_comparison`,
  `test_results`, `fold_results`, etc.) prepends these ID columns so
  diagnoses can be joined back to the original dataframe — for example,
  to compare demographics between participants who do and do not meet an
  optimized criterion.
- [`compare_diagnostic_systems()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
  automatically skips carry-through ID columns in its `...` inputs so
  they are not mistaken for diagnostic systems.

### Behavior changes

- [`binarize_data()`](https://tobiasrspiller.github.io/PTSDdiag/reference/binarize_data.md)
  now mutates only the `symptom_1`..`symptom_20` columns rather than the
  whole dataframe. Any additional columns (e.g. an ID column) are
  preserved unchanged. This fixes a latent bug where a non-numeric
  carry-through column would have been coerced or errored.
- [`create_ptsd_diagnosis_binarized()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_ptsd_diagnosis_binarized.md)
  now operates on the symptom subset only, accepting input dataframes
  with extra columns.
- [`summarize_ptsd_changes()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
  silently drops non-logical columns before computing metrics
  (previously errored). This lets ID columns ride along in comparison
  dataframes without breaking downstream summarization.

### Documentation

- New vignette `id-column-workflow` demonstrating how to use `id_col` to
  merge per-row diagnoses back to a dataframe with demographics.

## PTSDdiag 0.2.6

### Improvements

- All user-facing error messages now use the `cli` package for
  consistent, rich formatting: argument names are highlighted, actual
  values are shown, and hint bullets guide users toward fixes.
- Centralized input validation via `.validate_pcl5_data()` now accepts
  `strict_cols`, `warn_total`, and `instrument` parameters, reducing
  code duplication across exported functions.
- [`holdout_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/holdout_validation.md)
  and
  [`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md)
  now correctly restore the global RNG state on exit (replaced buggy
  [`withr::local_seed()`](https://withr.r-lib.org/reference/with_seed.html)
  with manual `on.exit` save/restore).
- Removed `withr` from Imports (no longer used).

### Documentation

- Added `@note` to `simulated_ptsd` and `simulated_ptsd_genpop` dataset
  documentation clarifying that symptoms were simulated independently
  (no within-cluster correlations).

### Tests

- New tests for RNG state restoration, edge cases
  (all-positive/all-negative baselines, binarize boundary values),
  non-integer `k` rejection, empty split guard, and `n_tied` output from
  optimization functions.

## PTSDdiag 0.2.5.1

### Bug fixes

- Fixed stale `README.md` that still linked to the removed
  `introduction.html` vignette instead of the new
  `internal_analysis.html`.
- Restored package website link in README.
- Added pkgdown site URL to DESCRIPTION `URL` field.
- Updated `JamesIves/github-pages-deploy-action` to v4.7.3 for Node.js
  24 compatibility.

## PTSDdiag 0.2.5

### Documentation

- Restructured vignettes into four focused articles: Quick Start, Full
  Internal Analysis, External Validation (PCL-5), and External
  Validation (CAPS-5).
- Updated pkgdown website configuration: fixed duplicate logo, added
  call-to-action buttons on the home page, added OpenGraph metadata for
  social sharing.
- Added changelog entries for versions 0.2.2–0.2.4.

## PTSDdiag 0.2.4

### New functions

- [`create_caps5_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_caps5_diagnosis.md)
  applies the DSM-5-TR diagnostic algorithm to CAPS-5
  (Clinician-Administered PTSD Scale for DSM-5) item scores and returns
  the clinician-rated diagnostic status.
- [`rename_caps5_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_caps5_columns.md)
  standardises CAPS-5 column names to `symptom_1` through `symptom_20`,
  enabling all downstream functions to work transparently on CAPS-5
  data.

### Improvements

- [`compare_diagnostic_systems()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
  gains a `caps5_data` argument for including CAPS-5 diagnoses in the
  unified comparison table, and a `reference` argument (`"pcl5"` or
  `"caps5"`) for selecting which instrument defines diagnostic “truth”.
  Labels are disambiguated automatically when both instruments are
  present (e.g. `"DSM-5-TR (PCL-5)"`, `"DSM-5-TR (CAPS-5)"`).

### Infrastructure

- Updated GitHub Actions workflows to Node.js 24 compatible versions.

## PTSDdiag 0.2.3

### New functions

- [`create_icd11_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md)
  applies ICD-11 PTSD diagnostic criteria to PCL-5 data and returns a
  comparison dataframe against DSM-5-TR. Output is directly compatible
  with
  [`summarize_ptsd_changes()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md).
- [`compare_diagnostic_systems()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
  produces a single unified summary table comparing the diagnostic
  performance of DSM-5-TR, ICD-11, and any number of optimised symptom
  combinations. Output is
  [`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html)-ready for
  manuscript tables.

## PTSDdiag 0.2.2

### Improvements

- [`create_readable_summary()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md)
  gains a `DT` parameter for optional interactive
  [`DT::datatable()`](https://rdrr.io/pkg/DT/man/datatable.html) widget
  output, consistent with the optimisation functions.
- [`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
  and
  [`optimize_combinations_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
  gain a `show_progress` parameter (default `TRUE`). Set to `FALSE` for
  batch or non-interactive use.

## PTSDdiag 0.2.1

### Improvements

- [`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md),
  [`optimize_combinations_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md),
  [`holdout_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/holdout_validation.md),
  and
  [`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md)
  now return plain data frames by default. Set `DT = TRUE` for
  interactive DT widgets (previous default behaviour).
- Combination identity (`combination_id` and `rank` columns) is now
  tracked through the full pipeline: optimization summaries,
  [`write_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md)
  /
  [`read_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
  JSON files, and cross-validation combination summaries.
- Progress reporting via the `cli` package: fold-level progress bars in
  [`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md)
  and informational messages in
  [`holdout_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/holdout_validation.md)
  and the optimization functions.
- [`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md)
  supports parallel fold processing via `future.apply` when available.
  Set up with `future::plan(future::multisession)` before calling.

### Deprecations

- [`analyze_best_six_symptoms_four_required()`](https://tobiasrspiller.github.io/PTSDdiag/reference/analyze_best_six_symptoms_four_required.md)
  and
  [`analyze_best_six_symptoms_four_required_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/analyze_best_six_symptoms_four_required_clusters.md)
  are soft-deprecated in

  favour of
  [`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
  and
  [`optimize_combinations_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md).

### Documentation

- Updated vignettes to use the generalized API
  ([`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
  and
  [`optimize_combinations_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md))
  instead of legacy wrappers.

## PTSDdiag 0.2.0

- New generalized optimization functions
  [`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
  and
  [`optimize_combinations_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
  that allow configurable number of symptoms per combination
  (`n_symptoms`), required threshold (`n_required`), number of top
  results (`n_top`), and custom cluster definitions (`clusters`).
- New
  [`apply_symptom_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
  function for external validation: apply pre-derived combinations to a
  new dataset and compare against DSM-5 baseline.
- New
  [`write_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md)
  and
  [`read_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
  functions for exporting and importing optimized symptom combinations
  as human-readable JSON files, enabling collaboration across research
  groups without sharing raw data.
- Original functions
  [`analyze_best_six_symptoms_four_required()`](https://tobiasrspiller.github.io/PTSDdiag/reference/analyze_best_six_symptoms_four_required.md)
  and
  [`analyze_best_six_symptoms_four_required_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/analyze_best_six_symptoms_four_required_clusters.md)
  are preserved as backward-compatible wrappers with PCL-5 defaults.
- [`holdout_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/holdout_validation.md)
  and
  [`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md)
  now accept `n_symptoms`, `n_required`, and `n_top` parameters.
- Internal refactoring: shared validation and diagnosis logic
  consolidated into reusable internal helpers.

## PTSDdiag 0.1.0

CRAN release: 2026-02-13

- Initial CRAN submission.
- Core analysis functions for identifying optimal 6-symptom PTSD
  diagnostic combinations using PCL-5 data.
- Hierarchical (cluster-based) and non-hierarchical analysis approaches.
- DSM-5 diagnostic criteria implementation (binarized and
  non-binarized).
- Diagnostic accuracy metrics: sensitivity, specificity, PPV, NPV.
- Holdout and k-fold cross-validation methods for model evaluation.
- Simulated PCL-5 dataset with 5,000 observations for demonstration.
