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
  score_by = "false_cases"
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

  - "false_cases": Minimize total misclassifications

  - "newly_nondiagnosed": Minimize false negatives only

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

1.  Tests all possible combinations of `n_symptoms` symptoms from the 20
    PCL-5 items

2.  Requires `n_required` symptoms to be present (\>=2 on original 0-4
    scale) for diagnosis

3.  Identifies the `n_top` combinations that best match the original
    DSM-5 diagnosis

Optimization can be based on either:

- Minimizing false cases (both false positives and false negatives)

- Minimizing only false negatives (newly non-diagnosed cases)

The symptom clusters in PCL-5 are:

- Items 1-5: Intrusion symptoms (Criterion B)

- Items 6-7: Avoidance symptoms (Criterion C)

- Items 8-14: Negative alterations in cognitions and mood (Criterion D)

- Items 15-20: Alterations in arousal and reactivity (Criterion E)

## Examples

``` r
# Create example data
ptsd_data <- data.frame(matrix(sample(0:4, 200, replace=TRUE), ncol=20))
names(ptsd_data) <- paste0("symptom_", 1:20)

# \donttest{
# Find best 6-symptom combinations requiring 4 present (classic defaults)
results <- optimize_combinations(ptsd_data, n_symptoms = 6, n_required = 4,
             score_by = "false_cases")

# Find best 5-symptom combinations requiring 3 present, return top 5
results2 <- optimize_combinations(ptsd_data, n_symptoms = 5, n_required = 3,
              n_top = 5, score_by = "false_cases")

# Get symptom numbers
results$best_symptoms
#> [[1]]
#> [1]  1  2  4  7 15 16
#> 
#> [[2]]
#> [1]  1  2  4  7 16 19
#> 
#> [[3]]
#> [1]  1  2  6  7  8 15
#> 

# View summary statistics
results$summary

{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4"],["PTSD_orig","symptom_1_2_4_7_15_16","symptom_1_2_4_7_16_19","symptom_1_2_6_7_8_15"],["5 (50%)","5 (50%)","5 (50%)","5 (50%)"],["5 (50%)","5 (50%)","5 (50%)","5 (50%)"],[5,5,5,5],[5,5,5,5],[0,0,0,0],[0,0,0,0],[10,10,10,10],[0,0,0,0],[1,1,1,1],[1,1,1,1],[1,1,1,1],[1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>Scenario<\/th>\n      <th>Total Diagnosed<\/th>\n      <th>Total Non-Diagnosed<\/th>\n      <th>True Positive<\/th>\n      <th>True Negative<\/th>\n      <th>Newly Diagnosed<\/th>\n      <th>Newly Non-Diagnosed<\/th>\n      <th>True Cases<\/th>\n      <th>False Cases<\/th>\n      <th>Sensitivity<\/th>\n      <th>Specificity<\/th>\n      <th>PPV<\/th>\n      <th>NPV<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":true,"columnDefs":[{"className":"dt-right","targets":[4,5,6,7,8,9,10,11,12,13]},{"orderable":false,"targets":0},{"name":" ","targets":0},{"name":"Scenario","targets":1},{"name":"Total Diagnosed","targets":2},{"name":"Total Non-Diagnosed","targets":3},{"name":"True Positive","targets":4},{"name":"True Negative","targets":5},{"name":"Newly Diagnosed","targets":6},{"name":"Newly Non-Diagnosed","targets":7},{"name":"True Cases","targets":8},{"name":"False Cases","targets":9},{"name":"Sensitivity","targets":10},{"name":"Specificity","targets":11},{"name":"PPV","targets":12},{"name":"NPV","targets":13}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}# }
```
