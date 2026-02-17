# Find optimal hierarchical six-symptom combinations for PTSD diagnosis

Convenience wrapper around
[`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
with the original PCL-5 defaults: 6 symptoms, 4 required, top 3
returned, and standard DSM-5 cluster structure.

Identifies the three best six-symptom combinations for PTSD diagnosis
where four symptoms must be present and must include at least one
symptom from each DSM-5 criterion cluster.

## Usage

``` r
analyze_best_six_symptoms_four_required_clusters(
  data,
  score_by = "false_cases"
)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns with PCL-5 item scores
  (output of rename_ptsd_columns). Each symptom should be scored on a
  0-4 scale where:

  - 0 = Not at all

  - 1 = A little bit

  - 2 = Moderately

  - 3 = Quite a bit

  - 4 = Extremely

- score_by:

  Character string specifying optimization criterion:

  - "false_cases": Minimize total misclassifications

  - "newly_nondiagnosed": Minimize false negatives only

## Value

A list containing:

- best_symptoms: List of three vectors, each containing six symptom
  numbers representing the best combinations found

- diagnosis_comparison: Dataframe comparing original DSM-5 diagnosis
  with diagnoses based on the three best combinations

- summary: Interactive datatable (DT) showing diagnostic accuracy
  metrics for each combination

## Details

The function:

1.  Generates valid combinations ensuring representation from all
    clusters

2.  Requires 4 symptoms to be present (\>=2 on original 0-4 scale) for
    diagnosis

3.  Validates that present symptoms include at least one from each
    cluster

4.  Identifies the three combinations that best match the original DSM-5
    diagnosis

DSM-5 PTSD symptom clusters:

- Cluster 1 (B) - Intrusion: Items 1-5

- Cluster 2 (C) - Avoidance: Items 6-7

- Cluster 3 (D) - Negative alterations in cognitions and mood: Items
  8-14

- Cluster 4 (E) - Alterations in arousal and reactivity: Items 15-20

Optimization can be based on either:

- Minimizing false cases (both false positives and false negatives)

- Minimizing only false negatives (newly non-diagnosed cases)

## See also

[`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
for the generalized version with configurable parameters and custom
cluster definitions.

## Examples

``` r
# Create example data
ptsd_data <- data.frame(matrix(sample(0:4, 200, replace=TRUE), ncol=20))
names(ptsd_data) <- paste0("symptom_", 1:20)

# \donttest{
# Find best hierarchical combinations minimizing false cases
results <- analyze_best_six_symptoms_four_required_clusters(ptsd_data, score_by = "false_cases")

# Get symptom numbers
results$best_symptoms
#> [[1]]
#> [1]  4  6  7 11 12 15
#> 
#> [[2]]
#> [1]  1  3  6  8 11 15
#> 
#> [[3]]
#> [1]  1  3  6  8 13 15
#> 

# View raw comparison data
results$diagnosis_comparison
#>    PTSD_orig symptom_4_6_7_11_12_15 symptom_1_3_6_8_11_15 symptom_1_3_6_8_13_15
#> 1       TRUE                   TRUE                  TRUE                  TRUE
#> 2       TRUE                  FALSE                 FALSE                 FALSE
#> 3       TRUE                   TRUE                 FALSE                 FALSE
#> 4       TRUE                   TRUE                  TRUE                  TRUE
#> 5      FALSE                  FALSE                 FALSE                 FALSE
#> 6      FALSE                  FALSE                 FALSE                 FALSE
#> 7       TRUE                   TRUE                  TRUE                  TRUE
#> 8       TRUE                   TRUE                  TRUE                  TRUE
#> 9       TRUE                   TRUE                  TRUE                  TRUE
#> 10      TRUE                   TRUE                  TRUE                  TRUE

# View summary statistics
results$summary

{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4"],["PTSD_orig","symptom_4_6_7_11_12_15","symptom_1_3_6_8_11_15","symptom_1_3_6_8_13_15"],["8 (80%)","7 (70%)","6 (60%)","6 (60%)"],["2 (20%)","3 (30%)","4 (40%)","4 (40%)"],[8,7,6,6],[2,2,2,2],[0,0,0,0],[0,1,2,2],[10,9,8,8],[0,1,2,2],[1,0.875,0.75,0.75],[1,1,1,1],[1,1,1,1],[1,0.6667,0.5,0.5]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>Scenario<\/th>\n      <th>Total Diagnosed<\/th>\n      <th>Total Non-Diagnosed<\/th>\n      <th>True Positive<\/th>\n      <th>True Negative<\/th>\n      <th>Newly Diagnosed<\/th>\n      <th>Newly Non-Diagnosed<\/th>\n      <th>True Cases<\/th>\n      <th>False Cases<\/th>\n      <th>Sensitivity<\/th>\n      <th>Specificity<\/th>\n      <th>PPV<\/th>\n      <th>NPV<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":true,"columnDefs":[{"className":"dt-right","targets":[4,5,6,7,8,9,10,11,12,13]},{"orderable":false,"targets":0},{"name":" ","targets":0},{"name":"Scenario","targets":1},{"name":"Total Diagnosed","targets":2},{"name":"Total Non-Diagnosed","targets":3},{"name":"True Positive","targets":4},{"name":"True Negative","targets":5},{"name":"Newly Diagnosed","targets":6},{"name":"Newly Non-Diagnosed","targets":7},{"name":"True Cases","targets":8},{"name":"False Cases","targets":9},{"name":"Sensitivity","targets":10},{"name":"Specificity","targets":11},{"name":"PPV","targets":12},{"name":"NPV","targets":13}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}# }
```
