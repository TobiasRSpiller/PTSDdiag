# Per-symptom inclusion counts across optimization scenarios

Returns a long-format data frame giving how often each of the 20 PCL-5
symptoms appears in the top combinations of each scenario in a
[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
result. This is the data source for
[`plot_symptom_frequency`](https://tobiasrspiller.github.io/PTSDdiag/reference/plot_symptom_frequency.md)
and matches the structure of the preprint's Supplementary Table S4.

## Usage

``` r
symptom_frequency(
  comparison,
  include_overall = TRUE,
  overall_includes_fixed = FALSE
)
```

## Arguments

- comparison:

  A `ptsdiag_comparison` object.

- include_overall:

  Logical. If `TRUE` (default), an `OVERALL` row is appended that pools
  across scenarios.

- overall_includes_fixed:

  Logical. If `TRUE`, fixed criteria contribute to the OVERALL row.
  Default `FALSE`.

## Value

A data.frame with columns `Symptom` (integer 1-20), `Approach` (factor
with levels in scenario order, optionally ending in `"OVERALL"`),
`Count` (integer), `RelFreq` (numeric in \\0, 1\\).

## Details

For optimize scenarios, `Count` ranges from 0 to `n_top` (the number of
stored combinations). For fixed scenarios such as ICD-11, the fixed
symptom set contributes exactly one combination so `Count` is either 0
or 1. `RelFreq` normalises `Count` by the number of combinations stored
in that scenario.

The optional `OVERALL` row pools counts across scenarios. By default
fixed scenarios are excluded from the OVERALL pool so that OVERALL
continues to reflect data-driven symptom selection. Set
`overall_includes_fixed = TRUE` to weight every combination equally.

## See also

[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md),
[`plot_symptom_frequency`](https://tobiasrspiller.github.io/PTSDdiag/reference/plot_symptom_frequency.md),
[`summarize_top_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md).

## Examples

``` r
# \donttest{
ptsd_data <- rename_ptsd_columns(simulated_ptsd)
comp <- compare_optimizations(ptsd_data, n_top = 5, show_progress = FALSE)
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 1, 6, 8, 11, 17, 19 (1 additional tied)
#> ℹ Evaluated 38760 combinations. Best: 6, 7, 9, 16, 17, 19
#> ℹ Evaluated 38760 combinations. Best: 5, 6, 7, 8, 10, 12
freq <- symptom_frequency(comp)
head(freq)
#>   Symptom         Approach Count RelFreq
#> 1       1 4/6 Hierarchical     5       1
#> 2       2 4/6 Hierarchical     0       0
#> 3       3 4/6 Hierarchical     0       0
#> 4       4 4/6 Hierarchical     0       0
#> 5       5 4/6 Hierarchical     0       0
#> 6       6 4/6 Hierarchical     5       1
# }
```
