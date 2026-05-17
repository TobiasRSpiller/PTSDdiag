# Full Internal Analysis

## 1. Introduction

The `PTSDdiag` package provides tools for analysing and optimising PTSD
diagnostic criteria using PCL-5 (PTSD Checklist for DSM-5) data. This
vignette demonstrates a complete single-dataset workflow:

- Import and prepare PCL-5 data
- Calculate descriptive statistics and reliability metrics
- Identify optimal symptom combinations (hierarchical and
  non-hierarchical)
- Apply ICD-11 PTSD diagnostic criteria and compare diagnostic systems
- Export and import optimised combinations
- Validate models using holdout and cross-validation

For workflows involving independent validation datasets, see the
[External Validation
(PCL-5)](https://tobiasrspiller.github.io/PTSDdiag/articles/external_validation_pcl5.md)
and [External Validation
(CAPS-5)](https://tobiasrspiller.github.io/PTSDdiag/articles/external_validation_caps5.md)
vignettes.

## 2. Setup

### 2.1. Installation

Install the released version from CRAN:

``` r

install.packages("PTSDdiag")
```

Or the development version from GitHub:

``` r

# install.packages("devtools")
devtools::install_github("TobiasRSpiller/PTSDdiag")
```

### 2.2. Loading packages

``` r

library("PTSDdiag")
```

``` r

library(psych)     # For reliability analysis
```

## 3. Data preparation

### 3.1. Loading the sample data

The package includes `simulated_ptsd`, a dataset of 5,000 simulated
PCL-5 records. Each record rates 20 PTSD symptoms on a 5-point scale (0
= Not at all, 1 = A little bit, 2 = Moderately, 3 = Quite a bit, 4 =
Extremely).

The PCL-5 organises symptoms into four DSM-5 clusters:

- Symptoms 1–5: Criterion B (Intrusion)
- Symptoms 6–7: Criterion C (Avoidance)
- Symptoms 8–14: Criterion D (Negative alterations in cognitions and
  mood)
- Symptoms 15–20: Criterion E (Alterations in arousal and reactivity)

Input data must contain numeric values 0–4 only, with no missing values,
20 columns (one per symptom), and row-wise observations.

``` r

data("simulated_ptsd")
head(simulated_ptsd)
#>   S1 S2 S3 S4 S5 S6 S7 S8 S9 S10 S11 S12 S13 S14 S15 S16 S17 S18 S19 S20
#> 1  2  1  4  1  4  3  3  3  4   4   4   4   4   4   4   4   3   3   4   3
#> 2  3  3  4  3  3  2  3  3  3   3   4   2   4   4   3   4   3   3   3   4
#> 3  0  1  1  2  2  2  3  0  3   2   3   3   2   1   3   1   2   2   1   3
#> 4  3  3  3  3  3  3  4  1  4   4   2   3   4   2   2   2   4   3   3   3
#> 5  2  3  3  2  3  1  2  1  4   3   2   3   3   4   3   3   4   4   3   3
#> 6  1  1  2  1  2  2  1  0  2   1   2   3   3   3   1   2   1   0   3   3
```

### 3.2. Standardising column names

All package functions expect columns named `symptom_1` through
`symptom_20`. Use
[`rename_ptsd_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)
to standardise:

``` r

simulated_ptsd_renamed <- rename_ptsd_columns(simulated_ptsd)
names(simulated_ptsd_renamed)
#>  [1] "symptom_1"  "symptom_2"  "symptom_3"  "symptom_4"  "symptom_5" 
#>  [6] "symptom_6"  "symptom_7"  "symptom_8"  "symptom_9"  "symptom_10"
#> [11] "symptom_11" "symptom_12" "symptom_13" "symptom_14" "symptom_15"
#> [16] "symptom_16" "symptom_17" "symptom_18" "symptom_19" "symptom_20"
```

### 3.3. Descriptive statistics

We calculate total scores, apply DSM-5 diagnostic criteria, and
summarise:

``` r

# Calculate total scores (range 0-80)
simulated_ptsd_total <- calculate_ptsd_total(simulated_ptsd_renamed)

# Apply DSM-5 diagnostic criteria
simulated_ptsd_total_diagnosed <- create_ptsd_diagnosis_nonbinarized(simulated_ptsd_total)

# Summary statistics
summarize_ptsd(simulated_ptsd_total_diagnosed)
#>   mean_total sd_total n_diagnosed
#> 1     57.772 12.36218        4710
```

### 3.4. Reliability analysis

Cronbach’s alpha assesses the internal consistency of the PCL-5 items:

``` r

cronbach <- psych::alpha(subset(simulated_ptsd_total_diagnosed, select = -total))
round(cronbach$total, 3)
#>  raw_alpha std.alpha G6(smc) average_r    S/N   ase  mean    sd median_r
#>      0.913     0.916   0.921     0.341 10.851 0.002 2.796 0.594    0.332
```

## 4. Identifying optimal symptom combinations

Standard PTSD diagnosis requires evaluating 20 symptoms across four
clusters. The goal is to identify reduced symptom combinations that
preserve the polythetic structure of the diagnosis while maintaining
diagnostic accuracy.

We examine two structural approaches: a **hierarchical** approach
(requiring at least one symptom from each DSM-5 cluster) and a
**non-hierarchical** approach (selecting symptoms purely by accuracy).

> **Note on computation time.** The examples below use 4-symptom
> combinations (C(20, 4) = 4,845 to evaluate), which run in seconds. A
> typical analysis uses 6-symptom combinations (C(20, 6) = 38,760),
> which takes 1–2 minutes with 5,000 observations.

### 4.1. Hierarchical analysis

The hierarchical approach requires at least one symptom from each DSM-5
cluster, maintaining the structural logic of the diagnostic criteria.

The `score_by` argument controls the optimisation target:

- `"newly_nondiagnosed"` – minimise false negatives (missed diagnoses)
- `"false_cases"` – minimise total misclassifications

``` r

best_combinations_hierarchical <- optimize_combinations_clusters(
  simulated_ptsd_renamed,
  n_symptoms = 4,
  n_required = 3,
  n_top      = 3,
  score_by   = "newly_nondiagnosed",
  clusters   = list(B = 1:5, C = 6:7, D = 8:14, E = 15:20),
  show_progress = FALSE
)
```

The function returns three elements. **1. The best symptom
combinations:**

``` r

best_combinations_hierarchical$best_symptoms
#> [[1]]
#> [1]  1  7 11 17
#> 
#> [[2]]
#> [1]  4  6 11 17
#> 
#> [[3]]
#> [1]  1  6 11 17
```

**2. A row-level comparison of DSM-5-TR vs. each combination** (first 5
rows):

``` r

knitr::kable(
  head(best_combinations_hierarchical$diagnosis_comparison, 5),
  caption = "Diagnosis comparison: DSM-5-TR vs. top hierarchical combinations (first 5 rows)"
)
```

| PTSD_orig | symptom_1_7_11_17 | symptom_4_6_11_17 | symptom_1_6_11_17 |
|:----------|:------------------|:------------------|:------------------|
| TRUE      | TRUE              | FALSE             | TRUE              |
| TRUE      | TRUE              | TRUE              | TRUE              |
| TRUE      | FALSE             | TRUE              | FALSE             |
| TRUE      | TRUE              | TRUE              | TRUE              |
| TRUE      | TRUE              | FALSE             | FALSE             |

Diagnosis comparison: DSM-5-TR vs. top hierarchical combinations (first
5 rows) {.table}

**3. Diagnostic accuracy metrics:**

``` r

knitr::kable(
  best_combinations_hierarchical$summary,
  digits  = 4,
  caption = "Hierarchical combinations: diagnostic accuracy metrics"
)
```

| Scenario | combination_id | rank | Total Diagnosed | Total Non-Diagnosed | True Positive | True Negative | Newly Diagnosed | Newly Non-Diagnosed | True Cases | False Cases | Sensitivity | Specificity | PPV | NPV |
|:---|:---|---:|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PTSD_orig | NA | NA | 4710 (94.2%) | 290 (5.8%) | 4710 | 290 | 0 | 0 | 5000 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| symptom_1_7_11_17 | 1_7_11_17 | 1 | 3755 (75.1%) | 1245 (24.9%) | 3753 | 288 | 2 | 957 | 4041 | 959 | 0.7968 | 0.9931 | 0.9995 | 0.2313 |
| symptom_4_6_11_17 | 4_6_11_17 | 2 | 3754 (75.08%) | 1246 (24.92%) | 3750 | 286 | 4 | 960 | 4036 | 964 | 0.7962 | 0.9862 | 0.9989 | 0.2295 |
| symptom_1_6_11_17 | 1_6_11_17 | 3 | 3752 (75.04%) | 1248 (24.96%) | 3749 | 287 | 3 | 961 | 4036 | 964 | 0.7960 | 0.9897 | 0.9992 | 0.2300 |

Hierarchical combinations: diagnostic accuracy metrics {.table}

### 4.2. Non-hierarchical analysis

The non-hierarchical approach selects symptoms purely by accuracy,
without requiring cluster representation.

``` r

best_combinations_nonhierarchical <- optimize_combinations(
  simulated_ptsd_renamed,
  n_symptoms = 4,
  n_required = 3,
  n_top      = 3,
  score_by   = "newly_nondiagnosed",
  show_progress = FALSE
)
```

**Best symptom combinations:**

``` r

best_combinations_nonhierarchical$best_symptoms
#> [[1]]
#> [1]  1  6  7 13
#> 
#> [[2]]
#> [1]  4  6  7 13
#> 
#> [[3]]
#> [1]  4  6  7 17
```

**Diagnosis comparison** (first 5 rows):

``` r

knitr::kable(
  head(best_combinations_nonhierarchical$diagnosis_comparison, 5),
  caption = "Diagnosis comparison: DSM-5-TR vs. top non-hierarchical combinations (first 5 rows)"
)
```

| PTSD_orig | symptom_1_6_7_13 | symptom_4_6_7_13 | symptom_4_6_7_17 |
|:----------|:-----------------|:-----------------|:-----------------|
| TRUE      | TRUE             | TRUE             | TRUE             |
| TRUE      | TRUE             | TRUE             | TRUE             |
| TRUE      | TRUE             | TRUE             | TRUE             |
| TRUE      | TRUE             | TRUE             | TRUE             |
| TRUE      | TRUE             | TRUE             | TRUE             |

Diagnosis comparison: DSM-5-TR vs. top non-hierarchical combinations
(first 5 rows) {.table}

**Diagnostic accuracy metrics:**

``` r

knitr::kable(
  best_combinations_nonhierarchical$summary,
  digits  = 4,
  caption = "Non-hierarchical combinations: diagnostic accuracy metrics"
)
```

| Scenario | combination_id | rank | Total Diagnosed | Total Non-Diagnosed | True Positive | True Negative | Newly Diagnosed | Newly Non-Diagnosed | True Cases | False Cases | Sensitivity | Specificity | PPV | NPV |
|:---|:---|---:|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PTSD_orig | NA | NA | 4710 (94.2%) | 290 (5.8%) | 4710 | 290 | 0 | 0 | 5000 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| symptom_1_6_7_13 | 1_6_7_13 | 1 | 4573 (91.46%) | 427 (8.54%) | 4535 | 252 | 38 | 175 | 4787 | 213 | 0.9628 | 0.8690 | 0.9917 | 0.5902 |
| symptom_4_6_7_13 | 4_6_7_13 | 2 | 4574 (91.48%) | 426 (8.52%) | 4535 | 251 | 39 | 175 | 4786 | 214 | 0.9628 | 0.8655 | 0.9915 | 0.5892 |
| symptom_4_6_7_17 | 4_6_7_17 | 3 | 4568 (91.36%) | 432 (8.64%) | 4528 | 250 | 40 | 182 | 4778 | 222 | 0.9614 | 0.8621 | 0.9912 | 0.5787 |

Non-hierarchical combinations: diagnostic accuracy metrics {.table
style="width:100%;"}

## 5. Comparing diagnostic systems

Optimised combinations can be benchmarked against established reference
standards: the full DSM-5-TR criteria and the ICD-11 PTSD definition.

### 5.1. ICD-11 PTSD criteria

The ICD-11 defines PTSD using a narrower symptom set than DSM-5-TR.
Using PCL-5 items, the ICD-11 requires **all three** of the following
clusters to be met (symptom present = score \>= 2):

| ICD-11 Cluster | Requirement | PCL-5 Items |
|----|----|----|
| Re-experiencing (in the present) | \>= 1 of items 1, 2, 3 | Intrusive memories, nightmares, flashbacks |
| Avoidance | \>= 1 of items 6, 7 | Avoidance of thoughts, avoidance of reminders |
| Sense of current threat | \>= 1 of items 16, 17 | Hypervigilance, exaggerated startle |

[`create_icd11_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md)
applies these criteria:

``` r

icd11_result <- create_icd11_diagnosis(simulated_ptsd_renamed)
head(icd11_result)
#>   PTSD_orig PTSD_icd11
#> 1      TRUE       TRUE
#> 2      TRUE       TRUE
#> 3      TRUE      FALSE
#> 4      TRUE       TRUE
#> 5      TRUE       TRUE
#> 6      TRUE       TRUE
```

``` r

cat(sprintf("DSM-5-TR prevalence: %.1f%%\n", mean(icd11_result$PTSD_orig)  * 100))
#> DSM-5-TR prevalence: 94.2%
cat(sprintf("ICD-11 prevalence:   %.1f%%\n", mean(icd11_result$PTSD_icd11) * 100))
#> ICD-11 prevalence:   92.8%
```

Diagnostic accuracy of ICD-11 relative to DSM-5-TR:

``` r

knitr::kable(
  create_readable_summary(summarize_ptsd_changes(icd11_result)),
  digits  = 4,
  caption = "ICD-11 vs. DSM-5-TR: diagnostic accuracy metrics"
)
```

| Scenario | Total Diagnosed | Total Non-Diagnosed | True Positive | True Negative | Newly Diagnosed | Newly Non-Diagnosed | True Cases | False Cases | Sensitivity | Specificity | PPV | NPV |
|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PTSD_orig | 4710 (94.2%) | 290 (5.8%) | 4710 | 290 | 0 | 0 | 5000 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| PTSD_icd11 | 4641 (92.82%) | 359 (7.18%) | 4607 | 256 | 34 | 103 | 4863 | 137 | 0.9781 | 0.8828 | 0.9927 | 0.7131 |

ICD-11 vs. DSM-5-TR: diagnostic accuracy metrics {.table}

### 5.2. Unified comparison table

[`compare_diagnostic_systems()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
combines any number of diagnostic criteria into a single table. Here we
compare DSM-5-TR, ICD-11, and both sets of optimised combinations:

``` r

tbl_full <- compare_diagnostic_systems(
  simulated_ptsd_renamed,
  best_combinations_nonhierarchical$diagnosis_comparison,
  best_combinations_hierarchical$diagnosis_comparison,
  icd11 = TRUE
)

knitr::kable(
  tbl_full,
  digits  = 4,
  caption = "Comparison: DSM-5-TR, ICD-11, non-hierarchical, and hierarchical combinations"
)
```

| system | n_diagnosed | pct_diagnosed | sensitivity | specificity | ppv | npv | n_false_negative | pct_false_negative | n_false_positive | pct_false_positive | n_misclassified |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| DSM-5-TR | 4710 | 94.20 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0.00 | 0 | 0.00 | 0 |
| ICD-11 | 4641 | 92.82 | 0.9781 | 0.8828 | 0.9927 | 0.7131 | 103 | 2.06 | 34 | 0.68 | 137 |
| symptom_1_6_7_13 | 4573 | 91.46 | 0.9628 | 0.8690 | 0.9917 | 0.5902 | 175 | 3.50 | 38 | 0.76 | 213 |
| symptom_4_6_7_13 | 4574 | 91.48 | 0.9628 | 0.8655 | 0.9915 | 0.5892 | 175 | 3.50 | 39 | 0.78 | 214 |
| symptom_4_6_7_17 | 4568 | 91.36 | 0.9614 | 0.8621 | 0.9912 | 0.5787 | 182 | 3.64 | 40 | 0.80 | 222 |
| symptom_1_7_11_17 | 3755 | 75.10 | 0.7968 | 0.9931 | 0.9995 | 0.2313 | 957 | 19.14 | 2 | 0.04 | 959 |
| symptom_4_6_11_17 | 3754 | 75.08 | 0.7962 | 0.9862 | 0.9989 | 0.2295 | 960 | 19.20 | 4 | 0.08 | 964 |
| symptom_1_6_11_17 | 3752 | 75.04 | 0.7960 | 0.9897 | 0.9992 | 0.2300 | 961 | 19.22 | 3 | 0.06 | 964 |

Comparison: DSM-5-TR, ICD-11, non-hierarchical, and hierarchical
combinations {.table}

Use the `labels` argument to rename the optimised combination rows (by
default, column names such as `symptom_1_6_8_15` are used). Set
`icd11 = FALSE` to omit the ICD-11 row.

## 6. Exporting and importing combinations

[`write_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md)
and
[`read_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
export and import optimised combinations as human-readable JSON files,
enabling sharing across research groups.

### 6.1. Saving derived combinations

``` r

tmp_hier    <- tempfile(fileext = ".json")
tmp_nonhier <- tempfile(fileext = ".json")

write_combinations(
  best_combinations_hierarchical$best_symptoms,
  file        = tmp_hier,
  n_required  = 3,
  clusters    = list(B = 1:5, C = 6:7, D = 8:14, E = 15:20),
  score_by    = "newly_nondiagnosed",
  description = "Top 3 hierarchical combinations from simulated data"
)

write_combinations(
  best_combinations_nonhierarchical$best_symptoms,
  file       = tmp_nonhier,
  n_required = 3,
  score_by   = "newly_nondiagnosed",
  description = "Top 3 non-hierarchical combinations from simulated data"
)

cat("Files written successfully.\n")
#> Files written successfully.
```

### 6.2. Loading saved combinations

A collaborator can load the combinations and apply them to new data:

``` r

spec <- read_combinations(tmp_hier)

cat("Combinations loaded: ", length(spec$combinations), "\n")
#> Combinations loaded:  3
cat("n_required:          ", spec$n_required, "\n")
#> n_required:           3
cat("Clusters:            ", paste(names(spec$clusters), collapse = ", "), "\n")
#> Clusters:             B, C, D, E
cat("Description:         ", spec$description, "\n")
#> Description:          Top 3 hierarchical combinations from simulated data
```

``` r

comparison_loaded <- apply_symptom_combinations(
  simulated_ptsd_renamed,
  combinations = spec$combinations,
  n_required   = spec$n_required,
  clusters     = spec$clusters
)

knitr::kable(
  create_readable_summary(summarize_ptsd_changes(comparison_loaded)),
  digits  = 4,
  caption = "Performance of re-loaded hierarchical combinations"
)
```

| Scenario | Total Diagnosed | Total Non-Diagnosed | True Positive | True Negative | Newly Diagnosed | Newly Non-Diagnosed | True Cases | False Cases | Sensitivity | Specificity | PPV | NPV |
|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PTSD_orig | 4710 (94.2%) | 290 (5.8%) | 4710 | 290 | 0 | 0 | 5000 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| symptom_1_7_11_17 | 3755 (75.1%) | 1245 (24.9%) | 3753 | 288 | 2 | 957 | 4041 | 959 | 0.7968 | 0.9931 | 0.9995 | 0.2313 |
| symptom_4_6_11_17 | 3754 (75.08%) | 1246 (24.92%) | 3750 | 286 | 4 | 960 | 4036 | 964 | 0.7962 | 0.9862 | 0.9989 | 0.2295 |
| symptom_1_6_11_17 | 3752 (75.04%) | 1248 (24.96%) | 3749 | 287 | 3 | 961 | 4036 | 964 | 0.7960 | 0.9897 | 0.9992 | 0.2300 |

Performance of re-loaded hierarchical combinations {.table
style="width:100%;"}

For a complete derivation-validation workflow across independent
datasets, see the [External Validation
(PCL-5)](https://tobiasrspiller.github.io/PTSDdiag/articles/external_validation_pcl5.md)
vignette.

## 7. Model validation

The package provides two complementary approaches for estimating how
well optimised combinations generalise to new data.

> **Note on computation time.** The examples below use `n_symptoms = 4`
> to keep build time short. Real-world analyses typically use
> `n_symptoms = 6`.

### 7.1. Holdout validation

Holdout validation splits the data into training (70%) and test (30%)
sets. Optimal combinations are derived on the training set and evaluated
on the held-out test set.

``` r

validation_results <- holdout_validation(
  simulated_ptsd_renamed,
  train_ratio = 0.7,
  score_by    = "newly_nondiagnosed",
  seed        = 123,
  n_symptoms  = 4,
  n_required  = 3,
  n_top       = 3
)
```

**Best combinations identified on training data:**

``` r

cat("Non-hierarchical:\n")
#> Non-hierarchical:
print(validation_results$without_clusters$best_combinations)
#> [[1]]
#> [1]  4  6  7 13
#> 
#> [[2]]
#> [1]  1  6  7 13
#> 
#> [[3]]
#> [1]  4  6  7 17
cat("\nHierarchical:\n")
#> 
#> Hierarchical:
print(validation_results$with_clusters$best_combinations)
#> [[1]]
#> [1]  4  6 11 17
#> 
#> [[2]]
#> [1]  1  6 11 17
#> 
#> [[3]]
#> [1]  5  6 11 17
```

**Test-set performance:**

``` r

knitr::kable(
  validation_results$without_clusters$summary,
  digits  = 4,
  caption = "Holdout validation: non-hierarchical combinations (test set)"
)
```

| Scenario | combination_id | rank | Total Diagnosed | Total Non-Diagnosed | True Positive | True Negative | Newly Diagnosed | Newly Non-Diagnosed | True Cases | False Cases | Sensitivity | Specificity | PPV | NPV |
|:---|:---|---:|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PTSD_orig | NA | NA | 1419 (94.6%) | 81 (5.4%) | 1419 | 81 | 0 | 0 | 1500 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| symptom_4_6_7_13 | 4_6_7_13 | 1 | 1378 (91.87%) | 122 (8.13%) | 1366 | 69 | 12 | 53 | 1435 | 65 | 0.9626 | 0.8519 | 0.9913 | 0.5656 |
| symptom_1_6_7_13 | 1_6_7_13 | 2 | 1385 (92.33%) | 115 (7.67%) | 1374 | 70 | 11 | 45 | 1444 | 56 | 0.9683 | 0.8642 | 0.9921 | 0.6087 |
| symptom_4_6_7_17 | 4_6_7_17 | 3 | 1379 (91.93%) | 121 (8.07%) | 1368 | 70 | 11 | 51 | 1438 | 62 | 0.9641 | 0.8642 | 0.9920 | 0.5785 |

Holdout validation: non-hierarchical combinations (test set) {.table
style="width:100%;"}

``` r

knitr::kable(
  validation_results$with_clusters$summary,
  digits  = 4,
  caption = "Holdout validation: hierarchical combinations (test set)"
)
```

| Scenario | combination_id | rank | Total Diagnosed | Total Non-Diagnosed | True Positive | True Negative | Newly Diagnosed | Newly Non-Diagnosed | True Cases | False Cases | Sensitivity | Specificity | PPV | NPV |
|:---|:---|---:|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PTSD_orig | NA | NA | 1419 (94.6%) | 81 (5.4%) | 1419 | 81 | 0 | 0 | 1500 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| symptom_4_6_11_17 | 4_6_11_17 | 1 | 1145 (76.33%) | 355 (23.67%) | 1144 | 80 | 1 | 275 | 1224 | 276 | 0.8062 | 0.9877 | 0.9991 | 0.2254 |
| symptom_1_6_11_17 | 1_6_11_17 | 2 | 1150 (76.67%) | 350 (23.33%) | 1149 | 80 | 1 | 270 | 1229 | 271 | 0.8097 | 0.9877 | 0.9991 | 0.2286 |
| symptom_5_6_11_17 | 5_6_11_17 | 3 | 1138 (75.87%) | 362 (24.13%) | 1137 | 80 | 1 | 282 | 1217 | 283 | 0.8013 | 0.9877 | 0.9991 | 0.2210 |

Holdout validation: hierarchical combinations (test set) {.table}

### 7.2. Cross-validation

k-fold cross-validation provides a more robust estimate of
generalisation by repeating the train/test split `k` times.

``` r

cv_results <- cross_validation(
  simulated_ptsd_renamed,
  k          = 3,
  score_by   = "newly_nondiagnosed",
  seed       = 123,
  n_symptoms = 4,
  n_required = 3,
  n_top      = 3
)
```

**Results by fold – non-hierarchical:**

``` r

knitr::kable(
  cv_results$without_clusters$summary_by_fold,
  digits  = 4,
  caption = "Cross-validation: non-hierarchical results by fold"
)
```

| Split | Scenario | Total Diagnosed | Total Non-Diagnosed | True Positive | True Negative | Newly Diagnosed | Newly Non-Diagnosed | True Cases | False Cases | Sensitivity | Specificity | PPV | NPV | combination_id | rank |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:---|---:|
| Split 1 | PTSD_orig | 1565 (93.88%) | 102 (6.12%) | 1565 | 102 | 0 | 0 | 1667 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 1 | symptom_1_6_7_19 | 1502 (90.1%) | 165 (9.9%) | 1497 | 97 | 5 | 68 | 1594 | 73 | 0.9565 | 0.9510 | 0.9967 | 0.5879 | 1_6_7_19 | 1 |
| Split 1 | symptom_1_6_7_13 | 1519 (91.12%) | 148 (8.88%) | 1512 | 95 | 7 | 53 | 1607 | 60 | 0.9661 | 0.9314 | 0.9954 | 0.6419 | 1_6_7_13 | 2 |
| Split 1 | symptom_6_7_13_19 | 1500 (89.98%) | 167 (10.02%) | 1496 | 98 | 4 | 69 | 1594 | 73 | 0.9559 | 0.9608 | 0.9973 | 0.5868 | 6_7_13_19 | 3 |
| Split 2 | PTSD_orig | 1568 (94.06%) | 99 (5.94%) | 1568 | 99 | 0 | 0 | 1667 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 2 | symptom_1_6_7_13 | 1520 (91.18%) | 147 (8.82%) | 1503 | 82 | 17 | 65 | 1585 | 82 | 0.9585 | 0.8283 | 0.9888 | 0.5578 | 1_6_7_13 | 1 |
| Split 2 | symptom_4_6_7_13 | 1526 (91.54%) | 141 (8.46%) | 1509 | 82 | 17 | 59 | 1591 | 76 | 0.9624 | 0.8283 | 0.9889 | 0.5816 | 4_6_7_13 | 2 |
| Split 2 | symptom_1_6_7_18 | 1515 (90.88%) | 152 (9.12%) | 1497 | 81 | 18 | 71 | 1578 | 89 | 0.9547 | 0.8182 | 0.9881 | 0.5329 | 1_6_7_18 | 3 |
| Split 3 | PTSD_orig | 1577 (94.66%) | 89 (5.34%) | 1577 | 89 | 0 | 0 | 1666 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 3 | symptom_4_6_7_13 | 1525 (91.54%) | 141 (8.46%) | 1510 | 74 | 15 | 67 | 1584 | 82 | 0.9575 | 0.8315 | 0.9902 | 0.5248 | 4_6_7_13 | 1 |
| Split 3 | symptom_4_6_7_20 | 1511 (90.7%) | 155 (9.3%) | 1496 | 74 | 15 | 81 | 1570 | 96 | 0.9486 | 0.8315 | 0.9901 | 0.4774 | 4_6_7_20 | 2 |
| Split 3 | symptom_6_7_17_20 | 1521 (91.3%) | 145 (8.7%) | 1506 | 74 | 15 | 71 | 1580 | 86 | 0.9550 | 0.8315 | 0.9901 | 0.5103 | 6_7_17_20 | 3 |

Cross-validation: non-hierarchical results by fold {.table}

**Results by fold – hierarchical:**

``` r

knitr::kable(
  cv_results$with_clusters$summary_by_fold,
  digits  = 4,
  caption = "Cross-validation: hierarchical results by fold"
)
```

| Split | Scenario | Total Diagnosed | Total Non-Diagnosed | True Positive | True Negative | Newly Diagnosed | Newly Non-Diagnosed | True Cases | False Cases | Sensitivity | Specificity | PPV | NPV | combination_id | rank |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:---|---:|
| Split 1 | PTSD_orig | 1565 (93.88%) | 102 (6.12%) | 1565 | 102 | 0 | 0 | 1667 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 1 | symptom_1_7_11_17 | 1248 (74.87%) | 419 (25.13%) | 1248 | 102 | 0 | 317 | 1350 | 317 | 0.7974 | 1.0000 | 1.0000 | 0.2434 | 1_7_11_17 | 1 |
| Split 1 | symptom_4_6_11_17 | 1251 (75.04%) | 416 (24.96%) | 1250 | 101 | 1 | 315 | 1351 | 316 | 0.7987 | 0.9902 | 0.9992 | 0.2428 | 4_6_11_17 | 2 |
| Split 1 | symptom_4_7_11_17 | 1247 (74.81%) | 420 (25.19%) | 1246 | 101 | 1 | 319 | 1347 | 320 | 0.7962 | 0.9902 | 0.9992 | 0.2405 | 4_7_11_17 | 3 |
| Split 2 | PTSD_orig | 1568 (94.06%) | 99 (5.94%) | 1568 | 99 | 0 | 0 | 1667 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 2 | symptom_1_6_11_17 | 1240 (74.39%) | 427 (25.61%) | 1240 | 99 | 0 | 328 | 1339 | 328 | 0.7908 | 1.0000 | 1.0000 | 0.2319 | 1_6_11_17 | 1 |
| Split 2 | symptom_1_7_11_17 | 1252 (75.1%) | 415 (24.9%) | 1252 | 99 | 0 | 316 | 1351 | 316 | 0.7985 | 1.0000 | 1.0000 | 0.2386 | 1_7_11_17 | 2 |
| Split 2 | symptom_1_6_11_19 | 1229 (73.73%) | 438 (26.27%) | 1228 | 98 | 1 | 340 | 1326 | 341 | 0.7832 | 0.9899 | 0.9992 | 0.2237 | 1_6_11_19 | 3 |
| Split 3 | PTSD_orig | 1577 (94.66%) | 89 (5.34%) | 1577 | 89 | 0 | 0 | 1666 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 3 | symptom_4_6_11_17 | 1245 (74.73%) | 421 (25.27%) | 1242 | 86 | 3 | 335 | 1328 | 338 | 0.7876 | 0.9663 | 0.9976 | 0.2043 | 4_6_11_17 | 1 |
| Split 3 | symptom_4_7_11_17 | 1242 (74.55%) | 424 (25.45%) | 1240 | 87 | 2 | 337 | 1327 | 339 | 0.7863 | 0.9775 | 0.9984 | 0.2052 | 4_7_11_17 | 2 |
| Split 3 | symptom_1_7_11_17 | 1255 (75.33%) | 411 (24.67%) | 1253 | 87 | 2 | 324 | 1340 | 326 | 0.7945 | 0.9775 | 0.9984 | 0.2117 | 1_7_11_17 | 3 |

Cross-validation: hierarchical results by fold {.table}

**Stable combinations across folds** – if a combination appeared in
multiple folds, its average performance is reported:

``` r

if (!is.null(cv_results$without_clusters$combinations_summary)) {
  knitr::kable(
    cv_results$without_clusters$combinations_summary,
    digits  = 4,
    caption = "Stable non-hierarchical combinations across folds"
  )
} else {
  cat("No combination appeared in more than one fold (non-hierarchical).\n")
}
```

| Scenario | combination_id | Splits_Appeared | Total_Diagnosed | Total_Non_Diagnosed | True_Positive | True_Negative | Newly_Diagnosed | Newly_Non_Diagnosed | True_Cases | False_Cases | Sensitivity | Specificity | PPV | NPV |
|:---|:---|---:|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PTSD_orig | NA | 3 | 1570 (94.2%) | 96.67 (5.8%) | 1570.0 | 96.67 | 0 | 0 | 1666.67 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| symptom_1_6_7_13 | 1_6_7_13 | 2 | 1519.5 (91.15%) | 147.5 (8.85%) | 1507.5 | 88.50 | 12 | 59 | 1596.00 | 71 | 0.9623 | 0.8806 | 0.9921 | 0.6000 |
| symptom_4_6_7_13 | 4_6_7_13 | 2 | 1525.5 (91.54%) | 141 (8.46%) | 1509.5 | 78.00 | 16 | 63 | 1587.50 | 79 | 0.9599 | 0.8298 | 0.9895 | 0.5532 |

Stable non-hierarchical combinations across folds {.table
style="width:100%;"}

``` r

if (!is.null(cv_results$with_clusters$combinations_summary)) {
  knitr::kable(
    cv_results$with_clusters$combinations_summary,
    digits  = 4,
    caption = "Stable hierarchical combinations across folds"
  )
} else {
  cat("No combination appeared in more than one fold (hierarchical).\n")
}
```

| Scenario | combination_id | Splits_Appeared | Total_Diagnosed | Total_Non_Diagnosed | True_Positive | True_Negative | Newly_Diagnosed | Newly_Non_Diagnosed | True_Cases | False_Cases | Sensitivity | Specificity | PPV | NPV |
|:---|:---|---:|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PTSD_orig | NA | 3 | 1570 (94.2%) | 96.67 (5.8%) | 1570 | 96.67 | 0.00 | 0 | 1666.67 | 0.00 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| symptom_1_7_11_17 | 1_7_11_17 | 3 | 1251.67 (75.1%) | 415 (24.9%) | 1251 | 96.00 | 0.67 | 319 | 1347.00 | 319.67 | 0.7968 | 0.9931 | 0.9995 | 0.2313 |
| symptom_4_6_11_17 | 4_6_11_17 | 2 | 1248 (74.89%) | 418.5 (25.12%) | 1246 | 93.50 | 2.00 | 325 | 1339.50 | 327.00 | 0.7931 | 0.9791 | 0.9984 | 0.2234 |
| symptom_4_7_11_17 | 4_7_11_17 | 2 | 1244.5 (74.68%) | 422 (25.32%) | 1243 | 94.00 | 1.50 | 328 | 1337.00 | 329.50 | 0.7912 | 0.9843 | 0.9988 | 0.2227 |

Stable hierarchical combinations across folds {.table
style="width:100%;"}

### 7.3. Comparing validation approaches

|                    | Holdout          | Cross-Validation            |
|--------------------|------------------|-----------------------------|
| Train/test splits  | 1                | k                           |
| Speed              | Fast             | Slower                      |
| Best for           | Quick assessment | Publication-quality results |
| Stability estimate | Single estimate  | Average over k folds        |

``` r

holdout_sens <- validation_results$without_clusters$summary$Sensitivity[2]
cv_fold_sens <- cv_results$without_clusters$summary_by_fold$sensitivity

cat(sprintf("Holdout sensitivity (top non-hierarchical combination): %.4f\n", holdout_sens))
#> Holdout sensitivity (top non-hierarchical combination): 0.9626
cat(sprintf("CV mean sensitivity across folds:                      %.4f\n", mean(cv_fold_sens, na.rm = TRUE)))
#> Warning in mean.default(cv_fold_sens, na.rm = TRUE): argument is not numeric or
#> logical: returning NA
#> CV mean sensitivity across folds:                      NA
cat(sprintf("CV sensitivity range:                                  %.4f -- %.4f\n",
            min(cv_fold_sens, na.rm = TRUE), max(cv_fold_sens, na.rm = TRUE)))
#> Warning in min(cv_fold_sens, na.rm = TRUE): no non-missing arguments to min;
#> returning Inf
#> Warning in max(cv_fold_sens, na.rm = TRUE): no non-missing arguments to max;
#> returning -Inf
#> CV sensitivity range:                                  Inf -- -Inf
```

### 7.4. Best practices

1.  Set a seed for reproducibility: `seed = 123`
2.  Use holdout for initial assessment; cross-validation for
    publication-quality results
3.  Choose an appropriate optimisation target:
    - `score_by = "newly_nondiagnosed"` to minimise missed diagnoses
    - `score_by = "false_cases"` to minimise total misclassifications
4.  Examine multiple metrics: sensitivity for screening, specificity for
    differential diagnosis, PPV/NPV for clinical decision-making

## 8. Conclusion

For workflows that test whether optimised criteria generalise to
independent samples, see:

- [External Validation
  (PCL-5)](https://tobiasrspiller.github.io/PTSDdiag/articles/external_validation_pcl5.md)
  – derivation on one PCL-5 dataset, validation on another
- [External Validation
  (CAPS-5)](https://tobiasrspiller.github.io/PTSDdiag/articles/external_validation_caps5.md)
  – validation against the CAPS-5 gold standard
