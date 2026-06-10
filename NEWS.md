# PTSDdiag 0.3.3

## Bug fixes

* `create_icd11_diagnosis()` now operationalises the ICD-11 "sense of current
  threat" cluster with PCL-5 items 17 (hypervigilance) and 18 (exaggerated
  startle), the symptoms the documentation always intended. Earlier versions
  used items 16 (risk-taking behaviour) and 17, so the ICD-11 benchmark
  diagnosis, the ICD-11 symptom set reported by `compare_optimizations()` /
  `symptom_frequency()`, and any comparison against ICD-11 are affected.
  Re-run analyses that benchmarked against ICD-11.

# PTSDdiag 0.3.2

## New features

* `extract_definitions()` and `evaluate_definitions()` are now exported.
  `extract_definitions()` pulls the top-n combinations of each optimized
  scenario out of a `compare_optimizations()` result (reading each rule from
  the object) as a portable, shareable object; `evaluate_definitions()`
  applies such a set of mixed-rule definitions (plus ICD-11) to any sample
  and returns a performance table. Together they support multi-site
  workflows where only symptom-index definitions, not patient data, are
  shared.
* An `Accuracy` column ((TP + TN) / N) is now reported by
  `create_readable_summary()` (so `res$summary`, the holdout/cross-validation
  summaries, and the multi-site tables show it), `summarize_top_combinations()`,
  and `compare_diagnostic_systems()`. This makes the reported metric match the
  quantity `score_by = "accuracy"` optimizes.

## Behavior changes

* `holdout_validation()` and `cross_validation()` now default to
  `score_by = "accuracy"` (was `"sensitivity"`), matching
  `optimize_combinations()` and `compare_optimizations()`.

## Data

* `simulated_ptsd_genpop` now also ships paired clinician-administered CAPS-5
  ratings (`C1`–`C20`) for the same participants, simulated to correlate with
  the PCL-5 items at a total-score r of about 0.8. The dataset now has 43
  columns (demographics + 20 PCL-5 + 20 CAPS-5); the PCL-5 items and
  demographics are unchanged.

## Documentation

* The CAPS-5 workflow vignette now uses the bundled paired data instead of
  random CAPS-5 ratings, so the instrument agreement it shows is realistic.

# PTSDdiag 0.3.1

## Breaking changes

* The `score_by` argument values have been renamed for clarity. Pre-0.3.1
  values are no longer accepted; passing them errors with a migration hint.

  | Old value (≤ 0.3.0) | New value (0.3.1) | Meaning |
  | --- | --- | --- |
  | `"false_cases"` | `"accuracy"` | minimise FP + FN (= maximise accuracy) |
  | `"newly_nondiagnosed"` | `"sensitivity"` | minimise FN (= maximise sensitivity) |

  Defaults updated accordingly: `optimize_combinations()`,
  `optimize_combinations_clusters()`, and `compare_optimizations()` default
  to `"accuracy"`; `holdout_validation()` and `cross_validation()` default
  to `"sensitivity"`.

## Bundled data

* `simulated_ptsd` and `simulated_ptsd_genpop` now ship with three
  demographic columns (`patient_id`, `age`, `sex`) so that the
  demographic carry-through workflow (`id_col`) can be demonstrated
  end-to-end on the bundled data. The numerical PCL-5 profile of both
  datasets is unchanged.

## Documentation

* The error message from `rename_ptsd_columns()` /
  `rename_caps5_columns()` when the number of non-ID columns is not
  exactly 20 now spells out the strict positional behaviour and points
  users at `id_col` for unrelated covariates.
* Vignette restructure: the previous six vignettes have been
  consolidated into four with a shared template (clinical purpose +
  explicit input assumptions + epidemiological vocabulary +
  interpretation of every results table):
  * **Getting started** — single-cohort workflow + demographic
    join-back (replaces `quickstart` and folds in `id_column_workflow`).
  * **Comparing diagnostic criteria** — multi-scenario optimisation +
    ICD-11 + symptom-frequency heatmap (replaces `internal_analysis`
    and `multi_scenario_analysis`).
  * **Validating abbreviated symptom definitions** — internal and
    external validation (replaces validation sections of
    `internal_analysis` and `external_validation_pcl5`).
  * **Validating a shared definition across sites** — a multi-site
    workflow that derives a definition at one site and validates it at
    another by exchanging only a JSON symptom-index file, with no
    patient-level data shared.
  * **CAPS-5 workflow** — using CAPS-5 as the reference instrument
    (replaces `external_validation_caps5`).

