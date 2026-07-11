# Build a tidy comparison table of top combinations across scenarios

Produces a manuscript-ready table summarising the diagnostic performance
of each top combination (or fixed criterion) in a
[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
result. The output matches the layout of the PTSDdiag preprint's Table
2: one row per combination, with Approach / Rank / Combination / TP / FN
/ FP / TN / Sensitivity / Specificity / PPV / NPV / Accuracy / Balanced
Accuracy.

## Usage

``` r
summarize_top_combinations(comparison, top_n = NULL, as_percent = FALSE)
```

## Arguments

- comparison:

  A `ptsdiag_comparison` object.

- top_n:

  Optional integer. Per-scenario limit on combinations to include. Fixed
  scenarios always contribute exactly one row. Default `NULL` returns
  all stored combinations.

- as_percent:

  Logical. If `TRUE`, Sensitivity/Specificity/PPV/NPV/Accuracy/Balanced
  Accuracy are returned as percentages (0-100); otherwise as fractions
  (0-1). Default `FALSE`.

## Value

A data.frame with columns: `Approach`, `Rank`, `Combination`, `TP`,
`FN`, `FP`, `TN`, `Sensitivity`, `Specificity`, `PPV`, `NPV`,
`Accuracy`, `Balanced Accuracy`.

## Details

For each scenario, the per-row `diagnosis_comparison` dataframe is
summarised via
[`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md).
The self-comparison `PTSD_orig` row is dropped, the remaining rows are
renamed, and the scenario label is prepended.

Sensitivity, specificity, PPV, NPV, accuracy and balanced accuracy are
returned on the 0-1 fraction scale by default (matching
[`compare_diagnostic_systems`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md));
set `as_percent = TRUE` to convert to 0-100 for manuscript display.
Accuracy is `(TP + TN) / N`, the quantity maximised by
`score_by = "accuracy"`; balanced accuracy is
`(sensitivity + specificity) / 2`, the quantity maximised by the default
`score_by = "balanced_accuracy"`.

## See also

[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md),
[`symptom_frequency`](https://tobiasrspiller.github.io/PTSDdiag/reference/symptom_frequency.md),
[`plot_symptom_frequency`](https://tobiasrspiller.github.io/PTSDdiag/reference/plot_symptom_frequency.md).

## Examples

``` r
# \donttest{
# Use a 250-row subset and a small 4-symptom search to keep the example
# fast; omit `scenarios` to run the three default rules
ptsd_data <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                                 id_col = c("patient_id", "age", "sex"))
comp <- compare_optimizations(
  ptsd_data,
  scenarios = list(
    "3/4 Non-hierarchical" = list(n_symptoms = 4, n_required = 3,
                                  hierarchical = FALSE)
  ),
  include_icd11 = TRUE, n_top = 5, show_progress = FALSE
)
#> ℹ Evaluated 4845 combinations. Best: 6, 7, 12, 17
summarize_top_combinations(comp, as_percent = TRUE)
#>               Approach Rank       Combination  TP FN FP TN Sensitivity
#> 1 3/4 Non-hierarchical    1 symptom_6_7_12_17 227  5  0 18    97.84483
#> 2 3/4 Non-hierarchical    2  symptom_4_6_7_12 226  6  0 18    97.41379
#> 3 3/4 Non-hierarchical    3  symptom_4_6_7_19 225  7  0 18    96.98276
#> 4 3/4 Non-hierarchical    4 symptom_6_7_12_13 225  7  0 18    96.98276
#> 5 3/4 Non-hierarchical    5 symptom_6_7_12_15 225  7  0 18    96.98276
#> 6               ICD-11    1        PTSD_icd11 220 12  2 16    94.82759
#>   Specificity      PPV      NPV Accuracy Balanced Accuracy
#> 1   100.00000 100.0000 78.26087     98.0          98.92241
#> 2   100.00000 100.0000 75.00000     97.6          98.70690
#> 3   100.00000 100.0000 72.00000     97.2          98.49138
#> 4   100.00000 100.0000 72.00000     97.2          98.49138
#> 5   100.00000 100.0000 72.00000     97.2          98.49138
#> 6    88.88889  99.0991 57.14286     94.4          91.85824
# }
```
