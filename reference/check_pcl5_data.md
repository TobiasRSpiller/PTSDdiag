# Check PCL-5 item data before starting the workflow

Pre-flight check for a data frame of PCL-5 item scores. Unlike the
fail-fast validation inside the workflow functions, this check runs
**all** checks and reports every problem at once – column count, numeric
type, the integer 0-4 scoring range, and missing values – so a data file
can be fixed in one pass instead of one error at a time. Run it on your
item columns before
[`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md).

## Usage

``` r
check_pcl5_data(data, id_col = NULL)
```

## Arguments

- data:

  A data frame containing the PCL-5 item columns (plus any columns named
  in `id_col`).

- id_col:

  Optional character vector naming identifier column(s) to exclude from
  the check, mirroring
  [`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md).

## Value

`invisible(TRUE)` when every check passes; otherwise the function aborts
with a report listing all failed checks.

## Details

Two input shapes are supported. If `data` already contains the renamed
columns `symptom_1` through `symptom_20`, those are checked by name
(extra columns such as `total` are ignored). Otherwise all non-`id_col`
columns are treated as the item columns in positional DSM-5 order,
exactly as
[`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)
will interpret them – the check then also requires that there are
exactly 20 of them.

Rows in which every item is 0 are reported as an informational note, not
an error: whether symptom-free records are kept (e.g. to contribute true
negatives in a validation sample) or excluded is an analytic choice.

## See also

[`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md),
which this check prepares for.

## Examples

``` r
# Clean data passes and reports each check
ptsd_items <- simulated_ptsd[1:100, paste0("S", 1:20)]
check_pcl5_data(ptsd_items)
#> ✔ Found exactly 20 non-ID columns; checking them positionally (DSM-5 item order
#>   assumed).
#> ✔ 100 rows.
#> ✔ All item columns are numeric.
#> ✔ No missing values.
#> ✔ All scores are integers between 0 and 4.
#> ✔ All checks passed -- data ready for the PTSDdiag workflow.

# A data frame with several problems reports them all in one error
bad <- ptsd_items
bad$extra_column <- 1          # 21 item columns
bad$S3[5] <- NA                # a missing value
bad$S7[2] <- 9                 # out of the 0-4 range
try(check_pcl5_data(bad))
#> Error in check_pcl5_data(bad) : 
#>   `data` is not ready for the PTSDdiag workflow.
#> ✖ Expected exactly 20 item columns after excluding `id_col`; got 21.
#> ✔ 100 rows.
#> ✔ All item columns are numeric.
#> ✖ 1 missing value in "S3" (first affected row: 5).
#> ✖ Column "S7" contains values outside the integer 0-4 range (e.g. 9).
```
