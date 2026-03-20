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
