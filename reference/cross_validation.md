# Perform k-fold cross-validation for PTSD diagnostic models

Validates PTSD diagnostic models using k-fold cross-validation to assess
generalization performance and identify stable symptom combinations.

## Usage

``` r
cross_validation(
  data,
  k = 5,
  score_by = "newly_nondiagnosed",
  seed = 123,
  n_symptoms = 6,
  n_required = 4,
  n_top = 3,
  DT = FALSE
)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns with PCL-5 item scores
  (output of rename_ptsd_columns). Each symptom should be scored on a
  0-4 scale.

- k:

  Number of folds for cross-validation (default: 5)

- score_by:

  Character string specifying optimization criterion:

  - "false_cases": Minimize total misclassifications

  - "newly_nondiagnosed": Minimize false negatives only (default)

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

1.  Splits data into k folds

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
#> ℹ Evaluated 38760 combinations. Best: 3, 6, 7, 8, 11, 16
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 3, 5, 6, 13, 15, 16
#> ℹ Evaluated 38760 combinations. Best: 6, 7, 8, 9, 15, 16
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 4, 5, 7, 8, 15, 16
#> ℹ Evaluated 38760 combinations. Best: 3, 6, 7, 8, 11, 16
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 3, 5, 6, 13, 15, 16
#> ℹ Evaluated 38760 combinations. Best: 3, 6, 7, 8, 11, 16
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 3, 4, 7, 8, 15, 16
#> ℹ Evaluated 38760 combinations. Best: 3, 6, 7, 11, 13, 17
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 3, 5, 6, 13, 15, 16

# View summary for each fold
cv_results$without_clusters$summary_by_fold
#>      Split               Scenario Total Diagnosed Total Non-Diagnosed
#> 1  Split 1              PTSD_orig        28 (70%)            12 (30%)
#> 2  Split 1  symptom_3_6_7_8_11_16        22 (55%)            18 (45%)
#> 3  Split 1  symptom_6_7_8_9_15_16        20 (50%)            20 (50%)
#> 4  Split 1   symptom_3_6_7_8_9_11        20 (50%)            20 (50%)
#> 5  Split 2              PTSD_orig        26 (65%)            14 (35%)
#> 6  Split 2  symptom_6_7_8_9_15_16        22 (55%)            18 (45%)
#> 7  Split 2 symptom_6_7_8_15_16_17        18 (45%)            22 (55%)
#> 8  Split 2 symptom_6_7_9_14_15_16      23 (57.5%)          17 (42.5%)
#> 9  Split 3              PTSD_orig        36 (90%)             4 (10%)
#> 10 Split 3  symptom_3_6_7_8_11_16      29 (72.5%)          11 (27.5%)
#> 11 Split 3  symptom_6_7_8_9_15_16      29 (72.5%)          11 (27.5%)
#> 12 Split 3  symptom_2_6_7_8_15_16      27 (67.5%)          13 (32.5%)
#> 13 Split 4              PTSD_orig        34 (85%)             6 (15%)
#> 14 Split 4  symptom_3_6_7_8_11_16      27 (67.5%)          13 (32.5%)
#> 15 Split 4  symptom_6_7_8_9_15_16        26 (65%)            14 (35%)
#> 16 Split 4   symptom_3_6_7_8_9_16        24 (60%)            16 (40%)
#> 17 Split 5              PTSD_orig        30 (75%)            10 (25%)
#> 18 Split 5 symptom_3_6_7_11_13_17        18 (45%)            22 (55%)
#> 19 Split 5  symptom_3_6_7_8_11_15        22 (55%)            18 (45%)
#> 20 Split 5  symptom_3_6_7_8_11_16      27 (67.5%)          13 (32.5%)
#>    True Positive True Negative Newly Diagnosed Newly Non-Diagnosed True Cases
#> 1             28            12               0                   0         40
#> 2             19             9               3                   9         28
#> 3             19            11               1                   9         30
#> 4             19            11               1                   9         30
#> 5             26            14               0                   0         40
#> 6             19            11               3                   7         30
#> 7             15            11               3                  11         26
#> 8             18             9               5                   8         27
#> 9             36             4               0                   0         40
#> 10            28             3               1                   8         31
#> 11            29             4               0                   7         33
#> 12            27             4               0                   9         31
#> 13            34             6               0                   0         40
#> 14            24             3               3                  10         27
#> 15            24             4               2                  10         28
#> 16            21             3               3                  13         24
#> 17            30            10               0                   0         40
#> 18            17             9               1                  13         26
#> 19            20             8               2                  10         28
#> 20            25             8               2                   5         33
#>    False Cases Sensitivity Specificity    PPV    NPV combination_id rank
#> 1            0      1.0000      1.0000 1.0000 1.0000           <NA>   NA
#> 2           12      0.6786      0.7500 0.8636 0.5000  3_6_7_8_11_16    1
#> 3           10      0.6786      0.9167 0.9500 0.5500  6_7_8_9_15_16    2
#> 4           10      0.6786      0.9167 0.9500 0.5500   3_6_7_8_9_11    3
#> 5            0      1.0000      1.0000 1.0000 1.0000           <NA>   NA
#> 6           10      0.7308      0.7857 0.8636 0.6111  6_7_8_9_15_16    1
#> 7           14      0.5769      0.7857 0.8333 0.5000 6_7_8_15_16_17    2
#> 8           13      0.6923      0.6429 0.7826 0.5294 6_7_9_14_15_16    3
#> 9            0      1.0000      1.0000 1.0000 1.0000           <NA>   NA
#> 10           9      0.7778      0.7500 0.9655 0.2727  3_6_7_8_11_16    1
#> 11           7      0.8056      1.0000 1.0000 0.3636  6_7_8_9_15_16    2
#> 12           9      0.7500      1.0000 1.0000 0.3077  2_6_7_8_15_16    3
#> 13           0      1.0000      1.0000 1.0000 1.0000           <NA>   NA
#> 14          13      0.7059      0.5000 0.8889 0.2308  3_6_7_8_11_16    1
#> 15          12      0.7059      0.6667 0.9231 0.2857  6_7_8_9_15_16    2
#> 16          16      0.6176      0.5000 0.8750 0.1875   3_6_7_8_9_16    3
#> 17           0      1.0000      1.0000 1.0000 1.0000           <NA>   NA
#> 18          14      0.5667      0.9000 0.9444 0.4091 3_6_7_11_13_17    1
#> 19          12      0.6667      0.8000 0.9091 0.4444  3_6_7_8_11_15    2
#> 20           7      0.8333      0.8000 0.9259 0.6154  3_6_7_8_11_16    3

# View combinations that appeared multiple times
cv_results$without_clusters$combinations_summary
#> # A tibble: 3 × 15
#>   Scenario    combination_id Splits_Appeared Total_Diagnosed Total_Non_Diagnosed
#>   <chr>       <chr>                    <int> <chr>           <chr>              
#> 1 PTSD_orig   NA                           5 30.8 (77%)      9.2 (23%)          
#> 2 symptom_3_… 3_6_7_8_11_16                4 26.25 (65.62%)  13.75 (34.38%)     
#> 3 symptom_6_… 6_7_8_9_15_16                4 24.25 (60.62%)  15.75 (39.38%)     
#> # ℹ 10 more variables: True_Positive <dbl>, True_Negative <dbl>,
#> #   Newly_Diagnosed <dbl>, Newly_Non_Diagnosed <dbl>, True_Cases <dbl>,
#> #   False_Cases <dbl>, Sensitivity <dbl>, Specificity <dbl>, PPV <dbl>,
#> #   NPV <dbl>
# }
```
