# Read symptom combinations from a JSON file

Imports symptom combinations from a JSON file previously created by
[`write_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md).
The returned list contains all fields needed to apply the combinations
to new data via
[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md).

## Usage

``` r
read_combinations(file)
```

## Arguments

- file:

  Character string. Path to the JSON file to read.

## Value

A named list with the following elements:

- combinations:

  List of numeric vectors. Each vector contains symptom indices for one
  combination.

- combination_ids:

  Character vector of canonical combination IDs (sorted symptom indices
  joined by underscores, e.g. `"4_6_7_17_19_20"`). Computed from the
  combinations if not present in the file (backward compatibility with
  files created before v0.2.1).

- ranks:

  Integer vector of ranks (1 = best). Computed from list position if not
  present in the file.

- n_required:

  Numeric. Number of symptoms required for a positive diagnosis.

- clusters:

  `NULL` for non-hierarchical combinations, or a named list of numeric
  vectors defining the cluster structure.

- parameters:

  Named list with additional metadata: `n_symptoms` and `score_by` (may
  be `NULL` if not recorded).

- description:

  Character string with the user-provided description.

- ptsddiag_version:

  Character string indicating which package version created the file.

- created_at:

  Character string with the creation timestamp.

The `combinations`, `n_required`, and `clusters` elements can be passed
directly to
[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md):

    spec <- read_combinations("my_combos.json")
    result <- apply_symptom_combinations(
      data, spec$combinations, spec$n_required, spec$clusters
    )

## Details

The function validates the imported data using the same checks as
[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md),
ensuring that the file contains valid combinations, a valid `n_required`
threshold, and (if present) a valid cluster structure.

If the file was created with a different version of PTSDdiag than the
one currently installed, an informational message is displayed.

## See also

[`write_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md)
to export combinations to a JSON file.

[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
to apply imported combinations to new data.

## Examples

``` r
# Write example combinations
my_combos <- list(
  c(1, 6, 8, 10, 15, 19),
  c(2, 7, 9, 11, 16, 20)
)
tmp <- tempfile(fileext = ".json")
write_combinations(my_combos, tmp, n_required = 4,
                   score_by = "false_cases")
#> Combinations written to /tmp/RtmpGlFb3Z/file1ca22192d599.json

# Read them back
spec <- read_combinations(tmp)
spec$combinations
#> [[1]]
#> [1]  1  6  8 10 15 19
#> 
#> [[2]]
#> [1]  2  7  9 11 16 20
#> 
spec$n_required
#> [1] 4

# Apply to data (example workflow)
# comparison <- apply_symptom_combinations(
#   new_data, spec$combinations, spec$n_required, spec$clusters
# )

# Clean up
unlink(tmp)
```
