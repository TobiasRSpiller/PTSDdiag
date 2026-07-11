# Find optimal symptom combinations for diagnosis (non-hierarchical)

Identifies the best symptom combinations for PTSD diagnosis where a
specified number of symptoms must be present, regardless of their
cluster membership. This is a generalized version that allows
configuring the number of symptoms per combination, the required
threshold, and how many top results to return.

## Usage

``` r
optimize_combinations(
  data,
  n_symptoms = 6,
  n_required = 4,
  n_top = 3,
  score_by = "balanced_accuracy",
  DT = FALSE,
  show_progress = TRUE
)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns with PCL-5 item scores
  (output of
  [`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)).
  Each symptom should be scored on a 0-4 scale where:

  - 0 = Not at all

  - 1 = A little bit

  - 2 = Moderately

  - 3 = Quite a bit

  - 4 = Extremely

- n_symptoms:

  Integer specifying how many symptoms per combination (default: 6).
  Must be between 1 and 20.

- n_required:

  Integer specifying how many symptoms must be present for diagnosis
  (default: 4). Must be between 1 and `n_symptoms`.

- n_top:

  Integer specifying how many top combinations to return (default: 3).
  Must be a positive integer.

- score_by:

  Character string specifying optimization criterion:

  - "balanced_accuracy": Maximise balanced accuracy, the mean of
    sensitivity and specificity. Robust when one diagnostic class is
    much more common than the other. Default.

  - "accuracy": Minimize total misclassifications (FP + FN, i.e.
    maximise overall accuracy).

  - "sensitivity": Minimize false negatives only (i.e. maximise
    sensitivity relative to the full DSM-5-TR diagnosis).

- DT:

  Logical. If `TRUE`, return the summary as an interactive
  [`datatable`](https://rdrr.io/pkg/DT/man/datatable.html) widget. If
  `FALSE` (default), return a plain data.frame. The DT package must be
  installed when `DT = TRUE`.

- show_progress:

  Logical. If `TRUE` (default), display a progress bar while evaluating
  combinations. Set to `FALSE` for batch or non-interactive use.

## Value

A list containing:

- best_symptoms: List of `n_top` vectors, each containing `n_symptoms`
  symptom numbers representing the best combinations found

- diagnosis_comparison: Dataframe comparing original DSM-5 diagnosis
  with diagnoses based on the best combinations. If `data` carried
  non-symptom columns (e.g. an ID column added via
  [`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)),
  those are prepended in original order.

- summary: Diagnostic accuracy metrics for each combination. A
  data.frame by default, or an interactive
  [`datatable`](https://rdrr.io/pkg/DT/man/datatable.html) if
  `DT = TRUE`.

- n_tied: Integer. Number of additional combinations that scored
  identically to the best combination but are not included in the top
  results. When `n_tied > 0`, the reported "best" combination is one of
  several equivalent solutions. Ties are broken by lexicographic order
  of symptom indices.

## Details

The function:

1.  Tests all possible combinations of `n_symptoms` symptoms from the 20
    PCL-5 items

2.  Requires `n_required` symptoms to be present (\>=2 on original 0-4
    scale) for diagnosis

3.  Identifies the `n_top` combinations that best match the original
    DSM-5 diagnosis

Optimization can be based on:

- Maximizing balanced accuracy, the mean of sensitivity and specificity
  (the default)

- Minimizing false cases (both false positives and false negatives)

- Minimizing only false negatives (newly non-diagnosed cases)

The symptom clusters in PCL-5 are:

- Items 1-5: Intrusion symptoms (Criterion B)

- Items 6-7: Avoidance symptoms (Criterion C)

- Items 8-14: Negative alterations in cognitions and mood (Criterion D)

- Items 15-20: Alterations in arousal and reactivity (Criterion E)

## Examples

``` r
# Use a 250-row subset of the bundled data to keep the example fast
ptsd_data <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                                 id_col = c("patient_id", "age", "sex"))

# \donttest{
# Find best 6-symptom combinations requiring 4 present (classic defaults,
# optimized for balanced accuracy)
results <- optimize_combinations(ptsd_data, n_symptoms = 6, n_required = 4,
             score_by = "balanced_accuracy")
#> Evaluating combinations ■■■■■■■■                          23% | ETA:  3s
#> Evaluating combinations ■■■■■■■■■■■■■■■■■■■■■■■■■         80% | ETA:  1s
#> Evaluating combinations ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  100% | ETA:  0s
#> ℹ Evaluated 38760 combinations. Best: 6, 7, 8, 11, 13, 17 (1 additional tied)

# Find best 5-symptom combinations requiring 3 present, return top 5,
# this time minimizing total misclassifications
results2 <- optimize_combinations(ptsd_data, n_symptoms = 5, n_required = 3,
              n_top = 5, score_by = "accuracy")
#> ℹ Evaluated 15504 combinations. Best: 3, 6, 7, 11, 15 (4 additional tied)

# Get symptom numbers
results$best_symptoms
#> [[1]]
#> [1]  6  7  8 11 13 17
#> 
#> [[2]]
#> [1]  6  7 10 11 13 15
#> 
#> [[3]]
#> [1]  4  6  7  8 11 17
#> 

# Check how many combinations tied with the best
results$n_tied
#> [1] 1

# View summary statistics
results$summary
#>                  Scenario  combination_id rank Total Diagnosed
#> 1               PTSD_orig            <NA>   NA     232 (92.8%)
#> 2  symptom_6_7_8_11_13_17  6_7_8_11_13_17    1       230 (92%)
#> 3 symptom_6_7_10_11_13_15 6_7_10_11_13_15    2       230 (92%)
#> 4   symptom_4_6_7_8_11_17   4_6_7_8_11_17    3     229 (91.6%)
#>   Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1           18 (7.2%)           232            18               0
#> 2             20 (8%)           229            17               1
#> 3             20 (8%)           229            17               1
#> 4           21 (8.4%)           228            17               1
#>   Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity    PPV
#> 1                   0        250           0      1.0000      1.0000 1.0000
#> 2                   3        246           4      0.9871      0.9444 0.9957
#> 3                   3        246           4      0.9871      0.9444 0.9957
#> 4                   4        245           5      0.9828      0.9444 0.9956
#>      NPV Accuracy Balanced Accuracy
#> 1 1.0000    1.000            1.0000
#> 2 0.8500    0.984            0.9658
#> 3 0.8500    0.984            0.9658
#> 4 0.8095    0.980            0.9636
# }
```
