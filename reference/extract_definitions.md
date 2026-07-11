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
[`as_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/as_definitions.md)
for building the same object from combinations imported with
[`read_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md),
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
definitions <- extract_definitions(comp, n = 5)
lapply(definitions, function(d) d$symptoms)
#> $`3/4 Non-hierarchical`
#> $`3/4 Non-hierarchical`[[1]]
#> [1]  6  7 12 17
#> 
#> $`3/4 Non-hierarchical`[[2]]
#> [1]  4  6  7 12
#> 
#> $`3/4 Non-hierarchical`[[3]]
#> [1]  4  6  7 19
#> 
#> $`3/4 Non-hierarchical`[[4]]
#> [1]  6  7 12 13
#> 
#> $`3/4 Non-hierarchical`[[5]]
#> [1]  6  7 12 15
#> 
#> 
# }
```
