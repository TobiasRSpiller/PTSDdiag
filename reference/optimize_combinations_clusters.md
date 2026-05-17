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
  score_by = "false_cases",
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

  - "false_cases": Minimize total misclassifications

  - "newly_nondiagnosed": Minimize false negatives only

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

Optimization can be based on either:

- Minimizing false cases (both false positives and false negatives)

- Minimizing only false negatives (newly non-diagnosed cases)

## Examples

``` r
# Create example data
ptsd_data <- data.frame(matrix(sample(0:4, 200, replace=TRUE), ncol=20))
names(ptsd_data) <- paste0("symptom_", 1:20)

# \donttest{
# Find best hierarchical combinations with PCL-5 clusters
pcl5_clusters <- list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)
results <- optimize_combinations_clusters(ptsd_data, n_symptoms = 6,
             n_required = 4, score_by = "false_cases", clusters = pcl5_clusters)
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 1, 6, 8, 10, 17, 19 (7 additional tied)

# Get symptom numbers
results$best_symptoms
#> [[1]]
#> [1]  1  6  8 10 17 19
#> 
#> [[2]]
#> [1]  1  6  8 10 17 20
#> 
#> [[3]]
#> [1]  1  6 12 14 17 19
#> 

# View summary statistics
results$summary
#>                  Scenario  combination_id rank Total Diagnosed
#> 1               PTSD_orig            <NA>   NA         8 (80%)
#> 2  symptom_1_6_8_10_17_19  1_6_8_10_17_19    1         6 (60%)
#> 3  symptom_1_6_8_10_17_20  1_6_8_10_17_20    2         6 (60%)
#> 4 symptom_1_6_12_14_17_19 1_6_12_14_17_19    3         6 (60%)
#>   Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1             2 (20%)             8             2               0
#> 2             4 (40%)             6             2               0
#> 3             4 (40%)             6             2               0
#> 4             4 (40%)             6             2               0
#>   Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity PPV NPV
#> 1                   0         10           0        1.00           1   1 1.0
#> 2                   2          8           2        0.75           1   1 0.5
#> 3                   2          8           2        0.75           1   1 0.5
#> 4                   2          8           2        0.75           1   1 0.5
# }
```
