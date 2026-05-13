# Quick Start

This vignette gets you from installation to a first optimised PTSD
diagnostic combination in about 5 minutes. For the full workflow —
reliability analysis, ICD-11 comparison, model validation — see the
[Full Internal
Analysis](https://tobiasrspiller.github.io/PTSDdiag/articles/internal_analysis.md)
vignette.

## Install & load

``` r

# From CRAN
install.packages("PTSDdiag")

# Or the development version from GitHub
# install.packages("devtools")
devtools::install_github("TobiasRSpiller/PTSDdiag")
```

``` r

library(PTSDdiag)
```

## Load sample data

The package ships with `simulated_ptsd`: 5,000 simulated PCL-5 records
(20 symptoms, 0–4 scale), structured to reflect a trauma-exposed
clinical sample.

``` r

data("simulated_ptsd")
dim(simulated_ptsd)   # 5000 rows, 20 columns
#> [1] 5000   20
head(simulated_ptsd[, 1:5])
#>   S1 S2 S3 S4 S5
#> 1  2  1  4  1  4
#> 2  3  3  4  3  3
#> 3  0  1  1  2  2
#> 4  3  3  3  3  3
#> 5  2  3  3  2  3
#> 6  1  1  2  1  2
```

## Prepare & score

Standardise column names to the `symptom_1`–`symptom_20` convention,
then calculate total scores and apply DSM-5-TR criteria:

``` r

df <- rename_ptsd_columns(simulated_ptsd)
df <- calculate_ptsd_total(df)
df <- create_ptsd_diagnosis_nonbinarized(df)

summarize_ptsd(df)
#>   mean_total sd_total n_diagnosed
#> 1     57.772 12.36218        4710
```

## Find an optimal symptom combination

[`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
searches for the best *k*-symptom combinations (here: 4 out of 20) that
preserve DSM-5-TR diagnostic accuracy. Setting
`score_by = "newly_nondiagnosed"` minimises missed diagnoses (false
negatives).

> **Note on computation time.** This example uses `n_symptoms = 4`
> (4,845 combinations) for speed. A typical research analysis uses
> `n_symptoms = 6` (38,760 combinations), which takes 1–2 minutes.

``` r

result <- optimize_combinations(
  rename_ptsd_columns(simulated_ptsd),
  n_symptoms    = 4,
  n_required    = 3,
  n_top         = 3,
  score_by      = "newly_nondiagnosed",
  show_progress = FALSE
)
```

**Top combinations found:**

``` r

result$best_symptoms
#> [[1]]
#> [1]  1  6  7 13
#> 
#> [[2]]
#> [1]  4  6  7 13
#> 
#> [[3]]
#> [1]  4  6  7 17
```

**Diagnostic accuracy metrics:**

``` r

knitr::kable(result$summary, digits = 4,
             caption = "Top 3 non-hierarchical combinations")
```

| Scenario | combination_id | rank | Total Diagnosed | Total Non-Diagnosed | True Positive | True Negative | Newly Diagnosed | Newly Non-Diagnosed | True Cases | False Cases | Sensitivity | Specificity | PPV | NPV |
|:---|:---|---:|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PTSD_orig | NA | NA | 4710 (94.2%) | 290 (5.8%) | 4710 | 290 | 0 | 0 | 5000 | 0 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| symptom_1_6_7_13 | 1_6_7_13 | 1 | 4573 (91.46%) | 427 (8.54%) | 4535 | 252 | 38 | 175 | 4787 | 213 | 0.9628 | 0.8690 | 0.9917 | 0.5902 |
| symptom_4_6_7_13 | 4_6_7_13 | 2 | 4574 (91.48%) | 426 (8.52%) | 4535 | 251 | 39 | 175 | 4786 | 214 | 0.9628 | 0.8655 | 0.9915 | 0.5892 |
| symptom_4_6_7_17 | 4_6_7_17 | 3 | 4568 (91.36%) | 432 (8.64%) | 4528 | 250 | 40 | 182 | 4778 | 222 | 0.9614 | 0.8621 | 0.9912 | 0.5787 |

Top 3 non-hierarchical combinations {.table style="width:100%;"}

## Next steps

| Goal | Vignette |
|----|----|
| Hierarchical analysis, ICD-11 comparison, model validation | [Full Internal Analysis](https://tobiasrspiller.github.io/PTSDdiag/articles/internal_analysis.md) |
| Derive on one PCL-5 dataset, validate on another | [External Validation (PCL-5)](https://tobiasrspiller.github.io/PTSDdiag/articles/external_validation_pcl5.md) |
| Validate against the CAPS-5 gold standard | [External Validation (CAPS-5)](https://tobiasrspiller.github.io/PTSDdiag/articles/external_validation_caps5.md) |
| Full function reference | [Reference](https://tobiasrspiller.github.io/PTSDdiag/reference/index.md) |
