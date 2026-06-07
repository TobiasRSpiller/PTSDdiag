# Run multiple PTSD optimization scenarios in one call

Runs several optimization scenarios on the same dataset and bundles the
results into a single object suitable for tabular and visual comparison.
Reproduces the multi-scenario workflow used in the PTSDdiag preprint
(4/6 hierarchical, 4/6 non-hierarchical, 3/6 non-hierarchical) in one
call, and also supports adding fixed criteria such as ICD-11 to the
comparison.

## Usage

``` r
compare_optimizations(
  data,
  scenarios = NULL,
  include_icd11 = FALSE,
  n_top = 10,
  score_by = "accuracy",
  clusters = NULL,
  show_progress = TRUE
)
```

## Arguments

- data:

  A dataframe containing the 20 PCL-5 item columns `symptom_1` through
  `symptom_20` (output of
  [`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)).
  Non-symptom columns (e.g. a participant identifier) are carried
  through every scenario's per-row diagnosis output.

- scenarios:

  Optional named list of scenario configurations. Each element is a list
  with:

  - `type`: `"optimize"` (default if omitted) or `"fixed"`.

  - For `type = "optimize"`: `n_symptoms` (integer 1-20), `n_required`
    (integer 1-`n_symptoms`), `hierarchical` (single logical), and
    optional `clusters` (named list of integer vectors; defaults to
    PCL-5 B/C/D/E when `hierarchical = TRUE`).

  - For `type = "fixed"`: `criterion` – either a known string (`"icd11"`
    or `"caps5"`) or a logical vector of length `nrow(data)`
    representing a pre-computed diagnosis. When supplying a logical
    vector you must also provide `symptoms`, the integer indices counted
    as "included" in the heatmap.

  When `NULL` (default), runs the three preprint scenarios: 4/6
  hierarchical, 4/6 non-hierarchical, 3/6 non-hierarchical.

- include_icd11:

  Logical. When `TRUE`, appends an `"ICD-11"` fixed-criterion scenario
  after any user-supplied entries (deduplicated by label). Default
  `FALSE`.

- n_top:

  Integer. Number of top combinations to retain per optimize scenario
  (default 10). Fixed scenarios always contribute exactly one
  combination regardless of `n_top`.

- score_by:

  Character. Optimization criterion: `"accuracy"` (minimise FP + FN) or
  `"sensitivity"` (minimise FN only). Applied to optimize scenarios that
  do not override it. Default `"accuracy"`.

- clusters:

  Optional named list of integer vectors defining the PCL-5 clusters
  used by hierarchical optimize scenarios that do not specify their own.
  Defaults to the DSM-5 B/C/D/E grouping when needed.

- show_progress:

  Logical. Forwarded to each optimize scenario's progress bar. Default
  `TRUE`.

## Value

An object of class `ptsdiag_comparison`, a list with:

- `scenarios`: named list of per-scenario results. Each element mirrors
  the shape returned by
  [`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
  (`best_symptoms`, `diagnosis_comparison`, `summary`, `n_tied`) and
  carries a `type` attribute.

- `config`: data.frame with one row per scenario summarising the
  configuration used.

- `n_rows`: number of input rows.

- `call`: the matched call.

Pass the result to
[`summarize_top_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md)
for a manuscript-ready performance table, to
[`symptom_frequency`](https://tobiasrspiller.github.io/PTSDdiag/reference/symptom_frequency.md)
for the long-format symptom inclusion counts, and to
[`plot_symptom_frequency`](https://tobiasrspiller.github.io/PTSDdiag/reference/plot_symptom_frequency.md)
for the heatmap.

## Details

Each scenario is either:

- **optimize** (default): runs
  [`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
  or
  [`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
  depending on `hierarchical`. Returns the top `n_top` combinations.

- **fixed**: applies a pre-defined diagnostic criterion (such as ICD-11
  PTSD) and treats its fixed symptom set as a single "combination" for
  the purpose of the multi-scenario tables and heatmap.

Fixed scenarios let researchers benchmark optimized criteria against
published systems in a uniform output.

Any non-symptom columns present in `data` (e.g. an ID column added via
`rename_ptsd_columns(..., id_col = "patient_id")`) are carried through
to each scenario's per-row `diagnosis_comparison`, so per-participant
diagnoses can be joined back to demographics.

## See also

[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md),
[`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md),
[`create_icd11_diagnosis`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md),
[`summarize_top_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md),
[`symptom_frequency`](https://tobiasrspiller.github.io/PTSDdiag/reference/symptom_frequency.md),
[`plot_symptom_frequency`](https://tobiasrspiller.github.io/PTSDdiag/reference/plot_symptom_frequency.md).

## Examples

``` r
ptsd_data <- rename_ptsd_columns(simulated_ptsd,
                                  id_col = c("patient_id", "age", "sex"))
# \donttest{
# Three preprint scenarios + ICD-11 in one call
comp <- compare_optimizations(ptsd_data, n_top = 5, include_icd11 = TRUE,
                              show_progress = FALSE)
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 1, 6, 8, 11, 17, 19 (1 additional tied)
#> ℹ Evaluated 38760 combinations. Best: 6, 7, 9, 16, 17, 19
#> ℹ Evaluated 38760 combinations. Best: 5, 6, 7, 8, 10, 12
print(comp)
#> 
#> ── PTSDdiag multi-scenario comparison ──────────────────────────────────────────
#> Input rows: 5000.
#> Scenarios: 4.
#> 
#> • 4/6 Hierarchical [optimize]: best = 1, 6, 8, 11, 17, 19 (1 tied)
#> • 4/6 Non-hierarchical [optimize]: best = 6, 7, 9, 16, 17, 19
#> • 3/6 Non-hierarchical [optimize]: best = 5, 6, 7, 8, 10, 12
#> • ICD-11 [fixed]: symptoms 1, 2, 3, 6, 7, 16, 17

# Manuscript Table 2
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
#> 16               ICD-11    1             PTSD_icd11 4607 103  34 256
#>    Sensitivity Specificity      PPV      NPV
#> 1     87.32484    95.86207 99.70909 31.77143
#> 2     87.19745    97.93103 99.85412 32.01804
#> 3     87.15499    97.93103 99.85405 31.94601
#> 4     87.17622    97.24138 99.80554 31.82844
#> 5     87.28238    95.51724 99.68477 31.62100
#> 6     97.62208    72.41379 98.28987 65.21739
#> 7     97.68577    71.03448 98.20704 65.39683
#> 8     97.62208    71.37931 98.22687 64.89028
#> 9     97.89809    66.89655 97.96048 66.21160
#> 10    97.66454    70.68966 98.18570 65.07937
#> 11    99.55414    47.24138 96.84015 86.70886
#> 12    99.40552    48.27586 96.89570 83.33333
#> 13    99.51168    46.20690 96.77886 85.35032
#> 14    99.59660    44.82759 96.70171 87.24832
#> 15    99.70276    43.10345 96.60564 89.92806
#> 16    97.81316    88.27586 99.26740 71.30919
# }
```
