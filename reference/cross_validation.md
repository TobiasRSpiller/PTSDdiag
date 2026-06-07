# Perform k-fold cross-validation for PTSD diagnostic models

Validates PTSD diagnostic models using k-fold cross-validation to assess
generalization performance and identify stable symptom combinations.

## Usage

``` r
cross_validation(
  data,
  k = 5,
  score_by = "sensitivity",
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

  - "accuracy": Minimize total misclassifications (FP + FN, i.e.
    maximise overall accuracy).

  - "sensitivity": Minimize false negatives only (i.e. maximise
    sensitivity relative to the full DSM-5-TR diagnosis). Default.

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
# Create sample data
set.seed(42)
sample_data <- data.frame(
  matrix(sample(0:4, 20 * 200, replace = TRUE),
         nrow = 200,
         ncol = 20)
)
colnames(sample_data) <- paste0("symptom_", 1:20)

# \donttest{
# Perform 5-fold cross-validation
cv_results <- cross_validation(sample_data, k = 5)
#> ℹ Evaluated 38760 combinations. Best: 6, 7, 9, 14, 15, 16
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 3, 4, 7, 8, 15, 16 (3 additional tied)
#> ℹ Evaluated 38760 combinations. Best: 3, 6, 7, 8, 11, 16
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 3, 5, 6, 13, 15, 16
#> ℹ Evaluated 38760 combinations. Best: 2, 6, 7, 8, 15, 16 (1 additional tied)
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 3, 4, 7, 8, 15, 16
#> ℹ Evaluated 38760 combinations. Best: 3, 6, 7, 8, 11, 15 (3 additional tied)
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 4, 5, 7, 8, 15, 16
#> ℹ Evaluated 38760 combinations. Best: 6, 7, 8, 9, 15, 16
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 2, 4, 6, 8, 17, 20

# View summary for each fold
cv_results$without_clusters$summary_by_fold
#>      Split                Scenario Total Diagnosed Total Non-Diagnosed
#> 1  Split 1               PTSD_orig     31 (75.61%)         10 (24.39%)
#> 2  Split 1  symptom_6_7_9_14_15_16      23 (56.1%)          18 (43.9%)
#> 3  Split 1  symptom_3_6_7_11_13_17     21 (51.22%)         20 (48.78%)
#> 4  Split 1 symptom_6_7_11_14_15_16     22 (53.66%)         19 (46.34%)
#> 5  Split 2               PTSD_orig      31 (77.5%)           9 (22.5%)
#> 6  Split 2   symptom_3_6_7_8_11_16        26 (65%)            14 (35%)
#> 7  Split 2   symptom_2_6_7_9_15_16        24 (60%)            16 (40%)
#> 8  Split 2    symptom_3_6_7_8_9_11        24 (60%)            16 (40%)
#> 9  Split 3               PTSD_orig      31 (77.5%)           9 (22.5%)
#> 10 Split 3   symptom_2_6_7_8_15_16        20 (50%)            20 (50%)
#> 11 Split 3   symptom_3_6_7_8_11_16        22 (55%)            18 (45%)
#> 12 Split 3    symptom_3_6_7_8_9_11      23 (57.5%)          17 (42.5%)
#> 13 Split 4               PTSD_orig      31 (77.5%)           9 (22.5%)
#> 14 Split 4   symptom_3_6_7_8_11_15        20 (50%)            20 (50%)
#> 15 Split 4   symptom_3_6_7_8_11_16      25 (62.5%)          15 (37.5%)
#> 16 Split 4  symptom_3_6_7_11_12_16      21 (52.5%)          19 (47.5%)
#> 17 Split 5               PTSD_orig     30 (76.92%)          9 (23.08%)
#> 18 Split 5   symptom_6_7_8_9_15_16     21 (53.85%)         18 (46.15%)
#> 19 Split 5  symptom_6_7_9_14_15_16     23 (58.97%)         16 (41.03%)
#> 20 Split 5   symptom_2_6_7_9_15_16     22 (56.41%)         17 (43.59%)
#>    True Positive True Negative Newly Diagnosed Newly Non-Diagnosed True Cases
#> 1             31            10               0                   0         41
#> 2             22             9               1                   9         31
#> 3             19             8               2                  12         27
#> 4             20             8               2                  11         28
#> 5             31             9               0                   0         40
#> 6             23             6               3                   8         29
#> 7             21             6               3                  10         27
#> 8             23             8               1                   8         31
#> 9             31             9               0                   0         40
#> 10            18             7               2                  13         25
#> 11            21             8               1                  10         29
#> 12            21             7               2                  10         28
#> 13            31             9               0                   0         40
#> 14            19             8               1                  12         27
#> 15            24             8               1                   7         32
#> 16            19             7               2                  12         26
#> 17            30             9               0                   0         39
#> 18            20             8               1                  10         28
#> 19            21             7               2                   9         28
#> 20            20             7               2                  10         27
#>    False Cases Sensitivity Specificity    PPV    NPV  combination_id rank
#> 1            0      1.0000      1.0000 1.0000 1.0000            <NA>   NA
#> 2           10      0.7097      0.9000 0.9565 0.5000  6_7_9_14_15_16    1
#> 3           14      0.6129      0.8000 0.9048 0.4000  3_6_7_11_13_17    2
#> 4           13      0.6452      0.8000 0.9091 0.4211 6_7_11_14_15_16    3
#> 5            0      1.0000      1.0000 1.0000 1.0000            <NA>   NA
#> 6           11      0.7419      0.6667 0.8846 0.4286   3_6_7_8_11_16    1
#> 7           13      0.6774      0.6667 0.8750 0.3750   2_6_7_9_15_16    2
#> 8            9      0.7419      0.8889 0.9583 0.5000    3_6_7_8_9_11    3
#> 9            0      1.0000      1.0000 1.0000 1.0000            <NA>   NA
#> 10          15      0.5806      0.7778 0.9000 0.3500   2_6_7_8_15_16    1
#> 11          11      0.6774      0.8889 0.9545 0.4444   3_6_7_8_11_16    2
#> 12          12      0.6774      0.7778 0.9130 0.4118    3_6_7_8_9_11    3
#> 13           0      1.0000      1.0000 1.0000 1.0000            <NA>   NA
#> 14          13      0.6129      0.8889 0.9500 0.4000   3_6_7_8_11_15    1
#> 15           8      0.7742      0.8889 0.9600 0.5333   3_6_7_8_11_16    2
#> 16          14      0.6129      0.7778 0.9048 0.3684  3_6_7_11_12_16    3
#> 17           0      1.0000      1.0000 1.0000 1.0000            <NA>   NA
#> 18          11      0.6667      0.8889 0.9524 0.4444   6_7_8_9_15_16    1
#> 19          11      0.7000      0.7778 0.9130 0.4375  6_7_9_14_15_16    2
#> 20          12      0.6667      0.7778 0.9091 0.4118   2_6_7_9_15_16    3

# View combinations that appeared multiple times
cv_results$without_clusters$combinations_summary
#> # A tibble: 5 × 15
#>   Scenario    combination_id Splits_Appeared Total_Diagnosed Total_Non_Diagnosed
#>   <chr>       <chr>                    <int> <chr>           <chr>              
#> 1 PTSD_orig   NA                           5 30.8 (77.01%)   9.2 (22.99%)       
#> 2 symptom_2_… 2_6_7_9_15_16                2 23 (58.2%)      16.5 (41.8%)       
#> 3 symptom_3_… 3_6_7_8_11_16                3 24.33 (60.83%)  15.67 (39.17%)     
#> 4 symptom_3_… 3_6_7_8_9_11                 2 23.5 (58.75%)   16.5 (41.25%)      
#> 5 symptom_6_… 6_7_9_14_15_16               2 23 (57.53%)     17 (42.47%)        
#> # ℹ 10 more variables: True_Positive <dbl>, True_Negative <dbl>,
#> #   Newly_Diagnosed <dbl>, Newly_Non_Diagnosed <dbl>, True_Cases <dbl>,
#> #   False_Cases <dbl>, Sensitivity <dbl>, Specificity <dbl>, PPV <dbl>,
#> #   NPV <dbl>
# }
```
