# External Validation with CAPS-5 Data

## 1. Introduction

The CAPS-5 (Clinician-Administered PTSD Scale for DSM-5) is the gold
standard for PTSD diagnosis. When both PCL-5 and CAPS-5 data are
available for the same participants, optimised PCL-5 symptom
combinations can be evaluated against the clinician-rated diagnosis.

CAPS-5 mirrors the PCL-5 structure: 20 items on a 0–4 severity scale,
where the clinician integrates frequency and intensity into a single
rating. All `PTSDdiag` functions work identically on CAPS-5 data once
columns are renamed.

This vignette demonstrates how to:

- Prepare CAPS-5 data for analysis
- Apply DSM-5 diagnostic criteria to CAPS-5 data
- Compare PCL-5 and CAPS-5 diagnoses using either instrument as the
  reference standard
- Evaluate optimised PCL-5 combinations against the CAPS-5 gold standard

For a single-dataset PCL-5 workflow, see the [Full Internal
Analysis](https://tobiasrspiller.github.io/PTSDdiag/articles/internal_analysis.md)
vignette. For cross-sample validation using two PCL-5 datasets, see the
[External Validation
(PCL-5)](https://tobiasrspiller.github.io/PTSDdiag/articles/external_validation_pcl5.md)
vignette.

## 2. Setup

``` r

library("PTSDdiag")
```

We use the included `simulated_ptsd` dataset as the PCL-5 sample. To
illustrate the workflow, we simulate CAPS-5 data by adding clinician
variance to the PCL-5 scores. In practice, these would come from
separate instruments administered to the same participants.

``` r

data("simulated_ptsd")
simulated_ptsd_renamed <- rename_ptsd_columns(simulated_ptsd)
```

``` r

set.seed(42)
caps5_raw <- simulated_ptsd
for (j in seq_len(ncol(caps5_raw))) {
  noise <- sample(c(-1L, 0L, 0L, 0L, 1L), nrow(caps5_raw), replace = TRUE)
  caps5_raw[[j]] <- pmin(4L, pmax(0L, caps5_raw[[j]] + noise))
}
```

## 3. Preparing CAPS-5 data

[`rename_caps5_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_caps5_columns.md)
standardises column names. It works identically to
[`rename_ptsd_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)
but includes CAPS-5-specific documentation and error messages.

``` r

caps5 <- rename_caps5_columns(caps5_raw)
head(caps5[, 1:5])
#>   symptom_1 symptom_2 symptom_3 symptom_4 symptom_5
#> 1         1         2         4         1         3
#> 2         4         3         4         3         2
#> 3         0         0         2         3         2
#> 4         2         3         3         3         3
#> 5         2         3         3         3         2
#> 6         1         1         2         0         1
```

## 4. CAPS-5 diagnosis

[`create_caps5_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_caps5_diagnosis.md)
applies the standard DSM-5-TR diagnostic algorithm (binarise at \>= 2,
require \>= 1 symptom in each of Clusters B–E) to CAPS-5 data:

``` r

caps5_dx <- create_caps5_diagnosis(caps5)
cat("CAPS-5 PTSD prevalence:", mean(caps5_dx$PTSD_caps5), "\n")
#> CAPS-5 PTSD prevalence: 0.9426
cat("PCL-5 PTSD prevalence:", mean(
  create_ptsd_diagnosis_binarized(simulated_ptsd_renamed)$PTSD_orig
), "\n")
#> PCL-5 PTSD prevalence: 0.942
```

## 5. Comparing PCL-5 and CAPS-5 diagnoses

Pass `caps5_data` to
[`compare_diagnostic_systems()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
and choose which instrument serves as the reference standard. The
reference row always has perfect sensitivity and specificity (1.0000)
because it defines the diagnostic “truth”.

### 5.1. PCL-5 as reference

When PCL-5 is the reference, we evaluate how well the CAPS-5 and other
criteria reproduce the PCL-5-based DSM-5-TR diagnosis:

``` r

tbl_pcl5_ref <- compare_diagnostic_systems(
  simulated_ptsd_renamed,
  icd11      = TRUE,
  caps5_data = caps5,
  reference  = "pcl5"
)

knitr::kable(
  tbl_pcl5_ref,
  digits  = 4,
  caption = "PCL-5 as reference: how do CAPS-5 and ICD-11 compare?"
)
```

| system | n_diagnosed | pct_diagnosed | sensitivity | specificity | ppv | npv | n_false_negative | pct_false_negative | n_false_positive | pct_false_positive | n_misclassified |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| DSM-5-TR (PCL-5) | 4710 | 94.20 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0.00 | 0 | 0.00 | 0 |
| DSM-5-TR (CAPS-5) | 4713 | 94.26 | 0.9824 | 0.7034 | 0.9818 | 0.7108 | 83 | 1.66 | 86 | 1.72 | 169 |
| ICD-11 (PCL-5) | 4641 | 92.82 | 0.9781 | 0.8828 | 0.9927 | 0.7131 | 103 | 2.06 | 34 | 0.68 | 137 |

PCL-5 as reference: how do CAPS-5 and ICD-11 compare? {.table}

### 5.2. CAPS-5 as reference

When CAPS-5 is the reference, we evaluate how well the PCL-5 diagnosis
and other criteria reproduce the clinician-rated gold standard:

``` r

tbl_caps5_ref <- compare_diagnostic_systems(
  simulated_ptsd_renamed,
  icd11      = TRUE,
  caps5_data = caps5,
  reference  = "caps5"
)

knitr::kable(
  tbl_caps5_ref,
  digits  = 4,
  caption = "CAPS-5 as reference: how do PCL-5 and ICD-11 compare?"
)
```

| system | n_diagnosed | pct_diagnosed | sensitivity | specificity | ppv | npv | n_false_negative | pct_false_negative | n_false_positive | pct_false_positive | n_misclassified |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| DSM-5-TR (CAPS-5) | 4713 | 94.26 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0.00 | 0 | 0.00 | 0 |
| DSM-5-TR (PCL-5) | 4710 | 94.20 | 0.9818 | 0.7108 | 0.9824 | 0.7034 | 86 | 1.72 | 83 | 1.66 | 169 |
| ICD-11 (PCL-5) | 4641 | 92.82 | 0.9650 | 0.6760 | 0.9800 | 0.5404 | 165 | 3.30 | 93 | 1.86 | 258 |

CAPS-5 as reference: how do PCL-5 and ICD-11 compare? {.table}

## 6. Adding optimised combinations

Optimised PCL-5 combinations can be added to the comparison. Here we
derive combinations and evaluate them against both reference standards.

``` r

best_nonhier <- optimize_combinations(
  simulated_ptsd_renamed,
  n_symptoms    = 4,
  n_required    = 3,
  n_top         = 3,
  score_by      = "newly_nondiagnosed",
  show_progress = FALSE
)
```

**Against PCL-5 reference:**

``` r

tbl_opt_pcl5 <- compare_diagnostic_systems(
  simulated_ptsd_renamed,
  best_nonhier$diagnosis_comparison,
  icd11      = TRUE,
  caps5_data = caps5,
  reference  = "pcl5"
)

knitr::kable(
  tbl_opt_pcl5,
  digits  = 4,
  caption = "PCL-5 as reference: DSM-5-TR, ICD-11, CAPS-5, and optimised combinations"
)
```

| system | n_diagnosed | pct_diagnosed | sensitivity | specificity | ppv | npv | n_false_negative | pct_false_negative | n_false_positive | pct_false_positive | n_misclassified |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| DSM-5-TR (PCL-5) | 4710 | 94.20 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0.00 | 0 | 0.00 | 0 |
| DSM-5-TR (CAPS-5) | 4713 | 94.26 | 0.9824 | 0.7034 | 0.9818 | 0.7108 | 83 | 1.66 | 86 | 1.72 | 169 |
| ICD-11 (PCL-5) | 4641 | 92.82 | 0.9781 | 0.8828 | 0.9927 | 0.7131 | 103 | 2.06 | 34 | 0.68 | 137 |
| symptom_1_6_7_13 | 4573 | 91.46 | 0.9628 | 0.8690 | 0.9917 | 0.5902 | 175 | 3.50 | 38 | 0.76 | 213 |
| symptom_4_6_7_13 | 4574 | 91.48 | 0.9628 | 0.8655 | 0.9915 | 0.5892 | 175 | 3.50 | 39 | 0.78 | 214 |
| symptom_4_6_7_17 | 4568 | 91.36 | 0.9614 | 0.8621 | 0.9912 | 0.5787 | 182 | 3.64 | 40 | 0.80 | 222 |

PCL-5 as reference: DSM-5-TR, ICD-11, CAPS-5, and optimised combinations
{.table}

**Against CAPS-5 reference:**

``` r

tbl_opt_caps5 <- compare_diagnostic_systems(
  simulated_ptsd_renamed,
  best_nonhier$diagnosis_comparison,
  icd11      = TRUE,
  caps5_data = caps5,
  reference  = "caps5"
)

knitr::kable(
  tbl_opt_caps5,
  digits  = 4,
  caption = "CAPS-5 as reference: DSM-5-TR, ICD-11, PCL-5, and optimised combinations"
)
```

| system | n_diagnosed | pct_diagnosed | sensitivity | specificity | ppv | npv | n_false_negative | pct_false_negative | n_false_positive | pct_false_positive | n_misclassified |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| DSM-5-TR (CAPS-5) | 4713 | 94.26 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0.00 | 0 | 0.00 | 0 |
| DSM-5-TR (PCL-5) | 4710 | 94.20 | 0.9818 | 0.7108 | 0.9824 | 0.7034 | 86 | 1.72 | 83 | 1.66 | 169 |
| ICD-11 (PCL-5) | 4641 | 92.82 | 0.9650 | 0.6760 | 0.9800 | 0.5404 | 165 | 3.30 | 93 | 1.86 | 258 |
| symptom_1_6_7_13 | 4573 | 91.46 | 0.9531 | 0.7178 | 0.9823 | 0.4824 | 221 | 4.42 | 81 | 1.62 | 302 |
| symptom_4_6_7_13 | 4574 | 91.48 | 0.9531 | 0.7143 | 0.9821 | 0.4812 | 221 | 4.42 | 82 | 1.64 | 303 |
| symptom_4_6_7_17 | 4568 | 91.36 | 0.9508 | 0.6969 | 0.9810 | 0.4630 | 232 | 4.64 | 87 | 1.74 | 319 |

CAPS-5 as reference: DSM-5-TR, ICD-11, PCL-5, and optimised combinations
{.table}

## 7. Interpreting results

When comparing across instruments:

- When `caps5_data` is provided, labels are disambiguated automatically:
  `"DSM-5-TR (PCL-5)"` and `"DSM-5-TR (CAPS-5)"`.
- The `reference` parameter controls which instrument defines diagnostic
  “truth”. Running the comparison twice (once with each reference)
  provides a complete picture.
- ICD-11 criteria are always computed from PCL-5 data and labelled
  `"ICD-11 (PCL-5)"`.
- All workflows without `caps5_data` remain unchanged.

The degree of agreement between PCL-5 and CAPS-5 diagnoses is itself
informative: substantial discordance may reflect meaningful differences
in what self-report and clinician-administered instruments capture,
rather than a failure of the simplified criteria.
