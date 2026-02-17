# Apply pre-specified symptom combinations to new data

Applies one or more pre-specified symptom combinations to a new dataset
and returns a comparison dataframe with the baseline DSM-5 diagnosis and
the simplified diagnosis for each combination. This function enables
external validation by allowing combinations derived from one dataset to
be tested on another.

## Usage

``` r
apply_symptom_combinations(data, combinations, n_required = 4, clusters = NULL)
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

- combinations:

  A list of integer vectors. Each vector contains symptom indices (e.g.,
  `c(4, 6, 7, 17, 19, 20)`). All vectors must have the same length.
  Typically obtained from `results$best_symptoms` of an optimization
  run.

- n_required:

  Integer specifying how many symptoms must be present (scored \>= 2 on
  original scale) for a positive diagnosis (default: 4). Must be between
  1 and the length of each combination.

- clusters:

  `NULL` (default) for non-hierarchical checking, or a named list of
  integer vectors defining the cluster structure for hierarchical
  checking. When provided, a positive diagnosis additionally requires
  that the present symptoms span all defined clusters.

  For PCL-5: `list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)`

## Value

A dataframe with columns:

- `PTSD_orig`: Logical. Full DSM-5 diagnosis computed on this data.

- One column per combination (logical): Simplified diagnosis for each
  combination. Column names follow the `symptom_X_Y_Z` pattern.

This dataframe can be passed directly to
[`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
to compute diagnostic accuracy metrics.

## Details

The function:

1.  Computes the baseline DSM-5 diagnosis (`PTSD_orig`) on the provided
    data using binarized scores

2.  Binarizes the symptom data (scores \>= 2 become 1, others become 0)

3.  For each combination, determines diagnosis based on whether at least
    `n_required` symptoms are present

4.  If `clusters` is provided, additionally checks that present symptoms
    span all defined clusters (hierarchical checking)

5.  Returns a comparison dataframe suitable for
    [`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)

Typical workflow for external validation:

1.  Derive optimal combinations on Dataset A using
    [`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
    or
    [`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)

2.  Apply those combinations to Dataset B using this function

3.  Compute diagnostic metrics using
    [`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
    and
    [`create_readable_summary`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md)

## See also

[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
and
[`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
for deriving optimal combinations.

[`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
and
[`create_readable_summary`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md)
for computing and formatting diagnostic metrics from the returned
comparison dataframe.

## Examples

``` r
# Create example data
set.seed(42)
ptsd_data <- data.frame(matrix(sample(0:4, 400, replace=TRUE), ncol=20))
names(ptsd_data) <- paste0("symptom_", 1:20)

# Define some combinations to test
my_combinations <- list(
  c(1, 6, 8, 10, 15, 19),
  c(2, 7, 9, 11, 16, 20)
)

# Apply combinations (non-hierarchical)
comparison <- apply_symptom_combinations(ptsd_data, my_combinations,
                n_required = 4)

# Compute metrics
metrics <- summarize_ptsd_changes(comparison)
create_readable_summary(metrics)
#>                 Scenario Total Diagnosed Total Non-Diagnosed True Positive
#> 1              PTSD_orig        11 (55%)             9 (45%)            11
#> 2 symptom_1_6_8_10_15_19         9 (45%)            11 (55%)             8
#> 3 symptom_2_7_9_11_16_20         9 (45%)            11 (55%)             7
#>   True Negative Newly Diagnosed Newly Non-Diagnosed True Cases False Cases
#> 1             9               0                   0         20           0
#> 2             8               1                   3         16           4
#> 3             7               2                   4         14           6
#>   Sensitivity Specificity    PPV    NPV
#> 1      1.0000      1.0000 1.0000 1.0000
#> 2      0.7273      0.8889 0.8889 0.7273
#> 3      0.6364      0.7778 0.7778 0.6364

# Apply with hierarchical checking
pcl5_clusters <- list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)
hier_comparison <- apply_symptom_combinations(ptsd_data, my_combinations,
                     n_required = 4, clusters = pcl5_clusters)
summarize_ptsd_changes(hier_comparison)
#>                                        column diagnosed non_diagnosed
#> PTSD_orig                           PTSD_orig        11             9
#> symptom_1_6_8_10_15_19 symptom_1_6_8_10_15_19         1            19
#> symptom_2_7_9_11_16_20 symptom_2_7_9_11_16_20         3            17
#>                        newly_diagnosed newly_nondiagnosed true_positive
#> PTSD_orig                            0                  0            11
#> symptom_1_6_8_10_15_19               0                 10             1
#> symptom_2_7_9_11_16_20               0                  8             3
#>                        true_negative true_cases false_cases sensitivity
#> PTSD_orig                          9         20           0  1.00000000
#> symptom_1_6_8_10_15_19             9         10          10  0.09090909
#> symptom_2_7_9_11_16_20             9         12           8  0.27272727
#>                        specificity ppv       npv diagnosed_percent
#> PTSD_orig                        1   1 1.0000000                55
#> symptom_1_6_8_10_15_19           1   1 0.4736842                 5
#> symptom_2_7_9_11_16_20           1   1 0.5294118                15
#>                        non_diagnosed_percent
#> PTSD_orig                                 45
#> symptom_1_6_8_10_15_19                    95
#> symptom_2_7_9_11_16_20                    85
```
