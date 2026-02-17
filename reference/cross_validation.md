# Perform k-fold cross-validation for PTSD diagnostic models

Validates PTSD diagnostic models using k-fold cross-validation to assess
generalization performance and identify stable symptom combinations.

## Usage

``` r
cross_validation(
  data,
  k = 5,
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

- k:

  Number of folds for cross-validation (default: 5)

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

  - fold_results: List of diagnostic comparisons for each fold

  - summary_by_fold: Detailed results for each fold

  - combinations_summary: Average performance for combinations appearing
    in multiple folds (NULL if no combinations repeat)

- with_clusters: Results for model with cluster representation

  - fold_results: List of diagnostic comparisons for each fold

  - summary_by_fold: Detailed results for each fold

  - combinations_summary: Average performance for combinations appearing
    in multiple folds (NULL if no combinations repeat)

## Details

The function:

1.  Splits data into k folds

2.  For each fold, trains on k-1 folds and tests on the held-out fold

3.  Identifies symptom combinations that appear across multiple folds

4.  Calculates average performance metrics for repeated combinations

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
# Perform 5-fold cross-validation
cv_results <- cross_validation(sample_data, k = 5)

# View summary for each fold
cv_results$without_clusters$summary_by_fold

{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20"],["Split 1","Split 1","Split 1","Split 1","Split 2","Split 2","Split 2","Split 2","Split 3","Split 3","Split 3","Split 3","Split 4","Split 4","Split 4","Split 4","Split 5","Split 5","Split 5","Split 5"],["PTSD_orig","symptom_3_6_7_8_11_16","symptom_6_7_8_9_15_16","symptom_3_6_7_8_9_11","PTSD_orig","symptom_6_7_8_9_15_16","symptom_6_7_8_15_16_17","symptom_6_7_9_14_15_16","PTSD_orig","symptom_3_6_7_8_11_16","symptom_6_7_8_9_15_16","symptom_2_6_7_8_15_16","PTSD_orig","symptom_3_6_7_8_11_16","symptom_6_7_8_9_15_16","symptom_3_6_7_8_9_16","PTSD_orig","symptom_3_6_7_11_13_17","symptom_3_6_7_8_11_15","symptom_3_6_7_8_11_16"],["28 (70%)","22 (55%)","20 (50%)","20 (50%)","26 (65%)","22 (55%)","18 (45%)","23 (57.5%)","36 (90%)","29 (72.5%)","29 (72.5%)","27 (67.5%)","34 (85%)","27 (67.5%)","26 (65%)","24 (60%)","30 (75%)","18 (45%)","22 (55%)","27 (67.5%)"],["12 (30%)","18 (45%)","20 (50%)","20 (50%)","14 (35%)","18 (45%)","22 (55%)","17 (42.5%)","4 (10%)","11 (27.5%)","11 (27.5%)","13 (32.5%)","6 (15%)","13 (32.5%)","14 (35%)","16 (40%)","10 (25%)","22 (55%)","18 (45%)","13 (32.5%)"],[28,19,19,19,26,19,15,18,36,28,29,27,34,24,24,21,30,17,20,25],[12,9,11,11,14,11,11,9,4,3,4,4,6,3,4,3,10,9,8,8],[0,3,1,1,0,3,3,5,0,1,0,0,0,3,2,3,0,1,2,2],[0,9,9,9,0,7,11,8,0,8,7,9,0,10,10,13,0,13,10,5],[40,28,30,30,40,30,26,27,40,31,33,31,40,27,28,24,40,26,28,33],[0,12,10,10,0,10,14,13,0,9,7,9,0,13,12,16,0,14,12,7],[1,0.6786,0.6786,0.6786,1,0.7308,0.5769,0.6923,1,0.7778,0.8056,0.75,1,0.7059,0.7059,0.6176,1,0.5667,0.6667,0.8333],[1,0.75,0.9167,0.9167,1,0.7857,0.7857,0.6429,1,0.75,1,1,1,0.5,0.6667,0.5,1,0.9,0.8,0.8],[1,0.8636,0.95,0.95,1,0.8636,0.8333,0.7826,1,0.9655,1,1,1,0.8889,0.9231,0.875,1,0.9444,0.9091,0.9258999999999999],[1,0.5,0.55,0.55,1,0.6111,0.5,0.5294,1,0.2727,0.3636,0.3077,1,0.2308,0.2857,0.1875,1,0.4091,0.4444,0.6153999999999999]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>Split<\/th>\n      <th>Scenario<\/th>\n      <th>Total Diagnosed<\/th>\n      <th>Total Non-Diagnosed<\/th>\n      <th>True Positive<\/th>\n      <th>True Negative<\/th>\n      <th>Newly Diagnosed<\/th>\n      <th>Newly Non-Diagnosed<\/th>\n      <th>True Cases<\/th>\n      <th>False Cases<\/th>\n      <th>Sensitivity<\/th>\n      <th>Specificity<\/th>\n      <th>PPV<\/th>\n      <th>NPV<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":true,"columnDefs":[{"className":"dt-right","targets":[5,6,7,8,9,10,11,12,13,14]},{"orderable":false,"targets":0},{"name":" ","targets":0},{"name":"Split","targets":1},{"name":"Scenario","targets":2},{"name":"Total Diagnosed","targets":3},{"name":"Total Non-Diagnosed","targets":4},{"name":"True Positive","targets":5},{"name":"True Negative","targets":6},{"name":"Newly Diagnosed","targets":7},{"name":"Newly Non-Diagnosed","targets":8},{"name":"True Cases","targets":9},{"name":"False Cases","targets":10},{"name":"Sensitivity","targets":11},{"name":"Specificity","targets":12},{"name":"PPV","targets":13},{"name":"NPV","targets":14}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}
# View combinations that appeared multiple times
cv_results$without_clusters$combinations_summary

{"x":{"filter":"none","vertical":false,"data":[["1","2","3"],["PTSD_orig","symptom_3_6_7_8_11_16","symptom_6_7_8_9_15_16"],[5,4,4],["30.8 (77%)","26.25 (65.62%)","24.25 (60.62%)"],["9.2 (23%)","13.75 (34.38%)","15.75 (39.38%)"],[30.8,24,22.75],[9.199999999999999,5.75,7.5],[0,2.25,1.5],[0,8,8.25],[40,29.75,30.25],[0,10.25,9.75],[1,0.75,0.7339],[1,0.7188,0.8333],[1,0.9143,0.9381],[1,0.4182,0.4762]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>Scenario<\/th>\n      <th>Splits_Appeared<\/th>\n      <th>Total_Diagnosed<\/th>\n      <th>Total_Non_Diagnosed<\/th>\n      <th>True_Positive<\/th>\n      <th>True_Negative<\/th>\n      <th>Newly_Diagnosed<\/th>\n      <th>Newly_Non_Diagnosed<\/th>\n      <th>True_Cases<\/th>\n      <th>False_Cases<\/th>\n      <th>Sensitivity<\/th>\n      <th>Specificity<\/th>\n      <th>PPV<\/th>\n      <th>NPV<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":true,"columnDefs":[{"className":"dt-right","targets":[2,5,6,7,8,9,10,11,12,13,14]},{"orderable":false,"targets":0},{"name":" ","targets":0},{"name":"Scenario","targets":1},{"name":"Splits_Appeared","targets":2},{"name":"Total_Diagnosed","targets":3},{"name":"Total_Non_Diagnosed","targets":4},{"name":"True_Positive","targets":5},{"name":"True_Negative","targets":6},{"name":"Newly_Diagnosed","targets":7},{"name":"Newly_Non_Diagnosed","targets":8},{"name":"True_Cases","targets":9},{"name":"False_Cases","targets":10},{"name":"Sensitivity","targets":11},{"name":"Specificity","targets":12},{"name":"PPV","targets":13},{"name":"NPV","targets":14}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}# }
```
