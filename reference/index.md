# Package index

## Data Preparation

Functions for preparing and standardizing PCL-5 and CAPS-5 data

- [`rename_ptsd_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)
  : Rename PTSD symptom (= PCL-5 item) columns
- [`rename_caps5_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_caps5_columns.md)
  : Rename CAPS-5 symptom columns
- [`binarize_data()`](https://tobiasrspiller.github.io/PTSDdiag/reference/binarize_data.md)
  : Binarize PCL-5 symptom scores

## Diagnostic Scoring

Functions for calculating PTSD diagnoses and total scores

- [`calculate_ptsd_total()`](https://tobiasrspiller.github.io/PTSDdiag/reference/calculate_ptsd_total.md)
  : Calculate PTSD total score
- [`create_ptsd_diagnosis_binarized()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_ptsd_diagnosis_binarized.md)
  : Determine PTSD diagnosis based on DSM-5 criteria using binarized
  scores
- [`create_ptsd_diagnosis_nonbinarized()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_ptsd_diagnosis_nonbinarized.md)
  : Determine PTSD diagnosis based on DSM-5 criteria using non-binarized
  scores

## Analysis Functions

Functions for analyzing optimal symptom combinations

- [`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
  : Find optimal symptom combinations for diagnosis (non-hierarchical)
- [`optimize_combinations_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
  : Find optimal symptom combinations for diagnosis
  (hierarchical/cluster-based)
- [`apply_symptom_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
  : Apply pre-specified symptom combinations to new data
- [`analyze_best_six_symptoms_four_required()`](https://tobiasrspiller.github.io/PTSDdiag/reference/analyze_best_six_symptoms_four_required.md)
  : Find optimal non-hierarchical six-symptom combinations for PTSD
  diagnosis
- [`analyze_best_six_symptoms_four_required_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/analyze_best_six_symptoms_four_required_clusters.md)
  : Find optimal hierarchical six-symptom combinations for PTSD
  diagnosis

## Multi-Scenario Comparison

Compare multiple optimization scenarios in one call and visualise the
results

- [`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
  : Run multiple PTSD optimization scenarios in one call
- [`print(`*`<ptsdiag_comparison>`*`)`](https://tobiasrspiller.github.io/PTSDdiag/reference/print.ptsdiag_comparison.md)
  : Print method for ptsdiag_comparison objects
- [`summarize_top_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md)
  : Build a tidy comparison table of top combinations across scenarios
- [`symptom_frequency()`](https://tobiasrspiller.github.io/PTSDdiag/reference/symptom_frequency.md)
  : Per-symptom inclusion counts across optimization scenarios
- [`plot_symptom_frequency()`](https://tobiasrspiller.github.io/PTSDdiag/reference/plot_symptom_frequency.md)
  : Heatmap of PCL-5 symptom selection frequency across optimization
  scenarios

## Import/Export

Functions for sharing symptom combinations across research groups

- [`write_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md)
  : Write symptom combinations to a JSON file
- [`read_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
  : Read symptom combinations from a JSON file

## Summary and Reporting

Functions for creating summaries and comparing diagnostic approaches

- [`summarize_ptsd()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd.md)
  : Summarize PTSD scores and diagnoses
- [`summarize_ptsd_changes()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
  : Summarize changes in PTSD diagnostic metrics
- [`create_readable_summary()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md)
  : Create readable summary of PTSD diagnostic changes
- [`create_icd11_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md)
  : Apply ICD-11 PTSD diagnostic criteria to PCL-5 data
- [`create_caps5_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_caps5_diagnosis.md)
  : Compute CAPS-5 DSM-5-TR PTSD diagnosis
- [`compare_diagnostic_systems()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
  : Compare multiple diagnostic systems against a reference standard

## Validation

Model validation methods

- [`holdout_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/holdout_validation.md)
  : Perform holdout validation for PTSD diagnostic models
- [`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md)
  : Perform k-fold cross-validation for PTSD diagnostic models

## Datasets

Example and simulated datasets

- [`simulated_ptsd`](https://tobiasrspiller.github.io/PTSDdiag/reference/simulated_ptsd.md)
  : Simulated PCL-5 (PTSD Checklist) Data
- [`simulated_ptsd_genpop`](https://tobiasrspiller.github.io/PTSDdiag/reference/simulated_ptsd_genpop.md)
  : Simulated General Population PCL-5 Data
