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
Sensitivity, Specificity, PPV, NPV, Accuracy, and Balanced Accuracy.

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
# Use a 250-row subset and a small 4-symptom search to keep the example
# fast; omit `scenarios` to run the three default rules
ptsd <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                            id_col = c("patient_id", "age", "sex"))
comp <- compare_optimizations(
  ptsd,
  scenarios = list(
    "3/4 Non-hierarchical" = list(n_symptoms = 4, n_required = 3,
                                  hierarchical = FALSE)
  ),
  n_top = 10, show_progress = FALSE
)
#> ℹ Evaluated 4845 combinations. Best: 6, 7, 12, 17
definitions <- extract_definitions(comp, n = 3)
evaluate_definitions(ptsd, definitions)
#>                              Scenario Total Diagnosed Total Non-Diagnosed
#> 1                           PTSD_orig     232 (92.8%)           18 (7.2%)
#> 2 3/4 Non-hierarchical (6, 7, 12, 17)     227 (90.8%)           23 (9.2%)
#> 3  3/4 Non-hierarchical (4, 6, 7, 12)     226 (90.4%)           24 (9.6%)
#> 4  3/4 Non-hierarchical (4, 6, 7, 19)       225 (90%)            25 (10%)
#> 5                              ICD-11     226 (90.4%)           24 (9.6%)
#>   True Positive True Negative Newly Diagnosed Newly Non-Diagnosed True Cases
#> 1           232            18               0                   0        250
#> 2           227            18               0                   5        245
#> 3           226            18               0                   6        244
#> 4           225            18               0                   7        243
#> 5           224            16               2                   8        240
#>   False Cases Sensitivity Specificity    PPV    NPV Accuracy Balanced Accuracy
#> 1           0      1.0000      1.0000 1.0000 1.0000    1.000            1.0000
#> 2           5      0.9784      1.0000 1.0000 0.7826    0.980            0.9892
#> 3           6      0.9741      1.0000 1.0000 0.7500    0.976            0.9871
#> 4           7      0.9698      1.0000 1.0000 0.7200    0.972            0.9849
#> 5          10      0.9655      0.8889 0.9912 0.6667    0.960            0.9272
# }
```
