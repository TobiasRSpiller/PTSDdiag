# PTSDdiag 0.2.5.1

## Bug fixes

* Fixed stale `README.md` that still linked to the removed `introduction.html`
  vignette instead of the new `internal_analysis.html`.
* Restored package website link in README.
* Added pkgdown site URL to DESCRIPTION `URL` field.
* Updated `JamesIves/github-pages-deploy-action` to v4.7.3 for Node.js 24
  compatibility.

# PTSDdiag 0.2.5

## Documentation

* Restructured vignettes into four focused articles: Quick Start, Full Internal
  Analysis, External Validation (PCL-5), and External Validation (CAPS-5).
* Updated pkgdown website configuration: fixed duplicate logo, added
  call-to-action buttons on the home page, added OpenGraph metadata for social
  sharing.
* Added changelog entries for versions 0.2.2--0.2.4.

# PTSDdiag 0.2.4

## New functions

* `create_caps5_diagnosis()` applies the DSM-5-TR diagnostic algorithm to
  CAPS-5 (Clinician-Administered PTSD Scale for DSM-5) item scores and returns
  the clinician-rated diagnostic status.
* `rename_caps5_columns()` standardises CAPS-5 column names to `symptom_1`
  through `symptom_20`, enabling all downstream functions to work transparently
  on CAPS-5 data.

## Improvements

* `compare_diagnostic_systems()` gains a `caps5_data` argument for including
  CAPS-5 diagnoses in the unified comparison table, and a `reference` argument
  (`"pcl5"` or `"caps5"`) for selecting which instrument defines diagnostic
  "truth". Labels are disambiguated automatically when both instruments are
  present (e.g. `"DSM-5-TR (PCL-5)"`, `"DSM-5-TR (CAPS-5)"`).

## Infrastructure

* Updated GitHub Actions workflows to Node.js 24 compatible versions.

# PTSDdiag 0.2.3

## New functions

* `create_icd11_diagnosis()` applies ICD-11 PTSD diagnostic criteria to PCL-5
  data and returns a comparison dataframe against DSM-5-TR. Output is directly
  compatible with `summarize_ptsd_changes()`.
* `compare_diagnostic_systems()` produces a single unified summary table
  comparing the diagnostic performance of DSM-5-TR, ICD-11, and any number of
  optimised symptom combinations. Output is `knitr::kable()`-ready for
  manuscript tables.

# PTSDdiag 0.2.2

## Improvements

* `create_readable_summary()` gains a `DT` parameter for optional interactive
  `DT::datatable()` widget output, consistent with the optimisation functions.
* `optimize_combinations()` and `optimize_combinations_clusters()` gain a
  `show_progress` parameter (default `TRUE`). Set to `FALSE` for batch or
  non-interactive use.

# PTSDdiag 0.2.1

## Improvements

* `optimize_combinations()`, `optimize_combinations_clusters()`,
  `holdout_validation()`, and `cross_validation()` now return plain data frames
  by default. Set `DT = TRUE` for interactive DT widgets (previous default
  behaviour).
* Combination identity (`combination_id` and `rank` columns) is now tracked
  through the full pipeline: optimization summaries, `write_combinations()` /
  `read_combinations()` JSON files, and cross-validation combination summaries.
* Progress reporting via the `cli` package: fold-level progress bars in
  `cross_validation()` and informational messages in `holdout_validation()` and
  the optimization functions.
* `cross_validation()` supports parallel fold processing via `future.apply` when
  available. Set up with `future::plan(future::multisession)` before calling.

## Deprecations

* `analyze_best_six_symptoms_four_required()` and
  `analyze_best_six_symptoms_four_required_clusters()` are soft-deprecated in

  favour of `optimize_combinations()` and `optimize_combinations_clusters()`.

## Documentation

* Updated vignettes to use the generalized API (`optimize_combinations()` and
  `optimize_combinations_clusters()`) instead of legacy wrappers.

# PTSDdiag 0.2.0

* New generalized optimization functions `optimize_combinations()` and
  `optimize_combinations_clusters()` that allow configurable number of symptoms
  per combination (`n_symptoms`), required threshold (`n_required`), number of
  top results (`n_top`), and custom cluster definitions (`clusters`).
* New `apply_symptom_combinations()` function for external validation: apply
  pre-derived combinations to a new dataset and compare against DSM-5 baseline.
* New `write_combinations()` and `read_combinations()` functions for exporting
  and importing optimized symptom combinations as human-readable JSON files,
  enabling collaboration across research groups without sharing raw data.
* Original functions `analyze_best_six_symptoms_four_required()` and
  `analyze_best_six_symptoms_four_required_clusters()` are preserved as
  backward-compatible wrappers with PCL-5 defaults.
* `holdout_validation()` and `cross_validation()` now accept `n_symptoms`,
  `n_required`, and `n_top` parameters.
* Internal refactoring: shared validation and diagnosis logic consolidated into
  reusable internal helpers.

# PTSDdiag 0.1.0

* Initial CRAN submission.
* Core analysis functions for identifying optimal 6-symptom PTSD diagnostic
  combinations using PCL-5 data.
* Hierarchical (cluster-based) and non-hierarchical analysis approaches.
* DSM-5 diagnostic criteria implementation (binarized and non-binarized).
* Diagnostic accuracy metrics: sensitivity, specificity, PPV, NPV.
* Holdout and k-fold cross-validation methods for model evaluation.
* Simulated PCL-5 dataset with 5,000 observations for demonstration.
