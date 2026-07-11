# Evaluate symptom definitions against a sample

Applies a set of pre-derived symptom definitions to a dataset and
returns a performance table scoring each one against a reference
standard. By default the reference is the sample's own full DSM-5-TR
diagnosis; supply `reference` to score against an external standard
instead (e.g. a clinician CAPS diagnosis). Because it needs only the
definitions (symptom indices and rules) and a data frame, the same call
can be run at a site that never saw the data the definitions were
derived from.

## Usage

``` r
evaluate_definitions(
  data,
  definitions,
  include_icd11 = TRUE,
  reference = NULL,
  include_full_pcl5 = NULL,
  tidy = FALSE,
  as_percent = FALSE
)
```

## Arguments

- data:

  A dataframe with the 20 PCL-5 item columns `symptom_1` through
  `symptom_20` (output of
  [`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)).
  Additional carry-through columns are ignored (but may be named by
  `reference`).

- definitions:

  A named list of definitions, as returned by
  [`extract_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/extract_definitions.md)
  or
  [`as_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/as_definitions.md).
  Each element must contain `symptoms` (a list of integer vectors),
  `n_required`, and `hierarchical` (plus an optional `clusters`
  structure). A specification from
  [`read_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
  – or a list of them – is converted automatically via
  [`as_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/as_definitions.md).

- include_icd11:

  Logical. If `TRUE` (default), append the ICD-11 criterion as a
  benchmark row.

- reference:

  `NULL` (default) to score against the full DSM-5-TR PCL-5 diagnosis
  computed from `data`. Otherwise an external reference standard: a
  logical vector with one value per row, a 0/1-coded numeric vector, or
  a single string naming such a column in `data`. Missing values mark
  rows without a reference assessment; those rows are excluded (with a
  message).

- include_full_pcl5:

  Logical or `NULL` (default). Whether to add a `"Full 20-item PCL-5"`
  ceiling row. `NULL` resolves to `TRUE` exactly when `reference` is
  external (where the row is informative) and `FALSE` otherwise (where
  it would be a self-comparison).

- tidy:

  Logical. If `FALSE` (default), return the formatted display table (see
  [`create_readable_summary`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md)).
  If `TRUE`, return a plain analysis table matching
  [`summarize_top_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md):
  one row per evaluated rule with `Approach`, `Rank`, `Combination`, the
  2x2 counts, and numeric metrics – ready to filter, bind, or export
  without parsing labels.

- as_percent:

  Logical. Only with `tidy = TRUE`: if `TRUE`,
  Sensitivity/Specificity/PPV/NPV/Accuracy/Balanced Accuracy are
  returned as percentages (0-100) instead of fractions (0-1). Default
  `FALSE`.

## Value

With `tidy = FALSE`, a formatted performance table (see
[`create_readable_summary`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md)):
one row for the reference standard (labelled `PTSD_orig`), one per
definition (labelled by rule and symptom set), plus the optional
`"Full 20-item PCL-5"` and `"ICD-11"` rows.

With `tidy = TRUE`, a data.frame with columns `Approach`, `Rank` (the
combination's rank within its definition), `Combination`
(comma-separated PCL-5 item numbers; `NA` for the full-PCL-5 ceiling
row), `TP`, `FN`, `FP`, `TN`, `Sensitivity`, `Specificity`, `PPV`,
`NPV`, `Accuracy`, `Balanced Accuracy`. The reference self-comparison
row is omitted. The layout matches
[`summarize_top_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md),
so derivation and validation results can be combined with
[`rbind()`](https://rdrr.io/r/base/cbind.html).

## Details

Each definition is applied with its own rule via
[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
(using the definition's own cluster structure when present, otherwise
the default PCL-5 clusters, when `hierarchical = TRUE`). When
`include_icd11 = TRUE`, the ICD-11 criterion
([`create_icd11_diagnosis`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md))
is added as a fixed benchmark, computed locally on the supplied data.

With an external `reference`, rows with a missing reference value are
excluded from the evaluation (with a message reporting how many), and a
`"Full 20-item PCL-5"` ceiling row is added by default: the full
DSM-5-TR PCL-5 diagnosis scored against the same reference. This row
separates the cost of using a reduced symptom set from the intrinsic
disagreement between the PCL-5 and the external standard – no reduced
rule can be expected to exceed it.

## See also

[`extract_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/extract_definitions.md),
[`as_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/as_definitions.md),
[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md),
[`summarize_top_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md).

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

# Default: formatted table against the full DSM-5-TR PCL-5 diagnosis
evaluate_definitions(ptsd, definitions)
#>                              Scenario Total Diagnosed Total Non-Diagnosed
#> 1                           PTSD_orig     232 (92.8%)           18 (7.2%)
#> 2 3/4 Non-hierarchical (6, 7, 12, 17)     227 (90.8%)           23 (9.2%)
#> 3  3/4 Non-hierarchical (4, 6, 7, 12)     226 (90.4%)           24 (9.6%)
#> 4  3/4 Non-hierarchical (4, 6, 7, 19)       225 (90%)            25 (10%)
#> 5                              ICD-11     222 (88.8%)          28 (11.2%)
#>   True Positive True Negative Newly Diagnosed Newly Non-Diagnosed True Cases
#> 1           232            18               0                   0        250
#> 2           227            18               0                   5        245
#> 3           226            18               0                   6        244
#> 4           225            18               0                   7        243
#> 5           220            16               2                  12        236
#>   False Cases Sensitivity Specificity   PPV    NPV Accuracy Balanced Accuracy
#> 1           0      1.0000      1.0000 1.000 1.0000    1.000            1.0000
#> 2           5      0.9784      1.0000 1.000 0.7826    0.980            0.9892
#> 3           6      0.9741      1.0000 1.000 0.7500    0.976            0.9871
#> 4           7      0.9698      1.0000 1.000 0.7200    0.972            0.9849
#> 5          14      0.9483      0.8889 0.991 0.5714    0.944            0.9186

# Tidy analysis table (same layout as summarize_top_combinations())
evaluate_definitions(ptsd, definitions, tidy = TRUE)
#>               Approach Rank        Combination  TP FN FP TN Sensitivity
#> 1 3/4 Non-hierarchical    1       6, 7, 12, 17 227  5  0 18   0.9784483
#> 2 3/4 Non-hierarchical    2        4, 6, 7, 12 226  6  0 18   0.9741379
#> 3 3/4 Non-hierarchical    3        4, 6, 7, 19 225  7  0 18   0.9698276
#> 4               ICD-11    1 2, 3, 6, 7, 17, 18 220 12  2 16   0.9482759
#>   Specificity      PPV       NPV Accuracy Balanced Accuracy
#> 1   1.0000000 1.000000 0.7826087    0.980         0.9892241
#> 2   1.0000000 1.000000 0.7500000    0.976         0.9870690
#> 3   1.0000000 1.000000 0.7200000    0.972         0.9849138
#> 4   0.8888889 0.990991 0.5714286    0.944         0.9185824

# Against an external reference: the bundled general-population sample
# carries paired CAPS-5 items, standing in for a clinician diagnosis
gp   <- simulated_ptsd_genpop[1:400, ]
caps <- create_caps5_diagnosis(
  rename_caps5_columns(gp[, paste0("C", 1:20)])
)$PTSD_caps5
ptsd_gp <- rename_ptsd_columns(gp[, c("patient_id", paste0("S", 1:20))],
                               id_col = "patient_id")
ptsd_gp$caps <- caps
evaluate_definitions(ptsd_gp, definitions, reference = "caps", tidy = TRUE)
#>               Approach Rank        Combination TP FN FP  TN Sensitivity
#> 1 3/4 Non-hierarchical    1       6, 7, 12, 17 45 41 31 283   0.5232558
#> 2 3/4 Non-hierarchical    2        4, 6, 7, 12 45 41 30 284   0.5232558
#> 3 3/4 Non-hierarchical    3        4, 6, 7, 19 46 40 28 286   0.5348837
#> 4   Full 20-item PCL-5    1               <NA> 55 31 34 280   0.6395349
#> 5               ICD-11    1 2, 3, 6, 7, 17, 18 51 35 37 277   0.5930233
#>   Specificity       PPV       NPV Accuracy Balanced Accuracy
#> 1   0.9012739 0.5921053 0.8734568   0.8200         0.7122648
#> 2   0.9044586 0.6000000 0.8738462   0.8225         0.7138572
#> 3   0.9108280 0.6216216 0.8773006   0.8300         0.7228559
#> 4   0.8917197 0.6179775 0.9003215   0.8375         0.7656273
#> 5   0.8821656 0.5795455 0.8878205   0.8200         0.7375944
# }
```
