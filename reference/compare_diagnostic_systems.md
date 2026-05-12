# Compare multiple diagnostic systems against DSM-5-TR

Produces a single unified summary table comparing the diagnostic
performance of multiple criteria against DSM-5-TR as the reference
standard. Suitable for use as a manuscript table (e.g., Table 2)
comparing optimized symptom combinations, ICD-11, and DSM-5-TR in one
[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)-ready output.

## Usage

``` r
compare_diagnostic_systems(data, ..., icd11 = TRUE, labels = NULL)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns of PCL-5 item scores (output
  of
  [`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)).
  Used to compute both the DSM-5-TR reference diagnosis and, when
  `icd11 = TRUE`, the ICD-11 diagnosis.

- ...:

  Zero or more comparison dataframes, each containing a `PTSD_orig`
  column and at least one additional logical column representing a
  diagnostic system (e.g. output of
  [`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)).
  All `PTSD_orig` columns must be identical to the one computed from
  `data`.

- icd11:

  Logical. If `TRUE` (default), compute the ICD-11 PTSD diagnosis from
  `data` and include it as a row in the output, labelled `"ICD-11"`. Set
  to `FALSE` to omit ICD-11.

- labels:

  Optional character vector of display names for the systems coming from
  `...`, in the order the columns appear across all `...` inputs
  (excluding `PTSD_orig` columns). Does not apply to the `"DSM-5-TR"` or
  `"ICD-11"` rows, which are always labelled automatically. If `NULL`
  (default), column names are used. A warning is issued if the length of
  `labels` does not match the number of systems and column names are
  used as a fallback.

## Value

A `data.frame` with one row per diagnostic system and the following
columns:

- `system`: Display name of the diagnostic criterion

- `n_diagnosed`: Number of cases meeting the criterion

- `pct_diagnosed`: Percentage of total sample diagnosed (2 dp)

- `sensitivity`: 4 dp

- `specificity`: 4 dp

- `ppv`: Positive predictive value, 4 dp

- `npv`: Negative predictive value, 4 dp

- `n_false_negative`: Cases missed vs. DSM-5-TR

- `pct_false_negative`: Percentage of total sample, 2 dp

- `n_false_positive`: Cases over-diagnosed vs. DSM-5-TR

- `pct_false_positive`: Percentage of total sample, 2 dp

- `n_misclassified`: Total misclassified cases

The DSM-5-TR reference row has sensitivity = specificity = 1.0000 and
all misclassification counts = 0 by definition.

## Details

The function:

1.  Computes the DSM-5-TR reference diagnosis (`PTSD_orig`) from `data`
    — this always appears as the first row in the output

2.  Optionally computes ICD-11 diagnosis from `data` when `icd11 = TRUE`

3.  Collects all non-`PTSD_orig` columns from the `...` comparison
    dataframes (e.g. output of
    [`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md))

4.  Validates that every `PTSD_orig` column in `...` is identical to the
    reference computed from `data`

5.  Calls
    [`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
    internally and reshapes the result into a presentation-ready table

Built-in display labels: `PTSD_orig` → `"DSM-5-TR"`, `PTSD_icd11` →
`"ICD-11"`. These are applied automatically. Use the `labels` argument
to rename the remaining systems.

## See also

[`create_icd11_diagnosis`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md)
for the ICD-11 comparison dataframe.

[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
for generating comparison dataframes from optimized symptom
combinations.

[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
and
[`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
for deriving optimal combinations.

## Examples

``` r
ptsd_data <- rename_ptsd_columns(simulated_ptsd)

# ICD-11 vs DSM-5-TR only (no optimized combinations)
tbl <- compare_diagnostic_systems(ptsd_data, icd11 = TRUE)
tbl
#>     system n_diagnosed pct_diagnosed sensitivity specificity    ppv    npv
#> 1 DSM-5-TR        4710         94.20      1.0000      1.0000 1.0000 1.0000
#> 2   ICD-11        4641         92.82      0.9781      0.8828 0.9927 0.7131
#>   n_false_negative pct_false_negative n_false_positive pct_false_positive
#> 1                0               0.00                0               0.00
#> 2              103               2.06               34               0.68
#>   n_misclassified
#> 1               0
#> 2             137

# \donttest{
# Add two pre-specified combinations
combos <- apply_symptom_combinations(
  ptsd_data,
  combinations = list(c(1, 6, 8, 10, 15, 19), c(2, 7, 9, 11, 16, 20)),
  n_required = 4
)
tbl2 <- compare_diagnostic_systems(
  ptsd_data, combos,
  icd11  = TRUE,
  labels = c("Combo A", "Combo B")
)
knitr::kable(tbl2)
#> 
#> 
#> |system   | n_diagnosed| pct_diagnosed| sensitivity| specificity|    ppv|    npv| n_false_negative| pct_false_negative| n_false_positive| pct_false_positive| n_misclassified|
#> |:--------|-----------:|-------------:|-----------:|-----------:|------:|------:|----------------:|------------------:|----------------:|------------------:|---------------:|
#> |DSM-5-TR |        4710|         94.20|      1.0000|      1.0000| 1.0000| 1.0000|                0|               0.00|                0|               0.00|               0|
#> |ICD-11   |        4641|         92.82|      0.9781|      0.8828| 0.9927| 0.7131|              103|               2.06|               34|               0.68|             137|
#> |Combo A  |        4669|         93.38|      0.9635|      0.5483| 0.9719| 0.4804|              172|               3.44|              131|               2.62|             303|
#> |Combo B  |        4646|         92.92|      0.9618|      0.6000| 0.9750| 0.4915|              180|               3.60|              116|               2.32|             296|
# }
```
