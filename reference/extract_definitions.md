# Extract portable symptom definitions from a comparison

Pulls the top symptom combinations of each optimized scenario out of a
[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
result and returns them as a compact, shareable object. Each definition
is described only by its symptom indices and the rule needed to apply it
(how many must be present, and whether cluster representation is
required), so the object contains no participant-level data and can be
shared across sites.

## Usage

``` r
extract_definitions(comparison, n = 5)
```

## Arguments

- comparison:

  A `ptsdiag_comparison` object from
  [`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md).

- n:

  Integer. Number of top combinations to keep per optimized scenario
  (default 5). Capped at the number available.

## Value

A named list (one element per optimized scenario). Each element is a
list with:

- `symptoms`: list of integer vectors (the top-`n` combinations).

- `n_required`: integer threshold for that scenario.

- `hierarchical`: logical, whether cluster representation is required.

## Details

For each `type = "optimize"` scenario in the comparison, the rule
(`n_required`, `hierarchical`) is read from `comparison$config`, so the
only thing the user supplies is how many combinations to carry per
scenario. Fixed scenarios (e.g. ICD-11) are skipped, because their
symptom set is published rather than derived.

The result pairs with
[`evaluate_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md):
extract the definitions from one sample, then evaluate them in any
sample.

## See also

[`evaluate_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md),
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
definitions <- extract_definitions(comp, n = 5)
lapply(definitions, function(d) d$symptoms)
#> $`4/6 Hierarchical`
#> $`4/6 Hierarchical`[[1]]
#> [1]  1  6  7 11 15 17
#> 
#> $`4/6 Hierarchical`[[2]]
#> [1]  1  6  7 11 15 18
#> 
#> $`4/6 Hierarchical`[[3]]
#> [1]  1  4  6  7 11 17
#> 
#> $`4/6 Hierarchical`[[4]]
#> [1]  1  5  6  7 11 17
#> 
#> $`4/6 Hierarchical`[[5]]
#> [1]  1  4  6 11 15 18
#> 
#> 
#> $`4/6 Non-hierarchical`
#> $`4/6 Non-hierarchical`[[1]]
#> [1]  5  6  7 10 13 20
#> 
#> $`4/6 Non-hierarchical`[[2]]
#> [1]  5  6  7 11 13 20
#> 
#> $`4/6 Non-hierarchical`[[3]]
#> [1]  6  7 10 13 15 18
#> 
#> $`4/6 Non-hierarchical`[[4]]
#> [1]  2  5  6  7 12 19
#> 
#> $`4/6 Non-hierarchical`[[5]]
#> [1]  2  6  7 11 12 19
#> 
#> 
#> $`3/6 Non-hierarchical`
#> $`3/6 Non-hierarchical`[[1]]
#> [1]  2  6  7  8 10 15
#> 
#> $`3/6 Non-hierarchical`[[2]]
#> [1]  2  6 10 11 15 16
#> 
#> $`3/6 Non-hierarchical`[[3]]
#> [1]  2  6 10 11 15 19
#> 
#> $`3/6 Non-hierarchical`[[4]]
#> [1]  6  7  8 10 11 19
#> 
#> $`3/6 Non-hierarchical`[[5]]
#> [1]  6  7  8 10 15 18
#> 
#> 
# }
```
