# Perform holdout validation for PTSD diagnostic models

Validates PTSD diagnostic models using a train-test split approach
(holdout validation). Trains the model on a portion of the data and
evaluates performance on the held-out test set.

## Usage

``` r
holdout_validation(
  data,
  train_ratio = 0.7,
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

- train_ratio:

  Numeric between 0 and 1 indicating proportion of data for training
  (default: 0.7 for 70/30 split)

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

  - best_combinations: The `n_top` best symptom combinations from
    training

  - test_results: Diagnostic comparison on test data

  - summary: Formatted summary statistics (data.frame or DT widget)

- with_clusters: Results for model with cluster representation

  - best_combinations: The `n_top` best symptom combinations from
    training

  - test_results: Diagnostic comparison on test data

  - summary: Formatted summary statistics (data.frame or DT widget)

## Details

The function:

1.  Splits data into training and test sets based on `train_ratio`

2.  Finds optimal symptom combinations on training data

3.  Evaluates these combinations on test data

4.  Compares results to original DSM-5 diagnoses

Two models are evaluated:

- Model without cluster representation: Any `n_required` of `n_symptoms`
  symptoms

- Model with cluster representation: `n_required` of `n_symptoms`
  symptoms with at least one from each cluster

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
# Perform holdout validation
validation_results <- holdout_validation(sample_data, train_ratio = 0.7)
#> ℹ Training on 140 observations, testing on 60
#> ℹ Evaluated 38760 combinations. Best: 2, 6, 7, 9, 15, 16
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 1, 5, 7, 9, 16, 17
#> ✔ Holdout validation complete

# Access results
validation_results$without_clusters$summary
#>                 Scenario combination_id rank Total Diagnosed
#> 1              PTSD_orig           <NA>   NA     52 (86.67%)
#> 2  symptom_2_6_7_9_15_16  2_6_7_9_15_16    1     32 (53.33%)
#> 3 symptom_6_7_9_14_15_16 6_7_9_14_15_16    2     34 (56.67%)
#> 4  symptom_2_6_7_8_15_16  2_6_7_8_15_16    3        36 (60%)
#>   Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1          8 (13.33%)            52             8               0
#> 2         28 (46.67%)            31             7               1
#> 3         26 (43.33%)            34             8               0
#> 4            24 (40%)            35             7               1
#>   Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity    PPV
#> 1                   0         60           0      1.0000       1.000 1.0000
#> 2                  21         38          22      0.5962       0.875 0.9688
#> 3                  18         42          18      0.6538       1.000 1.0000
#> 4                  17         42          18      0.6731       0.875 0.9722
#>      NPV
#> 1 1.0000
#> 2 0.2500
#> 3 0.3077
#> 4 0.2917
validation_results$with_clusters$summary
#>                Scenario combination_id rank Total Diagnosed Total Non-Diagnosed
#> 1             PTSD_orig           <NA>   NA     52 (86.67%)          8 (13.33%)
#> 2 symptom_1_5_7_9_16_17  1_5_7_9_16_17    1        12 (20%)            48 (80%)
#> 3 symptom_1_5_7_9_17_20  1_5_7_9_17_20    2        12 (20%)            48 (80%)
#> 4 symptom_4_5_7_8_15_16  4_5_7_8_15_16    3        18 (30%)            42 (70%)
#>   True Positive True Negative Newly Diagnosed Newly Non-Diagnosed True Cases
#> 1            52             8               0                   0         60
#> 2            12             8               0                  40         20
#> 3            12             8               0                  40         20
#> 4            18             8               0                  34         26
#>   False Cases Sensitivity Specificity PPV    NPV
#> 1           0      1.0000           1   1 1.0000
#> 2          40      0.2308           1   1 0.1667
#> 3          40      0.2308           1   1 0.1667
#> 4          34      0.3462           1   1 0.1905
# }
```
