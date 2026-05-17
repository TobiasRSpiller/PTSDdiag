# Compute CAPS-5 DSM-5-TR PTSD diagnosis

Applies the DSM-5-TR PTSD diagnostic algorithm to CAPS-5
(Clinician-Administered PTSD Scale for DSM-5) item scores and returns a
single-column dataframe indicating diagnostic status. Because CAPS-5
uses the same 20-item structure, 0–4 severity scale, and \\\ge\\ 2
symptom-presence threshold as the PCL-5, the diagnostic algorithm is
identical.

## Usage

``` r
create_caps5_diagnosis(data)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns of CAPS-5 item severity
  scores (output of
  [`rename_caps5_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_caps5_columns.md)).
  Columns must be named `symptom_1` through `symptom_20`, scored on a
  0–4 scale, with no missing values.

## Value

A `data.frame` with one logical column and one row per participant:

- `PTSD_caps5`: CAPS-5 DSM-5-TR diagnosis

Any carry-through columns present in `data` (e.g. an ID column added via
[`rename_caps5_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_caps5_columns.md))
are prepended in original order.

## Details

The DSM-5-TR diagnostic criteria applied are:

- Criterion B (Intrusion): \\\ge\\ 1 of items 1–5 with severity \\\ge\\
  2

- Criterion C (Avoidance): \\\ge\\ 1 of items 6–7 with severity \\\ge\\
  2

- Criterion D (Negative cognitions/mood): \\\ge\\ 2 of items 8–14 with
  severity \\\ge\\ 2

- Criterion E (Arousal/reactivity): \\\ge\\ 2 of items 15–20 with
  severity \\\ge\\ 2

All four criteria must be met for a positive diagnosis.

Unlike
[`create_icd11_diagnosis`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md),
this function returns only the CAPS-5 diagnosis column (`PTSD_caps5`),
not a PCL-5 reference column. This is because the CAPS-5 diagnosis is
typically used as the gold-standard reference itself, not compared
against a PCL-5 baseline.

The returned dataframe can be passed to
[`compare_diagnostic_systems`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
via its `caps5_data` parameter, or used directly for descriptive
analyses.

## See also

[`rename_caps5_columns`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_caps5_columns.md)
for standardizing CAPS-5 column names.

[`compare_diagnostic_systems`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
for comparing CAPS-5 against PCL-5 and optimized symptom combinations in
a unified table.

[`create_icd11_diagnosis`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_icd11_diagnosis.md)
for the ICD-11 alternative criteria.

## Examples

``` r
# Simulate CAPS-5 data (using same structure as PCL-5)
set.seed(42)
caps5_raw <- data.frame(matrix(sample(0:4, 400, replace = TRUE), ncol = 20))
caps5_data <- rename_caps5_columns(caps5_raw)
caps5_dx <- create_caps5_diagnosis(caps5_data)
head(caps5_dx)
#>   PTSD_caps5
#> 1      FALSE
#> 2      FALSE
#> 3       TRUE
#> 4       TRUE
#> 5      FALSE
#> 6      FALSE
table(caps5_dx$PTSD_caps5)
#> 
#> FALSE  TRUE 
#>     9    11 
```
