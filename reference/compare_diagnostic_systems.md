# Compare multiple diagnostic systems against a reference standard

Produces a single unified summary table comparing the diagnostic
performance of multiple criteria against a chosen reference standard.
Suitable for use as a manuscript table comparing optimized symptom
combinations, ICD-11, CAPS-5, and DSM-5-TR in one
[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)-ready output.

## Usage

``` r
compare_diagnostic_systems(
  data,
  ...,
  icd11 = TRUE,
  caps5_data = NULL,
  reference = c("pcl5", "caps5"),
  labels = NULL
)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns of PCL-5 item scores (output
  of
  [`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)).
  Always required. Used to compute the PCL-5 DSM-5-TR diagnosis and,
  when `icd11 = TRUE`, the ICD-11 diagnosis.

- ...:

  Zero or more comparison dataframes, each containing a `PTSD_orig`
  column and at least one additional logical column representing a
  diagnostic system (e.g. output of
  [`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)).
  When `caps5_data` is `NULL`, all `PTSD_orig` columns must be identical
  to the one computed from `data`. When `caps5_data` is provided, only
  row counts are validated.

- icd11:

  Logical. If `TRUE` (default), compute the ICD-11 PTSD diagnosis from
  `data` and include it as a row in the output.

- caps5_data:

  Optional dataframe containing exactly 20 columns of CAPS-5 item
  severity scores (output of
  [`rename_caps5_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_caps5_columns.md)).
  Must have the same number of rows as `data` (paired participants).
  When provided, the CAPS-5 DSM-5-TR diagnosis is computed internally
  and included in the comparison.

- reference:

  Character. Which DSM-5-TR diagnosis serves as the reference standard:
  `"pcl5"` (default) or `"caps5"`. The reference row always has
  sensitivity = specificity = 1 and zero misclassifications. Setting
  `reference = "caps5"` requires `caps5_data` to be provided.

- labels:

  Optional character vector of display names for the systems coming from
  `...`, in the order the columns appear across all `...` inputs
  (excluding `PTSD_orig` columns). Does not apply to built-in rows
  (DSM-5-TR, ICD-11, CAPS-5), which are always labelled automatically.
  If `NULL` (default), column names are used. A warning is issued if the
  length does not match.

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

- `n_false_negative`: Cases missed vs. reference

- `pct_false_negative`: Percentage of total sample, 2 dp

- `n_false_positive`: Cases over-diagnosed vs. reference

- `pct_false_positive`: Percentage of total sample, 2 dp

- `n_misclassified`: Total misclassified cases

- `accuracy`: Proportion classified the same as the reference ((total -
  misclassified) / total), 4 dp

- `balanced_accuracy`: Mean of sensitivity and specificity
  ((sensitivity + specificity) / 2), 4 dp

## Details

The function:

1.  Computes the PCL-5 DSM-5-TR diagnosis from `data`

2.  If `caps5_data` is provided, computes the CAPS-5 DSM-5-TR diagnosis

3.  Sets the reference standard based on `reference`: either the PCL-5
    or CAPS-5 DSM-5-TR diagnosis. The reference row always appears first
    with sensitivity = specificity = 1.

4.  Optionally computes ICD-11 diagnosis from `data` when `icd11 = TRUE`

