# Apply ICD-11 PTSD diagnostic criteria to PCL-5 data

Applies ICD-11 PTSD diagnostic criteria to PCL-5 item scores and returns
a comparison dataframe against the full DSM-5-TR criteria. The output is
directly compatible with
[`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
so that ICD-11 diagnostic accuracy can be computed on the same footing
as optimized symptom combinations.

## Usage

``` r
create_icd11_diagnosis(data)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns of PCL-5 item scores (output
  of
  [`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)).
  Columns must be named `symptom_1` through `symptom_20`, scored on a
  0–4 scale, with no missing values.

## Value

A `data.frame` with two logical columns and one row per participant:

- `PTSD_orig`: DSM-5-TR diagnosis (reference standard)

- `PTSD_icd11`: ICD-11 diagnosis

Any carry-through columns present in `data` (e.g. an ID column added via
[`rename_ptsd_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md))
are prepended in original order so results can be joined back to the
source dataframe.

This dataframe can be passed directly to
[`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
or used as an input to
[`compare_diagnostic_systems`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md).

## Details

ICD-11 PTSD requires ALL THREE of the following clusters to be met
(symptom present = score \\\ge\\ 2 on original 0–4 scale):

1.  **Re-experiencing** (in the present): \\\ge\\ 1 of PCL-5 items 1, 2,
    3 (intrusive memories, nightmares, flashbacks)

2.  **Avoidance**: \\\ge\\ 1 of PCL-5 items 6, 7

3.  **Sense of current threat**: \\\ge\\ 1 of PCL-5 items 16, 17
    (hypervigilance, exaggerated startle)

A minimum of 3 symptoms total across all ICD-11 items (1, 2, 3, 6, 7,
16, 17) must be present. This is automatically satisfied when all three
cluster requirements are met but is enforced explicitly for clarity.

DSM-5-TR diagnosis (`PTSD_orig`) is computed using the same binarization
logic as the rest of the package
([`create_ptsd_diagnosis_binarized`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_ptsd_diagnosis_binarized.md)).

## See also

[`compare_diagnostic_systems`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
for a unified cross-system comparison table.

[`summarize_ptsd_changes`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)
and
[`create_readable_summary`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_readable_summary.md)
for computing and formatting diagnostic metrics.

## Examples

``` r
# Apply ICD-11 criteria to the built-in simulated dataset
ptsd_data <- rename_ptsd_columns(simulated_ptsd)
icd11_result <- create_icd11_diagnosis(ptsd_data)
head(icd11_result)
#>   PTSD_orig PTSD_icd11
#> 1      TRUE       TRUE
#> 2      TRUE       TRUE
#> 3      TRUE      FALSE
#> 4      TRUE       TRUE
#> 5      TRUE       TRUE
#> 6      TRUE       TRUE

# Feed directly into the metrics pipeline
metrics <- summarize_ptsd_changes(icd11_result)
create_readable_summary(metrics)
#>     Scenario Total Diagnosed Total Non-Diagnosed True Positive True Negative
#> 1  PTSD_orig    4710 (94.2%)          290 (5.8%)          4710           290
#> 2 PTSD_icd11   4641 (92.82%)         359 (7.18%)          4607           256
#>   Newly Diagnosed Newly Non-Diagnosed True Cases False Cases Sensitivity
#> 1               0                   0       5000           0      1.0000
#> 2              34                 103       4863         137      0.9781
#>   Specificity    PPV    NPV
#> 1      1.0000 1.0000 1.0000
#> 2      0.8828 0.9927 0.7131
```
