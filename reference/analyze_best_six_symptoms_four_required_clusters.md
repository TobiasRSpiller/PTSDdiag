# Find optimal hierarchical six-symptom combinations for PTSD diagnosis

\`r lifecycle::badge("deprecated")\`

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
  score_by = "false_cases",
  DT = FALSE
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

- DT:

  Logical. If `TRUE`, return the summary as an interactive
  [`datatable`](https://rdrr.io/pkg/DT/man/datatable.html) widget. If
  `FALSE` (default), return a plain data.frame.

## Value

A list containing:

- best_symptoms: List of three vectors, each containing six symptom
  numbers representing the best combinations found

- diagnosis_comparison: Dataframe comparing original DSM-5 diagnosis
  with diagnoses based on the three best combinations

- summary: Diagnostic accuracy metrics for each combination. A
  data.frame by default, or an interactive
  [`datatable`](https://rdrr.io/pkg/DT/man/datatable.html) if
  `DT = TRUE`.

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
#> Warning: `analyze_best_six_symptoms_four_required_clusters()` was deprecated in PTSDdiag
#> 0.2.1.
#> ℹ Please use `optimize_combinations_clusters()` instead.
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 4, 6, 7, 11, 12, 15

# Get symptom numbers
results$best_symptoms
#> [[1]]
#> [1]  4  6  7 11 12 15
#> 
#> [[2]]
#> [1]  1  4  6  8 11 15
#> 
#> [[3]]
#> [1]  1  5  6  8 11 15
#> 

# View raw comparison data
results$diagnosis_comparison
#>    PTSD_orig symptom_4_6_7_11_12_15 symptom_1_4_6_8_11_15 symptom_1_5_6_8_11_15
#> 1       TRUE                   TRUE                  TRUE                  TRUE
#> 2       TRUE                   TRUE                  TRUE                  TRUE
#> 3       TRUE                  FALSE                 FALSE                 FALSE
#> 4       TRUE                   TRUE                 FALSE                 FALSE
#> 5       TRUE                   TRUE                  TRUE                  TRUE
#> 6      FALSE                  FALSE                 FALSE                 FALSE
#> 7      FALSE                  FALSE                 FALSE                 FALSE
#> 8       TRUE                   TRUE                  TRUE                  TRUE
#> 9       TRUE                   TRUE                  TRUE                  TRUE
#> 10      TRUE                   TRUE                  TRUE                  TRUE

# View summary statistics
results$summary
#>                 Scenario combination_id rank Total Diagnosed
#> 1              PTSD_orig           <NA>   NA         8 (80%)
#> 2 symptom_4_6_7_11_12_15 4_6_7_11_12_15    1         7 (70%)
#> 3  symptom_1_4_6_8_11_15  1_4_6_8_11_15    2         6 (60%)
#> 4  symptom_1_5_6_8_11_15  1_5_6_8_11_15    3         6 (60%)
#>   Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1             2 (20%)             8             2               0
#> 2             3 (30%)             7             2               0
#> 3             4 (40%)             6             2               0
#> 4             4 (40%)             6             2               0
#>   Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity PPV    NPV
#> 1                   0         10           0       1.000           1   1 1.0000
#> 2                   1          9           1       0.875           1   1 0.6667
#> 3                   2          8           2       0.750           1   1 0.5000
#> 4                   2          8           2       0.750           1   1 0.5000
# }
```
