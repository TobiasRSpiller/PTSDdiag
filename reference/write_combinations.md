# Write symptom combinations to a JSON file

Exports optimized symptom combinations to a human-readable JSON file.
This enables sharing of derived combinations across research groups
without needing to share raw data, supporting reproducible
derivation-validation workflows.

## Usage

``` r
write_combinations(
  combinations,
  file,
  n_required = 4,
  clusters = NULL,
  n_symptoms = NULL,
  score_by = NULL,
  description = ""
)
```

## Arguments

- combinations:

  A list of integer vectors specifying symptom combinations, or the full
  result object from
  [`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
  /
  [`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
  (which contains `$best_symptoms`).

- file:

  Character string. Path to the output JSON file.

- n_required:

  Integer specifying how many symptoms must be present for a positive
  diagnosis (default: 4). This value is stored in the file so that
  [`read_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
  can retrieve it.

- clusters:

  `NULL` (default) for non-hierarchical combinations, or a named list of
  integer vectors defining the cluster structure for hierarchical
  combinations. Stored in the file for use with
  [`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md).

- n_symptoms:

  Integer or `NULL`. Number of symptoms per combination. If `NULL`
  (default), inferred from the length of the first combination.

- score_by:

  Character or `NULL`. The scoring criterion used during optimization
  (`"false_cases"` or `"newly_nondiagnosed"`). Stored as metadata for
  reproducibility. If `NULL` (default), omitted from the file.

- description:

  Character string. Optional free-text description of the derivation
  context (e.g., sample characteristics, dataset name). Default is an
  empty string.

## Value

The file path (invisibly), following the convention of
[`write.csv`](https://rdrr.io/r/utils/write.table.html).

## Details

The JSON file contains the combinations alongside metadata needed to
apply them via
[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md):
the required symptom threshold (`n_required`) and optional cluster
structure (`clusters`). Additional fields (`score_by`, `n_symptoms`,
`description`) provide context for reproducibility.

The `combinations` argument can be either:

- A list of integer vectors (e.g., from `results$best_symptoms`)

- The full result object from
  [`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
  or
  [`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
  (the function automatically extracts `$best_symptoms`)

## See also

[`read_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
to import combinations from a JSON file.

[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
and
[`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
for deriving optimal combinations.

[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
for applying imported combinations to new data.

## Examples

``` r
# Create example combinations
my_combos <- list(
  c(1, 6, 8, 10, 15, 19),
  c(2, 7, 9, 11, 16, 20)
)

# Write to a temporary file
tmp <- tempfile(fileext = ".json")
write_combinations(my_combos, tmp, n_required = 4,
                   score_by = "false_cases",
                   description = "Example non-hierarchical combinations")
#> Combinations written to /tmp/RtmpGlFb3Z/file1ca2f124738.json

# Can also pass a full optimization result directly:
# write_combinations(optimization_result, tmp, n_required = 4)

# Clean up
unlink(tmp)
```
