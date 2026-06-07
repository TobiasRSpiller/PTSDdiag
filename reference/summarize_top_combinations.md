# Build a tidy comparison table of top combinations across scenarios

Produces a manuscript-ready table summarising the diagnostic performance
of each top combination (or fixed criterion) in a
[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
result. The output matches the layout of the PTSDdiag preprint's Table
2: one row per combination, with Approach / Rank / Combination / TP / FN
/ FP / TN / Sensitivity / Specificity / PPV / NPV / Accuracy.

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

  Logical. If `TRUE`, Sensitivity/Specificity/PPV/NPV/Accuracy are
  returned as percentages (0-100); otherwise as fractions (0-1). Default
  `FALSE`.

## Value

A data.frame with columns: `Approach`, `Rank`, `Combination`, `TP`,
`FN`, `FP`, `TN`, `Sensitivity`, `Specificity`, `PPV`, `NPV`,
`Accuracy`.

## Details

For each scenario, the per-row `diagnosis_comparison` dataframe is
summarised via
[`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md).
The self-comparison `PTSD_orig` row is dropped, the remaining rows are
renamed, and the scenario label is prepended.

Sensitivity, specificity, PPV, NPV and accuracy are returned on the 0-1
fraction scale by default (matching
[`compare_diagnostic_systems`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md));
set `as_percent = TRUE` to convert to 0-100 for manuscript display.
Accuracy is `(TP + TN) / N`, the quantity minimised by
`score_by = "accuracy"`.

## See also

[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md),
[`symptom_frequency`](https://tobiasrspiller.github.io/PTSDdiag/reference/symptom_frequency.md),
[`plot_symptom_frequency`](https://tobiasrspiller.github.io/PTSDdiag/reference/plot_symptom_frequency.md).

## Examples

``` r
# \donttest{
ptsd_data <- rename_ptsd_columns(simulated_ptsd,
                                  id_col = c("patient_id", "age", "sex"))
comp <- compare_optimizations(ptsd_data, n_top = 5, show_progress = FALSE)
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 1, 6, 8, 11, 17, 19 (1 additional tied)
#> ℹ Evaluated 38760 combinations. Best: 6, 7, 9, 16, 17, 19
#> ℹ Evaluated 38760 combinations. Best: 5, 6, 7, 8, 10, 12
summarize_top_combinations(comp, as_percent = TRUE)
#>                Approach Rank            Combination   TP  FN  FP  TN
#> 1      4/6 Hierarchical    1 symptom_1_6_8_11_17_19 4113 597  12 278
#> 2      4/6 Hierarchical    2 symptom_1_6_7_11_17_19 4107 603   6 284
#> 3      4/6 Hierarchical    3 symptom_1_6_7_11_17_20 4105 605   6 284
#> 4      4/6 Hierarchical    4 symptom_1_6_8_11_15_17 4106 604   8 282
#> 5      4/6 Hierarchical    5 symptom_1_6_8_11_17_20 4111 599  13 277
#> 6  4/6 Non-hierarchical    1 symptom_6_7_9_16_17_19 4598 112  80 210
#> 7  4/6 Non-hierarchical    2  symptom_4_6_7_9_17_19 4601 109  84 206
#> 8  4/6 Non-hierarchical    3  symptom_4_6_7_9_12_17 4598 112  83 207
#> 9  4/6 Non-hierarchical    4 symptom_4_6_7_15_17_19 4611  99  96 194
#> 10 4/6 Non-hierarchical    5  symptom_5_6_7_8_11_20 4600 110  85 205
#> 11 3/6 Non-hierarchical    1  symptom_5_6_7_8_10_12 4689  21 153 137
#> 12 3/6 Non-hierarchical    2   symptom_5_6_7_8_9_10 4682  28 150 140
#> 13 3/6 Non-hierarchical    3  symptom_4_6_7_8_11_14 4687  23 156 134
#> 14 3/6 Non-hierarchical    4  symptom_6_7_8_9_11_19 4691  19 160 130
#> 15 3/6 Non-hierarchical    5  symptom_6_7_8_9_11_20 4696  14 165 125
#>    Sensitivity Specificity      PPV      NPV Accuracy
#> 1     87.32484    95.86207 99.70909 31.77143    87.82
#> 2     87.19745    97.93103 99.85412 32.01804    87.82
#> 3     87.15499    97.93103 99.85405 31.94601    87.78
#> 4     87.17622    97.24138 99.80554 31.82844    87.76
#> 5     87.28238    95.51724 99.68477 31.62100    87.76
#> 6     97.62208    72.41379 98.28987 65.21739    96.16
#> 7     97.68577    71.03448 98.20704 65.39683    96.14
#> 8     97.62208    71.37931 98.22687 64.89028    96.10
#> 9     97.89809    66.89655 97.96048 66.21160    96.10
#> 10    97.66454    70.68966 98.18570 65.07937    96.10
#> 11    99.55414    47.24138 96.84015 86.70886    96.52
#> 12    99.40552    48.27586 96.89570 83.33333    96.44
#> 13    99.51168    46.20690 96.77886 85.35032    96.42
#> 14    99.59660    44.82759 96.70171 87.24832    96.42
#> 15    99.70276    43.10345 96.60564 89.92806    96.42
# }
```
