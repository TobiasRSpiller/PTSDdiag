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
  n_top = 3
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

## Value

A list containing:

- without_clusters: Results for model without cluster representation

  - best_combinations: The `n_top` best symptom combinations from
    training

  - test_results: Diagnostic comparison on test data

  - summary: Formatted summary statistics

- with_clusters: Results for model with cluster representation

  - best_combinations: The `n_top` best symptom combinations from
    training

  - test_results: Diagnostic comparison on test data

  - summary: Formatted summary statistics

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

# Access results
validation_results$without_clusters$summary

{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4"],["PTSD_orig","symptom_2_6_7_9_15_16","symptom_6_7_9_14_15_16","symptom_2_6_7_8_15_16"],["52 (86.67%)","32 (53.33%)","34 (56.67%)","36 (60%)"],["8 (13.33%)","28 (46.67%)","26 (43.33%)","24 (40%)"],[52,31,34,35],[8,7,8,7],[0,1,0,1],[0,21,18,17],[60,38,42,42],[0,22,18,18],[1,0.5962,0.6538,0.6731],[1,0.875,1,0.875],[1,0.9688,1,0.9722],[1,0.25,0.3077,0.2917]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>Scenario<\/th>\n      <th>Total Diagnosed<\/th>\n      <th>Total Non-Diagnosed<\/th>\n      <th>True Positive<\/th>\n      <th>True Negative<\/th>\n      <th>Newly Diagnosed<\/th>\n      <th>Newly Non-Diagnosed<\/th>\n      <th>True Cases<\/th>\n      <th>False Cases<\/th>\n      <th>Sensitivity<\/th>\n      <th>Specificity<\/th>\n      <th>PPV<\/th>\n      <th>NPV<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":true,"columnDefs":[{"className":"dt-right","targets":[4,5,6,7,8,9,10,11,12,13]},{"orderable":false,"targets":0},{"name":" ","targets":0},{"name":"Scenario","targets":1},{"name":"Total Diagnosed","targets":2},{"name":"Total Non-Diagnosed","targets":3},{"name":"True Positive","targets":4},{"name":"True Negative","targets":5},{"name":"Newly Diagnosed","targets":6},{"name":"Newly Non-Diagnosed","targets":7},{"name":"True Cases","targets":8},{"name":"False Cases","targets":9},{"name":"Sensitivity","targets":10},{"name":"Specificity","targets":11},{"name":"PPV","targets":12},{"name":"NPV","targets":13}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}validation_results$with_clusters$summary

{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4"],["PTSD_orig","symptom_1_5_7_9_16_17","symptom_1_5_7_9_17_20","symptom_4_5_7_8_15_16"],["52 (86.67%)","12 (20%)","12 (20%)","18 (30%)"],["8 (13.33%)","48 (80%)","48 (80%)","42 (70%)"],[52,12,12,18],[8,8,8,8],[0,0,0,0],[0,40,40,34],[60,20,20,26],[0,40,40,34],[1,0.2308,0.2308,0.3462],[1,1,1,1],[1,1,1,1],[1,0.1667,0.1667,0.1905]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>Scenario<\/th>\n      <th>Total Diagnosed<\/th>\n      <th>Total Non-Diagnosed<\/th>\n      <th>True Positive<\/th>\n      <th>True Negative<\/th>\n      <th>Newly Diagnosed<\/th>\n      <th>Newly Non-Diagnosed<\/th>\n      <th>True Cases<\/th>\n      <th>False Cases<\/th>\n      <th>Sensitivity<\/th>\n      <th>Specificity<\/th>\n      <th>PPV<\/th>\n      <th>NPV<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":true,"columnDefs":[{"className":"dt-right","targets":[4,5,6,7,8,9,10,11,12,13]},{"orderable":false,"targets":0},{"name":" ","targets":0},{"name":"Scenario","targets":1},{"name":"Total Diagnosed","targets":2},{"name":"Total Non-Diagnosed","targets":3},{"name":"True Positive","targets":4},{"name":"True Negative","targets":5},{"name":"Newly Diagnosed","targets":6},{"name":"Newly Non-Diagnosed","targets":7},{"name":"True Cases","targets":8},{"name":"False Cases","targets":9},{"name":"Sensitivity","targets":10},{"name":"Specificity","targets":11},{"name":"PPV","targets":12},{"name":"NPV","targets":13}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}# }
```
