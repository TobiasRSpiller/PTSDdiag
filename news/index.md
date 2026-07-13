# Changelog

## PTSDdiag 0.4.1

CRAN check-time reduction; no functional changes. The 0.4.0 submission
was auto-rejected by CRAN’s incoming pretests solely for exceeding the
10-minute check-time limit on r-devel-windows.

- Search-heavy tests (exhaustive 6-symptom optimizations, holdout- and
  cross-validation runs) are now skipped on CRAN via `skip_on_cran()`;
  the complete suite continues to run on GitHub Actions for every push.
  CRAN still exercises the optimizer, the summary tables, the plot, and
  the whole 0.4.0 evaluation API on compact search spaces and hand-built
  definitions.
- Vignettes compute on 120-row subsets (previously 250), the
  cross-validation demo uses 2 folds, and the external-validation
  example reuses the holdout-derived combinations instead of running a
  third full search. All narratives, code paths, and interpretive
  statements are unchanged and were re-verified against the re-rendered
  output.

## PTSDdiag 0.4.0

This release focuses on the multi-site validation workflow: everything a
collaborator site previously had to hand-code around the package is now
built in. It also corrects the ICD-11 operationalization to the
field-standard six-item mapping (see Corrections — ICD-11 results
change). Apart from that correction, no existing call changes behavior.

### Corrections

