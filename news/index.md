# Changelog

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
