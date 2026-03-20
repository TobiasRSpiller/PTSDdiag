# Find optimal non-hierarchical six-symptom combinations for PTSD diagnosis

\`r lifecycle::badge("deprecated")\`

Convenience wrapper around
[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
with the original PCL-5 defaults: 6 symptoms, 4 required, top 3
returned.

Identifies the three best six-symptom combinations for PTSD diagnosis
where any four symptoms must be present, regardless of their cluster
membership.

## Usage

``` r
analyze_best_six_symptoms_four_required(
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
#> Warning: `analyze_best_six_symptoms_four_required()` was deprecated in PTSDdiag 0.2.1.
#> ℹ Please use `optimize_combinations()` instead.
#> ℹ Evaluated 38760 combinations. Best: 1, 2, 3, 6, 11, 16

# Get symptom numbers
results$best_symptoms
#> [[1]]
#> [1]  1  2  3  6 11 16
#> 
#> [[2]]
#> [1]  1  2  3  8 11 13
#> 
#> [[3]]
#> [1]  1  2  3  8 11 16
#> 

# View raw comparison data
results$diagnosis_comparison
#>    PTSD_orig symptom_1_2_3_6_11_16 symptom_1_2_3_8_11_13 symptom_1_2_3_8_11_16
#> 1      FALSE                 FALSE                 FALSE                 FALSE
#> 2       TRUE                  TRUE                  TRUE                  TRUE
#> 3       TRUE                  TRUE                  TRUE                  TRUE
#> 4       TRUE                  TRUE                  TRUE                  TRUE
#> 5       TRUE                  TRUE                  TRUE                  TRUE
#> 6      FALSE                 FALSE                 FALSE                 FALSE
#> 7       TRUE                  TRUE                  TRUE                  TRUE
#> 8      FALSE                 FALSE                 FALSE                 FALSE
#> 9      FALSE                 FALSE                 FALSE                 FALSE
#> 10      TRUE                  TRUE                  TRUE                  TRUE

# View summary statistics
results$summary
#>                Scenario combination_id rank Total Diagnosed Total Non-Diagnosed
#> 1             PTSD_orig           <NA>   NA         6 (60%)             4 (40%)
#> 2 symptom_1_2_3_6_11_16  1_2_3_6_11_16    1         6 (60%)             4 (40%)
#> 3 symptom_1_2_3_8_11_13  1_2_3_8_11_13    2         6 (60%)             4 (40%)
#> 4 symptom_1_2_3_8_11_16  1_2_3_8_11_16    3         6 (60%)             4 (40%)
#>   True Positive True Negative Newly Diagnosed Newly Non-Diagnosed True Cases
#> 1             6             4               0                   0         10
#> 2             6             4               0                   0         10
#> 3             6             4               0                   0         10
#> 4             6             4               0                   0         10
#>   False Cases Sensitivity Specificity PPV NPV
#> 1           0           1           1   1   1
#> 2           0           1           1   1   1
#> 3           0           1           1   1   1
#> 4           0           1           1   1   1
# }
```
