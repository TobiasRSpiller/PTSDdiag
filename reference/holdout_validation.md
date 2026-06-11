# Perform holdout validation for PTSD diagnostic models

Validates PTSD diagnostic models using a train-test split approach
(holdout validation). Trains the model on a portion of the data and
evaluates performance on the held-out test set.

## Usage

``` r
holdout_validation(
  data,
  train_ratio = 0.7,
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
  Each symptom should be scored on a 0-4 scale. Any additional
  non-symptom columns (e.g. an ID column passed via
  `rename_ptsd_columns(..., id_col = "patient_id")`) are carried through
  the train/test split and prepended to `test_results` so diagnoses can
  be joined back to the original dataframe.

- train_ratio:

  Numeric between 0 and 1 indicating proportion of data for training
  (default: 0.7 for 70/30 split)

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
# Use a 250-row subset of the bundled data to keep the example fast
ptsd_data <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                                 id_col = c("patient_id", "age", "sex"))

# \donttest{
# Validate a compact 3-of-5 definition (a 5-symptom search keeps the
# example fast; use n_symptoms = 6, n_required = 4 for the classic rule)
validation_results <- holdout_validation(ptsd_data, train_ratio = 0.7,
                                         n_symptoms = 5, n_required = 3)
#> ℹ Training on 175 observations, testing on 75
#> ℹ Evaluated 15504 combinations. Best: 4, 6, 7, 12, 16
#> ℹ Generated 3360 valid cluster-constrained combinations
#> Evaluating combinations ■■■■■■■■■■                        31% | ETA:  2s
#> Evaluating combinations ■■■■■■■■■■■■■■■■■■■■■■■■          76% | ETA:  1s
#> Evaluating combinations ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  100% | ETA:  0s
#> ℹ Evaluated 3360 combinations. Best: 1, 6, 7, 11, 17
#> ✔ Holdout validation complete

# Access results
validation_results$without_clusters$summary
#>               Scenario combination_id rank Total Diagnosed Total Non-Diagnosed
#> 1            PTSD_orig           <NA>   NA     73 (97.33%)           2 (2.67%)
#> 2  symptom_4_6_7_12_16    4_6_7_12_16    1        72 (96%)              3 (4%)
#> 3  symptom_4_6_7_11_16    4_6_7_11_16    2     74 (98.67%)           1 (1.33%)
#> 4 symptom_6_7_11_12_16   6_7_11_12_16    3     74 (98.67%)           1 (1.33%)
#>   True Positive True Negative Newly Diagnosed Newly Non-Diagnosed True Cases
#> 1            73             2               0                   0         75
#> 2            72             2               0                   1         74
#> 3            73             1               1                   0         74
#> 4            73             1               1                   0         74
#>   False Cases Sensitivity Specificity    PPV    NPV Accuracy Balanced Accuracy
#> 1           0      1.0000         1.0 1.0000 1.0000   1.0000            1.0000
#> 2           1      0.9863         1.0 1.0000 0.6667   0.9867            0.9932
#> 3           1      1.0000         0.5 0.9865 1.0000   0.9867            0.7500
#> 4           1      1.0000         0.5 0.9865 1.0000   0.9867            0.7500
validation_results$with_clusters$summary
#>              Scenario combination_id rank Total Diagnosed Total Non-Diagnosed
#> 1           PTSD_orig           <NA>   NA     73 (97.33%)           2 (2.67%)
#> 2 symptom_1_6_7_11_17    1_6_7_11_17    1     65 (86.67%)         10 (13.33%)
#> 3 symptom_1_6_7_11_18    1_6_7_11_18    2     61 (81.33%)         14 (18.67%)
#> 4 symptom_1_6_7_13_19    1_6_7_13_19    3     65 (86.67%)         10 (13.33%)
#>   True Positive True Negative Newly Diagnosed Newly Non-Diagnosed True Cases
#> 1            73             2               0                   0         75
#> 2            65             2               0                   8         67
#> 3            61             2               0                  12         63
#> 4            65             2               0                   8         67
#>   False Cases Sensitivity Specificity PPV    NPV Accuracy Balanced Accuracy
#> 1           0      1.0000           1   1 1.0000   1.0000            1.0000
#> 2           8      0.8904           1   1 0.2000   0.8933            0.9452
#> 3          12      0.8356           1   1 0.1429   0.8400            0.9178
#> 4           8      0.8904           1   1 0.2000   0.8933            0.9452
# }
```