5.  Collects all non-`PTSD_orig` columns from the `...` comparison
    dataframes (e.g. output of
    [`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md))

6.  Calls
    [`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
    internally and reshapes the result into a presentation-ready table

When `caps5_data` is `NULL` (default), labels follow the original
convention: `"DSM-5-TR"` and `"ICD-11"`. When `caps5_data` is provided,
labels are disambiguated with the instrument name: `"DSM-5-TR (PCL-5)"`,
`"DSM-5-TR (CAPS-5)"`, `"ICD-11 (PCL-5)"`.

When `caps5_data` is provided, the strict `PTSD_orig` validation on
`...` inputs is relaxed to a row-count check only, because comparison
dataframes may have been derived from either the PCL-5 or CAPS-5 data
(which produce different `PTSD_orig` vectors).

## See also

[`create_icd11_diagnosis`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md)
for the ICD-11 comparison dataframe.

[`create_caps5_diagnosis`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_caps5_diagnosis.md)
for standalone CAPS-5 diagnosis.

[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
for generating comparison dataframes from optimized symptom
combinations.

[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
and
[`optimize_combinations_clusters`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
for deriving optimal combinations.

## Examples

``` r
ptsd_data <- rename_ptsd_columns(simulated_ptsd,
                                  id_col = c("patient_id", "age", "sex"))

# ICD-11 vs DSM-5-TR only (no optimized combinations)
tbl <- compare_diagnostic_systems(ptsd_data, icd11 = TRUE)
tbl
#>     system n_diagnosed pct_diagnosed sensitivity specificity    ppv    npv
#> 1 DSM-5-TR        4710         94.20      1.0000         1.0 1.0000 1.0000
#> 2   ICD-11        4578         91.56      0.9658         0.9 0.9937 0.6185
#>   n_false_negative pct_false_negative n_false_positive pct_false_positive
#> 1                0               0.00                0               0.00
#> 2              161               3.22               29               0.58
#>   n_misclassified accuracy balanced_accuracy
#> 1               0    1.000            1.0000
#> 2             190    0.962            0.9329

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
#> |system   | n_diagnosed| pct_diagnosed| sensitivity| specificity|    ppv|    npv| n_false_negative| pct_false_negative| n_false_positive| pct_false_positive| n_misclassified| accuracy| balanced_accuracy|
#> |:--------|-----------:|-------------:|-----------:|-----------:|------:|------:|----------------:|------------------:|----------------:|------------------:|---------------:|--------:|-----------------:|
#> |DSM-5-TR |        4710|         94.20|      1.0000|      1.0000| 1.0000| 1.0000|                0|               0.00|                0|               0.00|               0|   1.0000|            1.0000|
#> |ICD-11   |        4578|         91.56|      0.9658|      0.9000| 0.9937| 0.6185|              161|               3.22|               29|               0.58|             190|   0.9620|            0.9329|
#> |Combo A  |        4669|         93.38|      0.9635|      0.5483| 0.9719| 0.4804|              172|               3.44|              131|               2.62|             303|   0.9394|            0.7559|
#> |Combo B  |        4646|         92.92|      0.9618|      0.6000| 0.9750| 0.4915|              180|               3.60|              116|               2.32|             296|   0.9408|            0.7809|

# With CAPS-5 as gold standard reference
caps5_raw <- data.frame(matrix(sample(0:4, 20 * nrow(simulated_ptsd),
                                      replace = TRUE), ncol = 20))
caps5_data <- rename_caps5_columns(caps5_raw)
tbl3 <- compare_diagnostic_systems(
  ptsd_data, combos,
  icd11      = TRUE,
  caps5_data = caps5_data,
  reference  = "caps5"
)
knitr::kable(tbl3)
#> 
#> 
#> |system                 | n_diagnosed| pct_diagnosed| sensitivity| specificity|    ppv|    npv| n_false_negative| pct_false_negative| n_false_positive| pct_false_positive| n_misclassified| accuracy| balanced_accuracy|
#> |:----------------------|-----------:|-------------:|-----------:|-----------:|------:|------:|----------------:|------------------:|----------------:|------------------:|---------------:|--------:|-----------------:|
#> |DSM-5-TR (CAPS-5)      |        3902|         78.04|      1.0000|      1.0000| 1.0000| 1.0000|                0|               0.00|                0|               0.00|               0|   1.0000|            1.0000|
#> |DSM-5-TR (PCL-5)       |        4710|         94.20|      0.9421|      0.0583| 0.7805| 0.2207|              226|               4.52|             1034|              20.68|            1260|   0.7480|            0.5002|
#> |ICD-11 (PCL-5)         |        4578|         91.56|      0.9165|      0.0874| 0.7811| 0.2275|              326|               6.52|             1002|              20.04|            1328|   0.7344|            0.5019|
#> |symptom_1_6_8_10_15_19 |        4669|         93.38|      0.9346|      0.0692| 0.7811| 0.2296|              255|               5.10|             1022|              20.44|            1277|   0.7446|            0.5019|
#> |symptom_2_7_9_11_16_20 |        4646|         92.92|      0.9311|      0.0774| 0.7820| 0.2401|              269|               5.38|             1013|              20.26|            1282|   0.7436|            0.5042|
# }
```
