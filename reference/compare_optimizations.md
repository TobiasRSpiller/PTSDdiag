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
  score_by = "balanced_accuracy",
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

  Character. Optimization criterion: `"balanced_accuracy"` (maximise the
  mean of sensitivity and specificity), `"accuracy"` (minimise FP + FN),
  or `"sensitivity"` (minimise FN only). Applied to optimize scenarios
  that do not override it. Default `"balanced_accuracy"`.

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
# Use a 250-row subset of the bundled data to keep the example fast
ptsd_data <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                                 id_col = c("patient_id", "age", "sex"))
# \donttest{
# A compact optimized rule plus ICD-11 (a small 4-symptom search keeps
# the example fast; omit `scenarios` to run the three default rules)
comp <- compare_optimizations(
  ptsd_data,
  scenarios = list(
    "3/4 Non-hierarchical" = list(n_symptoms = 4, n_required = 3,
                                  hierarchical = FALSE)
  ),
  include_icd11 = TRUE,
  n_top = 5,
  show_progress = FALSE
)
#> ℹ Evaluated 4845 combinations. Best: 6, 7, 12, 17
print(comp)
#> 
#> ── PTSDdiag multi-scenario comparison ──────────────────────────────────────────
#> Input rows: 250.
#> Scenarios: 2.
#> 
#> • 3/4 Non-hierarchical [optimize]: best = 6, 7, 12, 17
#> • ICD-11 [fixed]: symptoms 2, 3, 6, 7, 17, 18

# Manuscript Table 2
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
