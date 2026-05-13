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
| Split 1 | PTSD_orig | 1577 (94.6%) | 90 (5.4%) | 1577 | 90 | 0 | 0 | 1667 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 1 | symptom_1_6_7_13 | 1522 (91.3%) | 145 (8.7%) | 1509 | 77 | 13 | 68 | 1586 | 81 | 0.9569 | 0.8556 | 0.9915 | 0.5310 | 1_6_7_13 | 1 |
| Split 1 | symptom_4_6_7_13 | 1522 (91.3%) | 145 (8.7%) | 1509 | 77 | 13 | 68 | 1586 | 81 | 0.9569 | 0.8556 | 0.9915 | 0.5310 | 4_6_7_13 | 2 |
| Split 1 | symptom_1_6_7_19 | 1515 (90.88%) | 152 (9.12%) | 1504 | 79 | 11 | 73 | 1583 | 84 | 0.9537 | 0.8778 | 0.9927 | 0.5197 | 1_6_7_19 | 3 |
| Split 2 | PTSD_orig | 1559 (93.52%) | 108 (6.48%) | 1559 | 108 | 0 | 0 | 1667 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 2 | symptom_4_6_7_13 | 1516 (90.94%) | 151 (9.06%) | 1502 | 94 | 14 | 57 | 1596 | 71 | 0.9634 | 0.8704 | 0.9908 | 0.6225 | 4_6_7_13 | 1 |
| Split 2 | symptom_6_7_17_20 | 1514 (90.82%) | 153 (9.18%) | 1498 | 92 | 16 | 61 | 1590 | 77 | 0.9609 | 0.8519 | 0.9894 | 0.6013 | 6_7_17_20 | 2 |
| Split 2 | symptom_1_6_7_13 | 1524 (91.42%) | 143 (8.58%) | 1509 | 93 | 15 | 50 | 1602 | 65 | 0.9679 | 0.8611 | 0.9902 | 0.6503 | 1_6_7_13 | 3 |
| Split 3 | PTSD_orig | 1574 (94.48%) | 92 (5.52%) | 1574 | 92 | 0 | 0 | 1666 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 3 | symptom_4_6_7_17 | 1519 (91.18%) | 147 (8.82%) | 1507 | 80 | 12 | 67 | 1587 | 79 | 0.9574 | 0.8696 | 0.9921 | 0.5442 | 4_6_7_17 | 1 |
| Split 3 | symptom_6_7_11_17 | 1509 (90.58%) | 157 (9.42%) | 1497 | 80 | 12 | 77 | 1577 | 89 | 0.9511 | 0.8696 | 0.9920 | 0.5096 | 6_7_11_17 | 2 |
| Split 3 | symptom_1_6_7_13 | 1527 (91.66%) | 139 (8.34%) | 1517 | 82 | 10 | 57 | 1599 | 67 | 0.9638 | 0.8913 | 0.9935 | 0.5899 | 1_6_7_13 | 3 |

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
| Split 1 | PTSD_orig | 1577 (94.6%) | 90 (5.4%) | 1577 | 90 | 0 | 0 | 1667 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 1 | symptom_4_6_11_17 | 1241 (74.45%) | 426 (25.55%) | 1240 | 89 | 1 | 337 | 1329 | 338 | 0.7863 | 0.9889 | 0.9992 | 0.2089 | 4_6_11_17 | 1 |
| Split 1 | symptom_1_7_11_17 | 1243 (74.57%) | 424 (25.43%) | 1243 | 90 | 0 | 334 | 1333 | 334 | 0.7882 | 1.0000 | 1.0000 | 0.2123 | 1_7_11_17 | 2 |
| Split 1 | symptom_1_6_11_17 | 1242 (74.51%) | 425 (25.49%) | 1242 | 90 | 0 | 335 | 1332 | 335 | 0.7876 | 1.0000 | 1.0000 | 0.2118 | 1_6_11_17 | 3 |
| Split 2 | PTSD_orig | 1559 (93.52%) | 108 (6.48%) | 1559 | 108 | 0 | 0 | 1667 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 2 | symptom_5_7_11_17 | 1225 (73.49%) | 442 (26.51%) | 1223 | 106 | 2 | 336 | 1329 | 338 | 0.7845 | 0.9815 | 0.9984 | 0.2398 | 5_7_11_17 | 1 |
| Split 2 | symptom_1_7_11_17 | 1242 (74.51%) | 425 (25.49%) | 1240 | 106 | 2 | 319 | 1346 | 321 | 0.7954 | 0.9815 | 0.9984 | 0.2494 | 1_7_11_17 | 2 |
| Split 2 | symptom_4_7_11_17 | 1235 (74.09%) | 432 (25.91%) | 1233 | 106 | 2 | 326 | 1339 | 328 | 0.7909 | 0.9815 | 0.9984 | 0.2454 | 4_7_11_17 | 3 |
| Split 3 | PTSD_orig | 1574 (94.48%) | 92 (5.52%) | 1574 | 92 | 0 | 0 | 1666 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | NA | NA |
| Split 3 | symptom_4_6_11_17 | 1258 (75.51%) | 408 (24.49%) | 1257 | 91 | 1 | 317 | 1348 | 318 | 0.7986 | 0.9891 | 0.9992 | 0.2230 | 4_6_11_17 | 1 |
| Split 3 | symptom_1_6_11_17 | 1258 (75.51%) | 408 (24.49%) | 1257 | 91 | 1 | 317 | 1348 | 318 | 0.7986 | 0.9891 | 0.9992 | 0.2230 | 1_6_11_17 | 2 |
| Split 3 | symptom_1_7_11_17 | 1270 (76.23%) | 396 (23.77%) | 1270 | 92 | 0 | 304 | 1362 | 304 | 0.8069 | 1.0000 | 1.0000 | 0.2323 | 1_7_11_17 | 3 |

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
| PTSD_orig | NA | 3 | 1570 (94.2%) | 96.67 (5.8%) | 1570.00 | 96.67 | 0.00 | 0.00 | 1666.67 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| symptom_1_6_7_13 | 1_6_7_13 | 3 | 1524.33 (91.46%) | 142.33 (8.54%) | 1511.67 | 84.00 | 12.67 | 58.33 | 1595.67 | 71 | 0.9628 | 0.8689 | 0.9917 | 0.5902 |
| symptom_4_6_7_13 | 4_6_7_13 | 2 | 1519 (91.12%) | 148 (8.88%) | 1505.50 | 85.50 | 13.50 | 62.50 | 1591.00 | 76 | 0.9601 | 0.8636 | 0.9911 | 0.5777 |

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
| PTSD_orig | NA | 3 | 1570 (94.2%) | 96.67 (5.8%) | 1570.0 | 96.67 | 0.00 | 0 | 1666.67 | 0.00 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| symptom_1_6_11_17 | 1_6_11_17 | 2 | 1250 (75.01%) | 416.5 (24.99%) | 1249.5 | 90.50 | 0.50 | 326 | 1340.00 | 326.50 | 0.7931 | 0.9945 | 0.9996 | 0.2173 |
| symptom_1_7_11_17 | 1_7_11_17 | 3 | 1251.67 (75.1%) | 415 (24.9%) | 1251.0 | 96.00 | 0.67 | 319 | 1347.00 | 319.67 | 0.7968 | 0.9931 | 0.9995 | 0.2313 |
| symptom_4_6_11_17 | 4_6_11_17 | 2 | 1249.5 (74.98%) | 417 (25.02%) | 1248.5 | 90.00 | 1.00 | 327 | 1338.50 | 328.00 | 0.7924 | 0.9890 | 0.9992 | 0.2158 |

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
