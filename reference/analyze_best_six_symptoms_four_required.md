# Find optimal non-hierarchical six-symptom combinations for PTSD diagnosis

Convenience wrapper around
[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
with the original PCL-5 defaults: 6 symptoms, 4 required, top 3
returned.

Identifies the three best six-symptom combinations for PTSD diagnosis
where any four symptoms must be present, regardless of their cluster
membership.

## Usage

``` r
analyze_best_six_symptoms_four_required(data, score_by = "false_cases")
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

1.  Tests all possible combinations of 6 symptoms from the 20 PCL-5
    items

2.  Requires 4 symptoms to be present (\>=2 on original 0-4 scale) for
    diagnosis

3.  Identifies the three combinations that best match the original DSM-5
    diagnosis

Optimization can be based on either:

- Minimizing false cases (both false positives and false negatives)

- Minimizing only false negatives (newly non-diagnosed cases)

The symptom clusters in PCL-5 are:

- Items 1-5: Intrusion symptoms (Criterion B)

- Items 6-7: Avoidance symptoms (Criterion C)

- Items 8-14: Negative alterations in cognitions and mood (Criterion D)

- Items 15-20: Alterations in arousal and reactivity (Criterion E)

## See also

[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
for the generalized version with configurable parameters.

## Examples

``` r
# Create example data
ptsd_data <- data.frame(matrix(sample(0:4, 200, replace=TRUE), ncol=20))
names(ptsd_data) <- paste0("symptom_", 1:20)

# \donttest{
# Find best combinations minimizing false cases
results <- analyze_best_six_symptoms_four_required(ptsd_data, score_by = "false_cases")

# Get symptom numbers
results$best_symptoms
#> [[1]]
#> [1]  1  2  3  5  8 16
#> 
#> [[2]]
#> [1] 1 2 4 5 7 8
#> 
#> [[3]]
#> [1]  1  2  4  5  8 14
#> 

# View raw comparison data
results$diagnosis_comparison
#>    PTSD_orig symptom_1_2_3_5_8_16 symptom_1_2_4_5_7_8 symptom_1_2_4_5_8_14
#> 1       TRUE                 TRUE                TRUE                 TRUE
#> 2       TRUE                 TRUE                TRUE                 TRUE
#> 3       TRUE                 TRUE                TRUE                 TRUE
#> 4       TRUE                 TRUE                TRUE                 TRUE
#> 5      FALSE                FALSE               FALSE                FALSE
#> 6       TRUE                 TRUE                TRUE                 TRUE
#> 7      FALSE                FALSE               FALSE                FALSE
#> 8      FALSE                FALSE               FALSE                FALSE
#> 9       TRUE                 TRUE                TRUE                 TRUE
#> 10     FALSE                FALSE               FALSE                FALSE

# View summary statistics
results$summary

{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4"],["PTSD_orig","symptom_1_2_3_5_8_16","symptom_1_2_4_5_7_8","symptom_1_2_4_5_8_14"],["6 (60%)","6 (60%)","6 (60%)","6 (60%)"],["4 (40%)","4 (40%)","4 (40%)","4 (40%)"],[6,6,6,6],[4,4,4,4],[0,0,0,0],[0,0,0,0],[10,10,10,10],[0,0,0,0],[1,1,1,1],[1,1,1,1],[1,1,1,1],[1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>Scenario<\/th>\n      <th>Total Diagnosed<\/th>\n      <th>Total Non-Diagnosed<\/th>\n      <th>True Positive<\/th>\n      <th>True Negative<\/th>\n      <th>Newly Diagnosed<\/th>\n      <th>Newly Non-Diagnosed<\/th>\n      <th>True Cases<\/th>\n      <th>False Cases<\/th>\n      <th>Sensitivity<\/th>\n      <th>Specificity<\/th>\n      <th>PPV<\/th>\n      <th>NPV<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":true,"columnDefs":[{"className":"dt-right","targets":[4,5,6,7,8,9,10,11,12,13]},{"orderable":false,"targets":0},{"name":" ","targets":0},{"name":"Scenario","targets":1},{"name":"Total Diagnosed","targets":2},{"name":"Total Non-Diagnosed","targets":3},{"name":"True Positive","targets":4},{"name":"True Negative","targets":5},{"name":"Newly Diagnosed","targets":6},{"name":"Newly Non-Diagnosed","targets":7},{"name":"True Cases","targets":8},{"name":"False Cases","targets":9},{"name":"Sensitivity","targets":10},{"name":"Specificity","targets":11},{"name":"PPV","targets":12},{"name":"NPV","targets":13}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}# }
```
