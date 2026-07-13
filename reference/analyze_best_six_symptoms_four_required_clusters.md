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
  score_by = "balanced_accuracy",
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

  - "balanced_accuracy": Maximise balanced accuracy, the mean of
    sensitivity and specificity. Robust when one diagnostic class is
    much more common than the other. Default.

  - "accuracy": Minimize total misclassifications (FP + FN, i.e.
    maximise overall accuracy).

  - "sensitivity": Minimize false negatives only (i.e. maximise
    sensitivity relative to the full DSM-5-TR diagnosis).

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

Optimization can be based on:

- Maximizing balanced accuracy, the mean of sensitivity and specificity
  (the default)

- Minimizing false cases (both false positives and false negatives)

- Minimizing only false negatives (newly non-diagnosed cases)

## See also

[`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
for the generalized version with configurable parameters and custom
cluster definitions.

## Examples

``` r
# This deprecated wrapper always runs the full 6-symptom hierarchical
# search, so its example uses a 50-row subset to stay fast
ptsd_data <- rename_ptsd_columns(simulated_ptsd[1:50, ],
                                 id_col = c("patient_id", "age", "sex"))

# \donttest{
# Find best hierarchical combinations with the default balanced-accuracy
# criterion
results <- analyze_best_six_symptoms_four_required_clusters(ptsd_data)
#> Warning: `analyze_best_six_symptoms_four_required_clusters()` was deprecated in PTSDdiag
#> 0.2.1.
#> ℹ Please use `optimize_combinations_clusters()` instead.
#> ℹ Generated 13685 valid cluster-constrained combinations
#> Evaluating combinations ■■■■■■■■                          24% | ETA:  3s
#> Evaluating combinations ■■■■■■■■■■■                       32% | ETA:  3s
#> Evaluating combinations ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  100% | ETA:  0s
#> ℹ Evaluated 13685 combinations. Best: 5, 6, 7, 11, 15, 16 (31 additional tied)

# Get symptom numbers
results$best_symptoms
#> [[1]]
#> [1]  5  6  7 11 15 16
#> 
#> [[2]]
#> [1]  5  6  7 11 15 20
#> 
#> [[3]]
#> [1]  5  6  7 13 15 16
#> 

# View raw comparison data
results$diagnosis_comparison
#>    patient_id age    sex PTSD_orig symptom_5_6_7_11_15_16
#> 1       P0001  48   male      TRUE                   TRUE
#> 2       P0002  29   male      TRUE                   TRUE
#> 3       P0003  44   male      TRUE                   TRUE
#> 4       P0004  41 female      TRUE                   TRUE
#> 5       P0005  34   male      TRUE                   TRUE
#> 6       P0006  18   male      TRUE                   TRUE
#> 7       P0007  33   male      TRUE                   TRUE
#> 8       P0008  30 female      TRUE                   TRUE
#> 9       P0009  43 female      TRUE                   TRUE
#> 10      P0010  36 female      TRUE                   TRUE
#> 11      P0011  37 female      TRUE                   TRUE
#> 12      P0012  33   male      TRUE                  FALSE
#> 13      P0013  39 female      TRUE                   TRUE
#> 14      P0014  39   male      TRUE                   TRUE
#> 15      P0015  18 female      TRUE                   TRUE
#> 16      P0016  58 female     FALSE                  FALSE
#> 17      P0017  49 female      TRUE                   TRUE
#> 18      P0018  45 female      TRUE                   TRUE
#> 19      P0019  32 female      TRUE                   TRUE
#> 20      P0020  50   male      TRUE                   TRUE
#> 21      P0021  38   male      TRUE                   TRUE
#> 22      P0022  40 female      TRUE                   TRUE
#> 23      P0023  25   male      TRUE                   TRUE
#> 24      P0024  60 female      TRUE                   TRUE
#> 25      P0025  43 female      TRUE                   TRUE
#> 26      P0026  65   male      TRUE                   TRUE
#> 27      P0027  63   male      TRUE                   TRUE
#> 28      P0028  43 female      TRUE                   TRUE
#> 29      P0029  50 female      TRUE                   TRUE
#> 30      P0030  63   male     FALSE                  FALSE
#> 31      P0031  36   male      TRUE                   TRUE
#> 32      P0032  44   male      TRUE                   TRUE
#> 33      P0033  39   male      TRUE                   TRUE
#> 34      P0034  46   male      TRUE                  FALSE
#> 35      P0035  44 female      TRUE                   TRUE
#> 36      P0036  56   male      TRUE                   TRUE
#> 37      P0037  49   male      TRUE                   TRUE
#> 38      P0038  31 female     FALSE                  FALSE
#> 39      P0039  49 female      TRUE                   TRUE
#> 40      P0040  32 female      TRUE                   TRUE
#> 41      P0041  28 female      TRUE                   TRUE
#> 42      P0042  51 female      TRUE                   TRUE
#> 43      P0043  28 female      TRUE                   TRUE
#> 44      P0044  46 female     FALSE                  FALSE
#> 45      P0045  32 female      TRUE                   TRUE
#> 46      P0046  59   male      TRUE                   TRUE
#> 47      P0047  51   male      TRUE                   TRUE
#> 48      P0048  37 female      TRUE                   TRUE
#> 49      P0049  52   male     FALSE                  FALSE
#> 50      P0050  47 female      TRUE                   TRUE
#>    symptom_5_6_7_11_15_20 symptom_5_6_7_13_15_16
#> 1                    TRUE                   TRUE
#> 2                    TRUE                   TRUE
#> 3                    TRUE                   TRUE
#> 4                    TRUE                   TRUE
#> 5                    TRUE                   TRUE
#> 6                    TRUE                   TRUE
#> 7                    TRUE                   TRUE
#> 8                    TRUE                   TRUE
#> 9                    TRUE                   TRUE
#> 10                   TRUE                   TRUE
#> 11                   TRUE                  FALSE
#> 12                  FALSE                   TRUE
#> 13                   TRUE                   TRUE
#> 14                   TRUE                   TRUE
#> 15                   TRUE                   TRUE
#> 16                  FALSE                  FALSE
#> 17                   TRUE                   TRUE
#> 18                   TRUE                   TRUE
#> 19                   TRUE                   TRUE
#> 20                   TRUE                   TRUE
#> 21                   TRUE                   TRUE
#> 22                   TRUE                   TRUE
#> 23                   TRUE                   TRUE
#> 24                   TRUE                   TRUE
#> 25                   TRUE                   TRUE
#> 26                   TRUE                   TRUE
#> 27                   TRUE                   TRUE
#> 28                   TRUE                   TRUE
#> 29                   TRUE                   TRUE
#> 30                  FALSE                  FALSE
#> 31                   TRUE                   TRUE
#> 32                   TRUE                   TRUE
#> 33                   TRUE                   TRUE
#> 34                  FALSE                  FALSE
#> 35                   TRUE                   TRUE
#> 36                   TRUE                   TRUE
#> 37                   TRUE                   TRUE
#> 38                  FALSE                  FALSE
#> 39                   TRUE                   TRUE
#> 40                   TRUE                   TRUE
#> 41                   TRUE                   TRUE
#> 42                   TRUE                   TRUE
#> 43                   TRUE                   TRUE
#> 44                  FALSE                  FALSE
#> 45                   TRUE                   TRUE
#> 46                   TRUE                   TRUE
#> 47                   TRUE                   TRUE
#> 48                   TRUE                   TRUE
#> 49                  FALSE                  FALSE
#> 50                   TRUE                   TRUE

# View summary statistics
results$summary
#>                 Scenario combination_id rank Total Diagnosed
#> 1              PTSD_orig           <NA>   NA        45 (90%)
#> 2 symptom_5_6_7_11_15_16 5_6_7_11_15_16    1        43 (86%)
#> 3 symptom_5_6_7_11_15_20 5_6_7_11_15_20    2        43 (86%)
#> 4 symptom_5_6_7_13_15_16 5_6_7_13_15_16    3        43 (86%)
#>   Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1             5 (10%)            45             5               0
#> 2             7 (14%)            43             5               0
#> 3             7 (14%)            43             5               0
#> 4             7 (14%)            43             5               0
#>   Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity PPV    NPV
#> 1                   0         50           0      1.0000           1   1 1.0000
#> 2                   2         48           2      0.9556           1   1 0.7143
#> 3                   2         48           2      0.9556           1   1 0.7143
#> 4                   2         48           2      0.9556           1   1 0.7143
#>   Accuracy Balanced Accuracy
#> 1     1.00            1.0000
#> 2     0.96            0.9778
#> 3     0.96            0.9778
#> 4     0.96            0.9778
# }
```