# PTSDdiag 0.3.0

## New features

* `compare_optimizations()` runs multiple symptom-optimization scenarios on
  the same dataset in a single call and returns a `ptsdiag_comparison` S3
  object. Default scenarios reproduce the three approaches compared in the
  PTSDdiag preprint (4/6 hierarchical, 4/6 non-hierarchical, 3/6
  non-hierarchical). Users can supply their own named list of scenarios with
  arbitrary `n_symptoms` / `n_required` / `hierarchical` combinations.
* Fixed (non-optimised) criteria such as ICD-11 can be added to the same
  comparison either via the `include_icd11 = TRUE` convenience flag or via
  `scenarios` entries of `type = "fixed"`, including user-supplied logical
  diagnosis vectors. They appear as additional rows in the comparison table
  and as rows of 0/1 cells in the heatmap.
* `summarize_top_combinations()` produces a tidy manuscript-ready table
  (Approach / Rank / Combination / TP / FN / FP / TN / Sensitivity /
  Specificity / PPV / NPV) from a `ptsdiag_comparison`. Optional
  `as_percent = TRUE` returns percentages for direct manuscript use.
* `symptom_frequency()` returns the long-format Symptom × Approach × Count /
  RelFreq dataframe (source of the preprint's Supplementary Table S4),
  optionally appending an OVERALL pooled row.
* `plot_symptom_frequency()` draws the symptom-selection heatmap (Figure 1
  of the preprint) as a `ggplot` object, with the OVERALL row in its own
  facet for visual separation. `ggplot2` is now in Suggests.
* `id_col` carry-through (introduced in 0.2.7) propagates automatically
  through every scenario in `compare_optimizations()`.

## Documentation

* New vignette `multi-scenario-analysis` replicates the preprint's
  end-to-end derivation workflow in roughly twenty lines of code.

# PTSDdiag 0.2.7

## New features

* `rename_ptsd_columns()` and `rename_caps5_columns()` gain an `id_col`
  argument: a character vector of column name(s) to preserve through the
  workflow as participant identifiers. When supplied, the named columns are
  prepended to the renamed dataframe and propagate automatically through
  `optimize_combinations()`, `optimize_combinations_clusters()`,
  `apply_symptom_combinations()`, `holdout_validation()`, `cross_validation()`,
  `create_icd11_diagnosis()`, and `create_caps5_diagnosis()`. The result of
  each per-row function (`diagnosis_comparison`, `test_results`,
  `fold_results`, etc.) prepends these ID columns so diagnoses can be joined
  back to the original dataframe — for example, to compare demographics
  between participants who do and do not meet an optimized criterion.
* `compare_diagnostic_systems()` automatically skips carry-through ID
  columns in its `...` inputs so they are not mistaken for diagnostic
  systems.

## Behavior changes

* `binarize_data()` now mutates only the `symptom_1`..`symptom_20` columns
  rather than the whole dataframe. Any additional columns (e.g. an ID
  column) are preserved unchanged. This fixes a latent bug where a
  non-numeric carry-through column would have been coerced or errored.
* `create_ptsd_diagnosis_binarized()` now operates on the symptom subset
  only, accepting input dataframes with extra columns.
* `summarize_ptsd_changes()` silently drops non-logical columns before
  computing metrics (previously errored). This lets ID columns ride along
  in comparison dataframes without breaking downstream summarization.

## Documentation

* New vignette `id-column-workflow` demonstrating how to use `id_col` to
  merge per-row diagnoses back to a dataframe with demographics.

# PTSDdiag 0.2.6

## Improvements

* All user-facing error messages now use the `cli` package for consistent,
  rich formatting: argument names are highlighted, actual values are shown,
  and hint bullets guide users toward fixes.
* Centralized input validation via `.validate_pcl5_data()` now accepts
  `strict_cols`, `warn_total`, and `instrument` parameters, reducing code
  duplication across exported functions.
* `holdout_validation()` and `cross_validation()` now correctly restore
  the global RNG state on exit (replaced buggy `withr::local_seed()` with
  manual `on.exit` save/restore).
* Removed `withr` from Imports (no longer used).

## Documentation

* Added `@note` to `simulated_ptsd` and `simulated_ptsd_genpop` dataset
  documentation clarifying that symptoms were simulated independently
  (no within-cluster correlations).

## Tests

* New tests for RNG state restoration, edge cases (all-positive/all-negative
  baselines, binarize boundary values), non-integer `k` rejection, empty
  split guard, and `n_tied` output from optimization functions.

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
