# Evaluate symptom definitions against a sample

Applies a set of pre-derived symptom definitions to a dataset and
returns a performance table scoring each one against that sample's full
DSM-5-TR diagnosis. Because it needs only the definitions (symptom
indices and rules) and a data frame, the same call can be run at a site
that never saw the data the definitions were derived from.

## Usage

``` r
evaluate_definitions(data, definitions, include_icd11 = TRUE)
```

## Arguments

- data:

  A dataframe with the 20 PCL-5 item columns `symptom_1` through
  `symptom_20` (output of
  [`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)).
  Additional carry-through columns are ignored.

- definitions:

  A named list of definitions, as returned by
  [`extract_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/extract_definitions.md).
  Each element must contain `symptoms` (a list of integer vectors),
  `n_required`, and `hierarchical`.

- include_icd11:

  Logical. If `TRUE` (default), append the ICD-11 criterion as a
  benchmark row.

## Value

A formatted performance table (see
[`create_readable_summary`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md)):
one row for the full DSM-5-TR reference, one per definition (labelled by
rule and symptom set), and one for ICD-11 when included. Includes
Sensitivity, Specificity, PPV, NPV, and Accuracy.

## Details

Each definition is applied with its own rule via
[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
(using the default PCL-5 clusters when `hierarchical = TRUE`). When
`include_icd11 = TRUE`, the ICD-11 criterion
([`create_icd11_diagnosis`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md))
is added as a fixed benchmark, computed locally on the supplied data.
Every definition is then scored against the full DSM-5-TR diagnosis with
[`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
and
[`create_readable_summary`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md).

## See also

[`extract_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/extract_definitions.md),
[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md).

## Examples

``` r
# \donttest{
ptsd <- rename_ptsd_columns(simulated_ptsd[1:300, ],
                            id_col = c("patient_id", "age", "sex"))
comp <- compare_optimizations(ptsd, n_top = 10, show_progress = FALSE)
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 1, 6, 7, 11, 15, 17 (3 additional tied)
#> ℹ Evaluated 38760 combinations. Best: 5, 6, 7, 10, 13, 20 (2 additional tied)
#> ℹ Evaluated 38760 combinations. Best: 2, 6, 7, 8, 10, 15 (8 additional tied)
definitions <- extract_definitions(comp, n = 3)
evaluate_definitions(ptsd, definitions)
#>                                       Scenario Total Diagnosed
#> 1                                    PTSD_orig    277 (92.33%)
#> 2       4/6 Hierarchical (1, 6, 7, 11, 15, 17)    250 (83.33%)
#> 3       4/6 Hierarchical (1, 6, 7, 11, 15, 18)    250 (83.33%)
#> 4        4/6 Hierarchical (1, 4, 6, 7, 11, 17)       252 (84%)
#> 5   4/6 Non-hierarchical (5, 6, 7, 10, 13, 20)    277 (92.33%)
#> 6   4/6 Non-hierarchical (5, 6, 7, 11, 13, 20)    277 (92.33%)
#> 7  4/6 Non-hierarchical (6, 7, 10, 13, 15, 18)    277 (92.33%)
#> 8    3/6 Non-hierarchical (2, 6, 7, 8, 10, 15)    283 (94.33%)
#> 9  3/6 Non-hierarchical (2, 6, 10, 11, 15, 16)       285 (95%)
#> 10 3/6 Non-hierarchical (2, 6, 10, 11, 15, 19)       285 (95%)
#> 11                                      ICD-11       270 (90%)
#>    Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1           23 (7.67%)           277            23               0
#> 2          50 (16.67%)           250            23               0
#> 3          50 (16.67%)           250            23               0
#> 4             48 (16%)           251            22               1
#> 5           23 (7.67%)           274            20               3
#> 6           23 (7.67%)           274            20               3
#> 7           23 (7.67%)           274            20               3
#> 8           17 (5.67%)           276            16               7
#> 9              15 (5%)           277            15               8
#> 10             15 (5%)           277            15               8
#> 11            30 (10%)           268            21               2
#>    Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity    PPV
#> 1                    0        300           0      1.0000      1.0000 1.0000
#> 2                   27        273          27      0.9025      1.0000 1.0000
#> 3                   27        273          27      0.9025      1.0000 1.0000
#> 4                   26        273          27      0.9061      0.9565 0.9960
#> 5                    3        294           6      0.9892      0.8696 0.9892
#> 6                    3        294           6      0.9892      0.8696 0.9892
#> 7                    3        294           6      0.9892      0.8696 0.9892
#> 8                    1        292           8      0.9964      0.6957 0.9753
#> 9                    0        292           8      1.0000      0.6522 0.9719
#> 10                   0        292           8      1.0000      0.6522 0.9719
#> 11                   9        289          11      0.9675      0.9130 0.9926
#>       NPV Accuracy
#> 1  1.0000   1.0000
#> 2  0.4600   0.9100
#> 3  0.4600   0.9100
#> 4  0.4583   0.9100
#> 5  0.8696   0.9800
#> 6  0.8696   0.9800
#> 7  0.8696   0.9800
#> 8  0.9412   0.9733
#> 9  1.0000   0.9733
#> 10 1.0000   0.9733
#> 11 0.7000   0.9633
# }
```
