# Perform k-fold cross-validation for PTSD diagnostic models

Validates PTSD diagnostic models using k-fold cross-validation to assess
generalization performance and identify stable symptom combinations.

## Usage

``` r
cross_validation(
  data,
  k = 5,
  score_by = "balanced_accuracy",
  seed = 123,
  n_symptoms = 6,
  n_required = 4,
  n_top = 3,
  DT = FALSE
)
```

## Arguments

- data:

  A dataframe containing the 20 PCL-5 item columns `symptom_1` through
  `symptom_20` (output of
  [`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)).
  Any additional non-symptom columns (e.g. an ID column passed via
  `rename_ptsd_columns(..., id_col = "patient_id")`) are carried through
  every fold and prepended to each `fold_results` entry so diagnoses can
  be joined back to the original dataframe.

- k:

  Number of folds for cross-validation (default: 5)

- score_by:

  Character string specifying optimization criterion:

  - "balanced_accuracy": Maximise balanced accuracy, the mean of
    sensitivity and specificity. Robust when one diagnostic class is
    much more common than the other. Default.

  - "accuracy": Minimize total misclassifications (FP + FN, i.e.
    maximise overall accuracy).

  - "sensitivity": Minimize false negatives only (i.e. maximise
    sensitivity relative to the full DSM-5-TR diagnosis).

- seed:

  Integer for random number generation reproducibility (default: 123)

- n_symptoms:

  Integer specifying how many symptoms per combination (default: 6).
  Must be between 1 and 20.

- n_required:

  Integer specifying how many symptoms must be present for diagnosis
  (default: 4). Must be between 1 and `n_symptoms`.

- n_top:

  Integer specifying how many top combinations to return (default: 3).
  Must be a positive integer.

- DT:

  Logical. If `TRUE`, return summaries as interactive
  [`datatable`](https://rdrr.io/pkg/DT/man/datatable.html) widgets. If
  `FALSE` (default), return plain data.frames. The DT package must be
  installed when `DT = TRUE`.

## Value

A list containing:

- without_clusters: Results for model without cluster representation

  - fold_results: List of diagnostic comparisons for each fold

  - summary_by_fold: Detailed results for each fold (data.frame or DT
    widget)

  - combinations_summary: Average performance for combinations appearing
    in multiple folds (data.frame, DT widget, or NULL if no combinations
    repeat)

- with_clusters: Results for model with cluster representation

  - fold_results: List of diagnostic comparisons for each fold

  - summary_by_fold: Detailed results for each fold (data.frame or DT
    widget)

  - combinations_summary: Average performance for combinations appearing
    in multiple folds (data.frame, DT widget, or NULL if no combinations
    repeat)

## Details

The function:

1.  Splits data into k stratified folds (preserving the proportion of
    diagnosed cases in each fold via
    [`vfold_cv`](https://rsample.tidymodels.org/reference/vfold_cv.html))

2.  For each fold, trains on k-1 folds and tests on the held-out fold

3.  Identifies symptom combinations that appear across multiple folds

4.  Calculates average performance metrics for repeated combinations

Two models are evaluated:

- Model without cluster representation: Any `n_required` of `n_symptoms`
  symptoms

- Model with cluster representation: `n_required` of `n_symptoms`
  symptoms with at least one from each cluster

If the future.apply package is installed and a
[`plan`](https://future.futureverse.org/reference/plan.html) has been
set (e.g., `future::plan(future::multisession)`), folds are processed in
parallel via
[`future_lapply`](https://future.apply.futureverse.org/reference/future_lapply.html).
On macOS (including Apple Silicon), use
[`future::multisession`](https://future.futureverse.org/reference/multisession.html)
rather than
[`future::multicore`](https://future.futureverse.org/reference/multicore.html),
especially inside RStudio.

## Examples

``` r
# Use a 250-row subset of the bundled data to keep the example fast
ptsd_data <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                                 id_col = c("patient_id", "age", "sex"))

# \donttest{
# 3-fold cross-validation of a compact 3-of-4 definition (a 4-symptom
# search keeps the example fast; use n_symptoms = 6, n_required = 4 for
# the classic rule)
cv_results <- cross_validation(ptsd_data, k = 3,
                               n_symptoms = 4, n_required = 3)
#> ℹ Evaluated 4845 combinations. Best: 1, 5, 6, 7 (12 additional tied)
#> ℹ Generated 420 valid cluster-constrained combinations
#> ℹ Evaluated 420 combinations. Best: 1, 7, 13, 19
#> ℹ Evaluated 4845 combinations. Best: 6, 7, 12, 17
#> ℹ Generated 420 valid cluster-constrained combinations
#> ℹ Evaluated 420 combinations. Best: 1, 6, 11, 17 (2 additional tied)
#> ℹ Evaluated 4845 combinations. Best: 4, 6, 7, 12 (5 additional tied)
#> ℹ Generated 420 valid cluster-constrained combinations
#> ℹ Evaluated 420 combinations. Best: 1, 6, 11, 17 (3 additional tied)

# View summary for each fold
cv_results$without_clusters$summary_by_fold
#>      Split          Scenario Total Diagnosed Total Non-Diagnosed True Positive
#> 1  Split 1         PTSD_orig     79 (94.05%)           5 (5.95%)            79
#> 2  Split 1   symptom_1_5_6_7     80 (95.24%)           4 (4.76%)            77
#> 3  Split 1   symptom_1_6_7_9     80 (95.24%)           4 (4.76%)            78
#> 4  Split 1  symptom_1_6_7_12     81 (96.43%)           3 (3.57%)            78
#> 5  Split 2         PTSD_orig     78 (93.98%)           5 (6.02%)            78
#> 6  Split 2 symptom_6_7_12_17     76 (91.57%)           7 (8.43%)            76
#> 7  Split 2  symptom_4_6_7_12     76 (91.57%)           7 (8.43%)            76
#> 8  Split 2 symptom_6_7_12_15     75 (90.36%)           8 (9.64%)            75
#> 9  Split 3         PTSD_orig     75 (90.36%)           8 (9.64%)            75
#> 10 Split 3  symptom_4_6_7_12     72 (86.75%)         11 (13.25%)            72
#> 11 Split 3  symptom_4_6_7_17     73 (87.95%)         10 (12.05%)            72
#> 12 Split 3  symptom_4_6_7_19     71 (85.54%)         12 (14.46%)            71
#>    True Negative Newly Diagnosed Newly Non-Diagnosed True Cases False Cases
#> 1              5               0                   0         84           0
#> 2              2               3                   2         79           5
#> 3              3               2                   1         81           3
#> 4              2               3                   1         80           4
#> 5              5               0                   0         83           0
#> 6              5               0                   2         81           2
#> 7              5               0                   2         81           2
#> 8              5               0                   3         80           3
#> 9              8               0                   0         83           0
#> 10             8               0                   3         80           3
#> 11             7               1                   3         79           4
#> 12             8               0                   4         79           4
#>    Sensitivity Specificity    PPV    NPV Accuracy Balanced Accuracy
#> 1       1.0000       1.000 1.0000 1.0000   1.0000            1.0000
#> 2       0.9747       0.400 0.9625 0.5000   0.9405            0.6873
#> 3       0.9873       0.600 0.9750 0.7500   0.9643            0.7937
#> 4       0.9873       0.400 0.9630 0.6667   0.9524            0.6937
#> 5       1.0000       1.000 1.0000 1.0000   1.0000            1.0000
#> 6       0.9744       1.000 1.0000 0.7143   0.9759            0.9872
#> 7       0.9744       1.000 1.0000 0.7143   0.9759            0.9872
#> 8       0.9615       1.000 1.0000 0.6250   0.9639            0.9808
#> 9       1.0000       1.000 1.0000 1.0000   1.0000            1.0000
#> 10      0.9600       1.000 1.0000 0.7273   0.9639            0.9800
#> 11      0.9600       0.875 0.9863 0.7000   0.9518            0.9175
#> 12      0.9467       1.000 1.0000 0.6667   0.9518            0.9733
#>    combination_id rank
#> 1            <NA>   NA
#> 2         1_5_6_7    1
#> 3         1_6_7_9    2
#> 4        1_6_7_12    3
#> 5            <NA>   NA
#> 6       6_7_12_17    1
#> 7        4_6_7_12    2
#> 8       6_7_12_15    3
#> 9            <NA>   NA
#> 10       4_6_7_12    1
#> 11       4_6_7_17    2
#> 12       4_6_7_19    3

# View combinations that appeared multiple times
cv_results$without_clusters$combinations_summary
#> # A tibble: 2 × 17
#>   Scenario    combination_id Splits_Appeared Total_Diagnosed Total_Non_Diagnosed
#>   <chr>       <chr>                    <int> <chr>           <chr>              
#> 1 PTSD_orig   NA                           3 77.33 (92.8%)   6 (7.2%)           
#> 2 symptom_4_… 4_6_7_12                     2 74 (89.16%)     9 (10.84%)         
#> # ℹ 12 more variables: True_Positive <dbl>, True_Negative <dbl>,
#> #   Newly_Diagnosed <dbl>, Newly_Non_Diagnosed <dbl>, True_Cases <dbl>,
#> #   False_Cases <dbl>, Sensitivity <dbl>, Specificity <dbl>, PPV <dbl>,
#> #   NPV <dbl>, Accuracy <dbl>, Balanced_Accuracy <dbl>
# }
```
