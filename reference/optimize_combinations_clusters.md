# Find optimal symptom combinations for diagnosis (hierarchical/cluster-based)

Identifies the best symptom combinations for PTSD diagnosis where a
specified number of symptoms must be present and must include at least
one symptom from each defined cluster. This maintains the hierarchical
structure of the diagnostic criteria while allowing configurable
parameters.

## Usage

``` r
optimize_combinations_clusters(
  data,
  n_symptoms = 6,
  n_required = 4,
  n_top = 3,
  score_by = "balanced_accuracy",
  clusters,
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
  Must be at least as large as the number of clusters.

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

- clusters:

  A named list of integer vectors defining the cluster structure. Each
  list element represents one cluster, with the integer vector
  specifying which symptom indices belong to that cluster. Cluster
  elements must not overlap. This parameter is required (no default).

  For PCL-5: `list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)`

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

## Details

The function:

1.  Generates valid combinations ensuring representation from all
    clusters

2.  Requires `n_required` symptoms to be present (\>=2 on original 0-4
    scale) for diagnosis

3.  Validates that present symptoms include at least one from each
    cluster

4.  Identifies the `n_top` combinations that best match the original
    DSM-5 diagnosis

The `clusters` parameter must be a named list specifying the cluster
structure. For PCL-5, the standard clusters are:

- Cluster B (Intrusion): Items 1-5

- Cluster C (Avoidance): Items 6-7

- Cluster D (Negative alterations in cognitions and mood): Items 8-14

- Cluster E (Alterations in arousal and reactivity): Items 15-20

Optimization can be based on:

- Maximizing balanced accuracy, the mean of sensitivity and specificity
  (the default)

- Minimizing false cases (both false positives and false negatives)

- Minimizing only false negatives (newly non-diagnosed cases)

## Examples

``` r
# Use a 250-row subset of the bundled data to keep the example fast
ptsd_data <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                                 id_col = c("patient_id", "age", "sex"))

# \donttest{
# Find best hierarchical combinations with PCL-5 clusters (a 5-symptom
# search keeps the example fast; the classic rule uses n_symptoms = 6,
# n_required = 4)
pcl5_clusters <- list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)
results <- optimize_combinations_clusters(ptsd_data, n_symptoms = 5,
             n_required = 3, score_by = "balanced_accuracy",
             clusters = pcl5_clusters)
#> ℹ Generated 3360 valid cluster-constrained combinations
#> Evaluating combinations ■■■■■■■■                          22% | ETA:  4s
#> Evaluating combinations ■■■■■■■■                          24% | ETA:  3s
#> Evaluating combinations ■■■■■■■■■■■■■■■■■■■■■■■■■■■■      91% | ETA:  0s
#> Evaluating combinations ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  100% | ETA:  0s
#> ℹ Evaluated 3360 combinations. Best: 1, 6, 7, 11, 17

# Get symptom numbers
results$best_symptoms
#> [[1]]
#> [1]  1  6  7 11 17
#> 
#> [[2]]
#> [1]  1  7 13 15 17
#> 
#> [[3]]
#> [1]  1  4  6 11 17
#> 

# View summary statistics
results$summary
#>               Scenario combination_id rank Total Diagnosed Total Non-Diagnosed
#> 1            PTSD_orig           <NA>   NA     232 (92.8%)           18 (7.2%)
#> 2  symptom_1_6_7_11_17    1_6_7_11_17    1     206 (82.4%)          44 (17.6%)
#> 3 symptom_1_7_13_15_17   1_7_13_15_17    2       205 (82%)            45 (18%)
#> 4  symptom_1_4_6_11_17    1_4_6_11_17    3       205 (82%)            45 (18%)
#>   True Positive True Negative Newly Diagnosed Newly Non-Diagnosed True Cases
#> 1           232            18               0                   0        250
#> 2           206            18               0                  26        224
#> 3           205            18               0                  27        223
#> 4           205            18               0                  27        223
#>   False Cases Sensitivity Specificity PPV    NPV Accuracy Balanced Accuracy
#> 1           0      1.0000           1   1 1.0000    1.000            1.0000
#> 2          26      0.8879           1   1 0.4091    0.896            0.9440
#> 3          27      0.8836           1   1 0.4000    0.892            0.9418
#> 4          27      0.8836           1   1 0.4000    0.892            0.9418
# }
```
