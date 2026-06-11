# Rename PTSD symptom (= PCL-5 item) columns

Standardizes column names in PCL-5 (PTSD Checklist for DSM-5) data by
renaming them to a consistent format (symptom_1 through symptom_20).
This standardization is essential for subsequent analyses using other
functions in the package.

## Usage

``` r
rename_ptsd_columns(data, id_col = NULL)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns of PCL-5 item scores (plus
  any columns named in `id_col` for carry-through). The scores should be
  on a 0-4 scale where:

  - 0 = Not at all

  - 1 = A little bit

  - 2 = Moderately

  - 3 = Quite a bit

  - 4 = Extremely

- id_col:

  Optional character vector naming column(s) in `data` to preserve as
  identifiers. These columns are kept alongside the renamed symptom
  columns and propagate through the rest of the workflow
  ([`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md),
  [`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md),
  [`holdout_validation`](https://tobiasrspiller.github.io/PTSDdiag/reference/holdout_validation.md),
  [`cross_validation`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md)).
  Use them as a join key to merge per-row diagnoses back to the original
  dataframe (e.g. demographics). Defaults to `NULL` (no carry-through;
  all non-symptom columns are dropped).

## Value

A dataframe with PCL-5 columns renamed to `symptom_1` through
`symptom_20`. If `id_col` is supplied, the named columns are prepended
(in original order).

## Details

The function assumes the input data contains exactly 20 columns
corresponding to the 20 items of the PCL-5. The columns are renamed
sequentially from symptom_1 to symptom_20, maintaining their original
order. The PCL-5 items correspond to different symptom clusters:

- symptom_1 to symptom_5: Intrusion symptoms (Criterion B)

- symptom_6 to symptom_7: Avoidance symptoms (Criterion C)

- symptom_8 to symptom_14: Negative alterations in cognitions and mood
  (Criterion D)

- symptom_15 to symptom_20: Alterations in arousal and reactivity
  (Criterion E)

## Examples

``` r
# Example with a sample PCL-5 dataset
sample_data <- data.frame(
  matrix(sample(0:4, 20 * 10, replace = TRUE),
         nrow = 10,
         ncol = 20)
)
renamed_data <- rename_ptsd_columns(sample_data)
colnames(renamed_data)  # Shows new column names
#>  [1] "symptom_1"  "symptom_2"  "symptom_3"  "symptom_4"  "symptom_5" 
#>  [6] "symptom_6"  "symptom_7"  "symptom_8"  "symptom_9"  "symptom_10"
#> [11] "symptom_11" "symptom_12" "symptom_13" "symptom_14" "symptom_15"
#> [16] "symptom_16" "symptom_17" "symptom_18" "symptom_19" "symptom_20"

# Carry a participant identifier through the workflow
sample_data$patient_id <- sprintf("P%03d", seq_len(nrow(sample_data)))
with_id <- rename_ptsd_columns(sample_data, id_col = "patient_id")
head(with_id)
#>   patient_id symptom_1 symptom_2 symptom_3 symptom_4 symptom_5 symptom_6
#> 1       P001         0         2         3         1         3         0
#> 2       P002         4         3         2         2         2         1
#> 3       P003         0         1         2         0         1         1
#> 4       P004         1         4         0         2         2         2
#> 5       P005         2         4         4         1         3         4
#> 6       P006         0         1         4         3         2         4
#>   symptom_7 symptom_8 symptom_9 symptom_10 symptom_11 symptom_12 symptom_13
#> 1         0         2         2          3          0          2          0
#> 2         0         0         4          1          4          0          4
#> 3         2         0         0          1          4          2          1
#> 4         0         3         0          1          3          3          3
#> 5         3         3         1          3          4          2          4
#> 6         2         0         2          4          0          4          2
#>   symptom_14 symptom_15 symptom_16 symptom_17 symptom_18 symptom_19 symptom_20
#> 1          2          2          2          4          3          0          4
#> 2          4          3          3          4          3          2          1
#> 3          2          0          2          2          3          0          3
#> 4          0          4          4          1          3          3          3
#> 5          0          0          4          2          4          0          2
#> 6          0          0          2          2          2          0          0
```