- **ICD-11 re-experiencing now uses PCL-5 items 2-3 (was 1-3).**
  [`create_icd11_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md)
  — and everything built on it: the `"icd11"` fixed criterion in
  [`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md),
  `include_icd11 = TRUE` in
  [`evaluate_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md),
  and the ICD-11 row of the symptom-frequency heatmap — now
  operationalizes ICD-11 PTSD with the narrow six-item mapping (items 2,
  3, 6, 7, 17, 18; at least one symptom per cluster). ICD-11 requires
  re-experiencing with a here-and-now quality, which nightmares (item 2)
  and flashbacks (item 3) capture but intrusive memories (item 1) as
  worded in the PCL-5 do not; this is the mapping used across the
  published PCL-5-to-ICD-11 literature (Kuester et al. 2017; Schellong
  et al. 2019; Heeke et al. 2020; Pettrich et al. 2025). **All ICD-11
  benchmark results change** relative to earlier versions; because the
  six-item rule is strictly more conservative, ICD-11 diagnoses can only
  become less frequent. The broad seven-item variant remains available
  as a custom fixed criterion — see the recipe in
  [`?create_icd11_diagnosis`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md).

### New features

- [`as_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/as_definitions.md)
  converts combinations imported from JSON into the definitions list
  [`evaluate_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md)
  expects, with optional top-`n` truncation and automatic rule labels
  such as `"4/6 Hierarchical"`.
  [`read_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
  output is now classed `ptsdiag_spec` and can be passed to
  [`evaluate_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md)
  directly (single spec or a list of specs — the conversion happens
  automatically).
  [`write_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md)
  gains an optional `label` argument stored in the file, so the
  derivation site controls how each rule is labelled downstream.
- [`evaluate_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md)
  gains `reference`: validate definitions against an external reference
  standard (e.g. a clinician CAPS diagnosis) supplied as a logical
  vector, a 0/1 column, or a column name. Rows with a missing reference
  are excluded with a message, and a `"Full 20-item PCL-5"` ceiling row
  is added by default (`include_full_pcl5`) so the cost of the reduced
  symptom set can be separated from the intrinsic PCL-5-vs-reference
  disagreement.
- [`evaluate_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md)
  gains `tidy` (and `as_percent`): return a plain analysis table with
  `Approach` / `Rank` / `Combination`, the 2x2 counts, and numeric
  metrics — the same layout as
  [`summarize_top_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md),
  so derivation and validation results can be combined with
  [`rbind()`](https://rdrr.io/r/base/cbind.html). No more parsing rule
  labels out of the formatted display table.
- [`score_all_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/score_all_combinations.md)
  scores **every** candidate combination (optionally
  cluster-constrained) against the DSM-5-TR diagnosis and returns the
  complete ranked table — the exhaustive companion to
  [`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md),
  for interchangeability (“plateau”) analyses. Chunked, with optional
  parallel scoring via `future.apply` like
  [`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md).
- [`check_pcl5_data()`](https://tobiasrspiller.github.io/PTSDdiag/reference/check_pcl5_data.md):
  exported pre-flight check that reports every data problem in one pass
  (column count, numeric type, integer 0-4 range, missing values)
  instead of one error at a time, plus an informational note on all-zero
  rows. Aimed at collaborator sites preparing data for
  [`rename_ptsd_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md).
- New `inst/CITATION`: `citation("PTSDdiag")` now points to the paper
  and the package.

### Bug fixes

- Hierarchical definitions that carry a custom cluster structure (stored
  in a combinations JSON file) are now evaluated with exactly those
  clusters; previously
  [`evaluate_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md)
  silently substituted the default PCL-5 B/C/D/E structure.

## PTSDdiag 0.3.5

### New features

- New `score_by = "balanced_accuracy"` optimization criterion: maximises
  balanced accuracy, the mean of sensitivity and specificity
  (equivalently, minimises FN/P + FP/N). Available in
  [`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md),
  [`optimize_combinations_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md),
  [`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md),
  [`holdout_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/holdout_validation.md),
  and
  [`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md),
  and accepted as metadata by
  [`write_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md).
- A `Balanced Accuracy` column ((sensitivity + specificity) / 2) is now
  reported by
  [`summarize_ptsd_changes()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
  (as `balanced_accuracy`),
  [`create_readable_summary()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md)
  (so `res$summary`, the holdout/cross-validation summaries, and
  [`evaluate_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md)
  show it),
  [`summarize_top_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md),
  [`compare_diagnostic_systems()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md),
  and the cross-validation `combinations_summary` (as
  `Balanced_Accuracy`). This makes the reported metric match the
  quantity the new default optimizes.

### Behavior changes

- All optimization and validation functions now default to
  `score_by = "balanced_accuracy"` (was `"accuracy"`). In imbalanced
  samples (the bundled clinical data is about 94% PTSD-positive) plain
  accuracy is dominated by the majority class; balanced accuracy weighs
  performance in the diagnosed and non-diagnosed groups equally. Pass
  `score_by = "accuracy"` to reproduce results from earlier versions.
- `score_by = "balanced_accuracy"` requires both diagnosed and
  non-diagnosed cases under the reference criterion; data where every
  case falls in one class now stops with an informative error suggesting
  `"accuracy"` or `"sensitivity"`.
- [`create_readable_summary()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md)
  now requires a `balanced_accuracy` column in its input. Data frames
  produced by
  [`summarize_ptsd_changes()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
  carry it automatically; hand-built inputs need the additional column.

### Documentation

- All vignettes demonstrate `score_by = "balanced_accuracy"` as the
  standard outcome, and the Getting started vignette explains the choice
  among the three criteria.
- Vignettes now run on a uniform 250-row subset of the bundled data, so
  building the package (and the CI checks) is several times faster. The
  Getting started vignette previously optimized on all 5,000 rows.
- Removed leftover editorial text from the Getting started vignette, and
  the PCL-5 total score is now computed on a descriptive copy so the
  optimizer’s “total column detected” warning no longer appears in the
  rendered vignette. Fixed typos across the comparison, validation, and
  multi-site vignettes.
- README article links point to the current vignettes (the previous
  links referenced articles removed in 0.3.1).
- Examples use the same uniform 250-row subset with compact search
  spaces so that CRAN’s `--run-donttest` checks stay fast.

### Internal

- Structural tests now run on compact search spaces and reuse expensive
  comparison objects, cutting the test-suite runtime from about five
  minutes to under a minute without losing coverage; the canonical
  6-of-4 searches are still exercised once per optimizer.

## PTSDdiag 0.3.3

### Bug fixes

- [`create_icd11_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md)
  now operationalises the ICD-11 “sense of current threat” cluster with
  PCL-5 items 17 (hypervigilance) and 18 (exaggerated startle), the
  symptoms the documentation always intended. Earlier versions used
  items 16 (risk-taking behaviour) and 17, so the ICD-11 benchmark
  diagnosis, the ICD-11 symptom set reported by
  [`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
  /
  [`symptom_frequency()`](https://tobiasrspiller.github.io/PTSDdiag/reference/symptom_frequency.md),
  and any comparison against ICD-11 are affected. Re-run analyses that
  benchmarked against ICD-11.

## PTSDdiag 0.3.2

### New features

- [`extract_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/extract_definitions.md)
  and
  [`evaluate_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md)
  are now exported.
  [`extract_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/extract_definitions.md)
  pulls the top-n combinations of each optimized scenario out of a
  [`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
  result (reading each rule from the object) as a portable, shareable
  object;
  [`evaluate_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md)
  applies such a set of mixed-rule definitions (plus ICD-11) to any
  sample and returns a performance table. Together they support
  multi-site workflows where only symptom-index definitions, not patient
  data, are shared.
- An `Accuracy` column ((TP + TN) / N) is now reported by
  [`create_readable_summary()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md)
  (so `res$summary`, the holdout/cross-validation summaries, and the
  multi-site tables show it),
  [`summarize_top_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md),
  and
  [`compare_diagnostic_systems()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md).
  This makes the reported metric match the quantity
  `score_by = "accuracy"` optimizes.

### Behavior changes

- [`holdout_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/holdout_validation.md)
  and
  [`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md)
  now default to `score_by = "accuracy"` (was `"sensitivity"`), matching
  [`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
  and
  [`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md).

### Data

- `simulated_ptsd_genpop` now also ships paired clinician-administered
  CAPS-5 ratings (`C1`–`C20`) for the same participants, simulated to
  correlate with the PCL-5 items at a total-score r of about 0.8. The
  dataset now has 43 columns (demographics + 20 PCL-5 + 20 CAPS-5); the
  PCL-5 items and demographics are unchanged.

### Documentation

- The CAPS-5 workflow vignette now uses the bundled paired data instead
  of random CAPS-5 ratings, so the instrument agreement it shows is
  realistic.

## PTSDdiag 0.3.1

### Breaking changes

- The `score_by` argument values have been renamed for clarity.
  Pre-0.3.1 values are no longer accepted; passing them errors with a
  migration hint.

  | Old value (≤ 0.3.0) | New value (0.3.1) | Meaning |
  |----|----|----|
  | `"false_cases"` | `"accuracy"` | minimise FP + FN (= maximise accuracy) |
  | `"newly_nondiagnosed"` | `"sensitivity"` | minimise FN (= maximise sensitivity) |

  Defaults updated accordingly:
  [`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md),
  [`optimize_combinations_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md),
  and
  [`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
  default to `"accuracy"`;
  [`holdout_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/holdout_validation.md)
  and
  [`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md)
  default to `"sensitivity"`.

### Bundled data

- `simulated_ptsd` and `simulated_ptsd_genpop` now ship with three
  demographic columns (`patient_id`, `age`, `sex`) so that the
  demographic carry-through workflow (`id_col`) can be demonstrated
  end-to-end on the bundled data. The numerical PCL-5 profile of both
  datasets is unchanged.

### Documentation

- The error message from
  [`rename_ptsd_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)
  /
  [`rename_caps5_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_caps5_columns.md)
  when the number of non-ID columns is not exactly 20 now spells out the
  strict positional behaviour and points users at `id_col` for unrelated
  covariates.
- Vignette restructure: the previous six vignettes have been
  consolidated into four with a shared template (clinical purpose +
  explicit input assumptions + epidemiological vocabulary +
  interpretation of every results table):
  - **Getting started** — single-cohort workflow + demographic join-back
    (replaces `quickstart` and folds in `id_column_workflow`).
  - **Comparing diagnostic criteria** — multi-scenario optimisation +
    ICD-11 + symptom-frequency heatmap (replaces `internal_analysis` and
    `multi_scenario_analysis`).
  - **Validating abbreviated symptom definitions** — internal and
    external validation (replaces validation sections of
    `internal_analysis` and `external_validation_pcl5`).
  - **Validating a shared definition across sites** — a multi-site
    workflow that derives a definition at one site and validates it at
    another by exchanging only a JSON symptom-index file, with no
    patient-level data shared.
  - **CAPS-5 workflow** — using CAPS-5 as the reference instrument
    (replaces `external_validation_caps5`).

## PTSDdiag 0.3.0

### New features

- [`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
  runs multiple symptom-optimization scenarios on the same dataset in a
  single call and returns a `ptsdiag_comparison` S3 object. Default
  scenarios reproduce the three approaches compared in the PTSDdiag
  preprint (4/6 hierarchical, 4/6 non-hierarchical, 3/6
  non-hierarchical). Users can supply their own named list of scenarios
  with arbitrary `n_symptoms` / `n_required` / `hierarchical`
  combinations.
- Fixed (non-optimised) criteria such as ICD-11 can be added to the same
  comparison either via the `include_icd11 = TRUE` convenience flag or
  via `scenarios` entries of `type = "fixed"`, including user-supplied
  logical diagnosis vectors. They appear as additional rows in the
  comparison table and as rows of 0/1 cells in the heatmap.
- [`summarize_top_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md)
  produces a tidy manuscript-ready table (Approach / Rank / Combination
  / TP / FN / FP / TN / Sensitivity / Specificity / PPV / NPV) from a
  `ptsdiag_comparison`. Optional `as_percent = TRUE` returns percentages
  for direct manuscript use.
- [`symptom_frequency()`](https://tobiasrspiller.github.io/PTSDdiag/reference/symptom_frequency.md)
  returns the long-format Symptom × Approach × Count / RelFreq dataframe
  (source of the preprint’s Supplementary Table S4), optionally
  appending an OVERALL pooled row.
- [`plot_symptom_frequency()`](https://tobiasrspiller.github.io/PTSDdiag/reference/plot_symptom_frequency.md)
  draws the symptom-selection heatmap (Figure 1 of the preprint) as a
  `ggplot` object, with the OVERALL row in its own facet for visual
  separation. `ggplot2` is now in Suggests.
- `id_col` carry-through (introduced in 0.2.7) propagates automatically
  through every scenario in
  [`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md).

### Documentation

- New vignette `multi-scenario-analysis` replicates the preprint’s
  end-to-end derivation workflow in roughly twenty lines of code.

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
