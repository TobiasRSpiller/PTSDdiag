# Convert imported combination specifications into definitions

Converts one or more combination specifications – as returned by
[`read_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
– into the definitions list that
[`evaluate_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md)
expects. This is the validation-site counterpart of
[`extract_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/extract_definitions.md):
the derivation site exports each rule as a JSON file, and the validation
site turns the imported files into evaluable definitions in one call.

## Usage

``` r
as_definitions(specs, n_top = NULL)
```

## Arguments

- specs:

  A single combination specification (the list returned by
  [`read_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md),
  or any list with `combinations` and `n_required` elements), or a list
  of such specifications – e.g. `lapply(files, read_combinations)`. List
  names, when supplied, become the definition labels.

- n_top:

  Integer or `NULL` (default). When supplied, only the first `n_top`
  combinations of each specification (their stored rank order) are kept;
  capped at the number available.

## Value

A named list in the shape returned by
[`extract_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/extract_definitions.md):
one element per specification, each a list with `symptoms` (list of
integer vectors), `n_required`, `hierarchical`, and `clusters` (`NULL`
unless the specification stored a cluster structure). Pass it to
[`evaluate_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md).

## Details

Each definition is labelled by, in order of precedence: the name given
to the list element in `specs`; the `label` stored in the file by
[`write_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md);
or an automatic label of the form `"4/6 Hierarchical"` derived from the
rule (`n_required` / number of symptoms, hierarchical when the
specification carries a cluster structure). Duplicate labels are an
error – name the list elements to disambiguate.

A cluster structure stored in the specification is preserved in the
definition, so hierarchical rules exported with non-default clusters are
evaluated with exactly those clusters.

## See also

[`read_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md),
[`evaluate_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md),
[`extract_definitions`](https://tobiasrspiller.github.io/PTSDdiag/reference/extract_definitions.md).

## Examples

``` r
# A derivation site exports a rule ...
tmp <- tempfile(fileext = ".json")
write_combinations(list(c(1, 6, 8, 10, 15, 19), c(2, 7, 9, 11, 16, 20)),
                   tmp, n_required = 4, label = "4/6 Non-hierarchical")
#> ✔ Combinations written to /tmp/RtmpIP77bQ/file1b9520f3f0d.json

# ... and the validation site turns the imported file into definitions
spec <- read_combinations(tmp)
definitions <- as_definitions(spec, n_top = 2)
str(definitions)
#> List of 1
#>  $ 4/6 Non-hierarchical:List of 4
#>   ..$ symptoms    :List of 2
#>   .. ..$ : int [1:6] 1 6 8 10 15 19
#>   .. ..$ : int [1:6] 2 7 9 11 16 20
#>   ..$ n_required  : int 4
#>   ..$ hierarchical: logi FALSE
#>   ..$ clusters    : NULL

unlink(tmp)
```
