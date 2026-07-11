# Score every candidate symptom combination

Scores **every** candidate combination of `n_symptoms` PCL-5 items
against the full DSM-5-TR diagnosis and returns the complete ranked
table – not just the best ones. This is the exhaustive companion to
[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
/
[`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
(which keep only the top `n_top`): use it to study how performance
decays across the whole candidate set, e.g. to show that many symptom
sets are near-interchangeable (a plateau of near-optimal combinations
followed by a drop).

## Usage

``` r
score_all_combinations(
  data,
  n_symptoms = 6,
  n_required = 4,
  clusters = NULL,
  score_by = "balanced_accuracy",
  chunk_size = 1000,
  show_progress = TRUE
)
```

## Arguments

- data:

  A dataframe with the 20 PCL-5 item columns `symptom_1` through
  `symptom_20` (output of
  [`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)).
  Additional carry-through columns are ignored.

- n_symptoms:

  Integer. Number of items per combination (default 6).

- n_required:

  Integer. How many of the items must be present (score \>= 2) for a
  positive diagnosis (default 4).

- clusters:

  `NULL` (default) to score all subsets without a cluster constraint, or
  a named list of integer vectors (e.g.
  `list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)`) for the
  cluster-constrained candidate set and diagnosis rule.

- score_by:

  Character. Metric that defines the ranking: `"balanced_accuracy"`
  (default), `"accuracy"`, or `"sensitivity"`. All metrics are returned
  regardless; this only sets the sort order.

- chunk_size:

  Integer. Number of combinations scored per chunk (default 1000).
  Affects speed and parallel granularity only, never the result.

- show_progress:

  Logical. If `TRUE` (default), display a progress bar (sequential mode
  only).

## Value

A data.frame with one row per candidate combination, sorted
best-to-worst by `score_by` (ties broken by `combination_id` for
determinism):

- `rank`: 1 = best.

- `combination_id`: sorted item numbers joined by underscores (e.g.
  `"1_6_8_10_15_19"`).

- `tp`, `fn`, `fp`, `tn`: the 2x2 counts against the full DSM-5-TR
  diagnosis.

- `sensitivity`, `specificity`, `ppv`, `npv`, `accuracy`,
  `balanced_accuracy`: metrics on the 0-1 scale (`NA` where a
  denominator is zero).

The attributes `n_symptoms`, `n_required`, `clusters`, `score_by`, and
`n_combinations` record the configuration.

## Details

With `clusters = NULL`, all `choose(20, n_symptoms)` subsets are scored
(38,760 for six symptoms). With a cluster structure, only the
combinations containing at least one item per cluster are scored (13,685
six-symptom sets for the default PCL-5 clusters), and the diagnosis
additionally requires the present symptoms to span all clusters – the
same candidate set and rule as
[`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md).
The hierarchical per-row cluster check makes this mode noticeably
slower.

Combinations are processed in chunks. If the future.apply package is
installed and a `future` plan is set (e.g.
`future::plan(future::multisession)`), chunks are scored in parallel;
otherwise they are scored sequentially with a progress bar. Results are
identical either way.

The returned `combination_id` uses the same canonical format as
[`write_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md)
(sorted item numbers joined by underscores), so the full curve can be
joined against exported top-`k` combinations.

## See also

[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md),
[`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md),
[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md).

## Examples

``` r
# \donttest{
# A 4-symptom search on a 250-row subset keeps the example fast
ptsd_data <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                                 id_col = c("patient_id", "age", "sex"))
curve <- score_all_combinations(ptsd_data, n_symptoms = 4, n_required = 3,
                                show_progress = FALSE)
nrow(curve)     # choose(20, 4) = 4845 combinations, all ranked
#> [1] 4845
head(curve)
#>   rank combination_id  tp fn fp tn sensitivity specificity ppv       npv
#> 1    1      6_7_12_17 227  5  0 18   0.9784483           1   1 0.7826087
#> 2    2       4_6_7_12 226  6  0 18   0.9741379           1   1 0.7500000
#> 3    3       4_6_7_19 225  7  0 18   0.9698276           1   1 0.7200000
#> 4    4      6_7_12_13 225  7  0 18   0.9698276           1   1 0.7200000
#> 5    5      6_7_12_15 225  7  0 18   0.9698276           1   1 0.7200000
#> 6    6      6_7_12_18 225  7  0 18   0.9698276           1   1 0.7200000
#>   accuracy balanced_accuracy
#> 1    0.980         0.9892241
#> 2    0.976         0.9870690
#> 3    0.972         0.9849138
#> 4    0.972         0.9849138
#> 5    0.972         0.9849138
#> 6    0.972         0.9849138

# The full balanced-accuracy curve, e.g. for a rank plot:
# plot(curve$rank, curve$balanced_accuracy, type = "l", log = "x")
# }
```
