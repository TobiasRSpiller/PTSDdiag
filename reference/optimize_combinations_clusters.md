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
  clusters
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

## Value

A list containing:

- best_symptoms: List of `n_top` vectors, each containing `n_symptoms`
  symptom numbers representing the best combinations found

- diagnosis_comparison: Dataframe comparing original DSM-5 diagnosis
  with diagnoses based on the best combinations

- summary: Interactive datatable (DT) showing diagnostic accuracy
  metrics for each combination

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

# Get symptom numbers
results$best_symptoms
#> [[1]]
#> [1]  4  6  8  9 15 20
#> 
#> [[2]]
#> [1]  4  6  8 10 15 20
#> 
#> [[3]]
#> [1]  4  6  8 14 15 20
#> 

# View summary statistics
results$summary

{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4"],["PTSD_orig","symptom_4_6_8_9_15_20","symptom_4_6_8_10_15_20","symptom_4_6_8_14_15_20"],["9 (90%)","7 (70%)","7 (70%)","7 (70%)"],["1 (10%)","3 (30%)","3 (30%)","3 (30%)"],[9,7,7,7],[1,1,1,1],[0,0,0,0],[0,2,2,2],[10,8,8,8],[0,2,2,2],[1,0.7778,0.7778,0.7778],[1,1,1,1],[1,1,1,1],[1,0.3333,0.3333,0.3333]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>Scenario<\/th>\n      <th>Total Diagnosed<\/th>\n      <th>Total Non-Diagnosed<\/th>\n      <th>True Positive<\/th>\n      <th>True Negative<\/th>\n      <th>Newly Diagnosed<\/th>\n      <th>Newly Non-Diagnosed<\/th>\n      <th>True Cases<\/th>\n      <th>False Cases<\/th>\n      <th>Sensitivity<\/th>\n      <th>Specificity<\/th>\n      <th>PPV<\/th>\n      <th>NPV<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":true,"columnDefs":[{"className":"dt-right","targets":[4,5,6,7,8,9,10,11,12,13]},{"orderable":false,"targets":0},{"name":" ","targets":0},{"name":"Scenario","targets":1},{"name":"Total Diagnosed","targets":2},{"name":"Total Non-Diagnosed","targets":3},{"name":"True Positive","targets":4},{"name":"True Negative","targets":5},{"name":"Newly Diagnosed","targets":6},{"name":"Newly Non-Diagnosed","targets":7},{"name":"True Cases","targets":8},{"name":"False Cases","targets":9},{"name":"Sensitivity","targets":10},{"name":"Specificity","targets":11},{"name":"PPV","targets":12},{"name":"NPV","targets":13}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}# }
```
