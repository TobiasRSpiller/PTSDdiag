# Rename CAPS-5 symptom columns

Standardizes column names in CAPS-5 (Clinician-Administered PTSD Scale
for DSM-5) data by renaming them to a consistent format (`symptom_1`
through `symptom_20`). This standardization allows CAPS-5 data to be
used with the same downstream functions as PCL-5 data (e.g.,
[`create_caps5_diagnosis`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_caps5_diagnosis.md),
[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)).

## Usage

``` r
rename_caps5_columns(data, id_col = NULL)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns of CAPS-5 item severity
  ratings (plus any columns named in `id_col` for carry-through). Scores
  are on a 0–4 scale where:

  - 0 = Absent

  - 1 = Mild / subthreshold

  - 2 = Moderate / threshold (counts toward diagnosis)

  - 3 = Severe / markedly elevated

  - 4 = Extreme / incapacitating

- id_col:

  Optional character vector naming column(s) in `data` to preserve as
  identifiers. These columns propagate through the workflow and can be
  used to merge per-row diagnoses back to the original dataframe.
  Defaults to `NULL`.

## Value

A dataframe with CAPS-5 columns renamed to `symptom_1` through
`symptom_20`. If `id_col` is supplied, the named columns are prepended
(in original order).

## Details

The function assumes the input data contains exactly 20 columns
corresponding to the 20 CAPS-5 items. Each item is a single severity
rating (0–4) assigned by the clinician, who combines information about
frequency and intensity into that score. The columns are renamed
sequentially from `symptom_1` to `symptom_20`, maintaining their
original order.

The CAPS-5 items map to the same DSM-5 PTSD symptom clusters as the
PCL-5:

- symptom_1 to symptom_5: Intrusion symptoms (Criterion B)

- symptom_6 to symptom_7: Avoidance symptoms (Criterion C)

- symptom_8 to symptom_14: Negative alterations in cognitions and mood
  (Criterion D)

- symptom_15 to symptom_20: Alterations in arousal and reactivity
  (Criterion E)

The output naming (`symptom_1:symptom_20`) is intentionally identical to
the PCL-5 convention so that downstream functions such as
[`apply_symptom_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
and
[`compare_diagnostic_systems`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
work transparently on CAPS-5 data.

## See also

[`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)
for the PCL-5 equivalent.

[`create_caps5_diagnosis`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_caps5_diagnosis.md)
for computing a CAPS-5 DSM-5 diagnosis from the renamed data.

## Examples

``` r
# Example with simulated CAPS-5 data
caps5_data <- data.frame(
  matrix(sample(0:4, 20 * 10, replace = TRUE),
         nrow = 10,
         ncol = 20)
)
renamed_caps5 <- rename_caps5_columns(caps5_data)
colnames(renamed_caps5)  # symptom_1 through symptom_20
#>  [1] "symptom_1"  "symptom_2"  "symptom_3"  "symptom_4"  "symptom_5" 
#>  [6] "symptom_6"  "symptom_7"  "symptom_8"  "symptom_9"  "symptom_10"
#> [11] "symptom_11" "symptom_12" "symptom_13" "symptom_14" "symptom_15"
#> [16] "symptom_16" "symptom_17" "symptom_18" "symptom_19" "symptom_20"
```
