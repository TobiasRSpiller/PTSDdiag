# CAPS-5 workflow

This vignette compares a PCL-5 symptom definition against the CAPS-5
diagnosis, and shows how to optimize a definition against the CAPS-5
diagnosis directly.

## Why use the CAPS-5

The PCL-5 is completed by the patient; the CAPS-5 is administered by a
clinician. Both rate the same 20 DSM-5-TR symptoms on the same 0 to 4
scale, so when both are available for the same participants the CAPS-5
diagnosis is the closest available reference to a clinical ground truth.
That makes it the natural standard against which to judge a self-report
definition.

## Requirements for the input data

The CAPS-5 input must be the 20 items in their standard order, scored 0
to 4, with no missing values, plus any identifier columns you name in
`id_col`; the full contract is in the [Getting
started](https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.md)
vignette. One **additional requirement** applies here: when comparing
two instruments, the PCL-5 and CAPS-5 data frames must describe the same
participants in the same row order.

## Standardizing both instruments

We standardize the PCL-5 data as usual and create a CAPS-5 data frame in
the same form with
[`rename_caps5_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_caps5_columns.md).
The CAPS-5 ratings below are simulated independently of the PCL-5
scores, purely for illustration. Because they are random rather than
clinician-rated, the agreement reported in the next section reflects
chance, and the tables should be read as illustrations of the output
format rather than as a real instrument comparison. We use a 500-row
subset of the bundled data to keep the vignette fast.

``` r

library(PTSDdiag)

data("simulated_ptsd")
pcl5 <- simulated_ptsd[1:500, ]
ptsd <- rename_ptsd_columns(pcl5,
                            id_col = c("patient_id", "age", "sex"))

set.seed(42)
caps5_raw <- as.data.frame(matrix(
  sample(0:4, 20 * nrow(pcl5), replace = TRUE),
  ncol = 20
))
caps5 <- rename_caps5_columns(caps5_raw)
```

## Computing the CAPS-5 diagnosis

[`create_caps5_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_caps5_diagnosis.md)
applies the DSM-5-TR algorithm to the CAPS-5 severity scores, using the
same clusters and the same presence threshold of 2 or higher as the
PCL-5 diagnosis. It returns a single logical column, `PTSD_caps5`.

``` r

caps5_dx <- create_caps5_diagnosis(caps5)
head(caps5_dx)
#>   PTSD_caps5
#> 1      FALSE
#> 2      FALSE
#> 3       TRUE
#> 4      FALSE
#> 5       TRUE
#> 6       TRUE
mean(caps5_dx$PTSD_caps5) * 100
#> [1] 78.6
```

## Comparing the PCL-5 and CAPS-5 diagnoses

[`compare_diagnostic_systems()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
builds one summary table that scores each diagnostic system against a
chosen reference. Setting `reference = "caps5"` makes the CAPS-5 the
standard, so the PCL-5 diagnosis and ICD-11 are evaluated against it.
Each row reports sensitivity, specificity, PPV, and NPV against the
reference, together with the counts of false positives, false negatives,
and total misclassifications.

``` r

compare_diagnostic_systems(
  ptsd,
  caps5_data = caps5,
  icd11      = TRUE,
  reference  = "caps5"
)
#>              system n_diagnosed pct_diagnosed sensitivity specificity    ppv
#> 1 DSM-5-TR (CAPS-5)         393          78.6      1.0000      1.0000 1.0000
#> 2  DSM-5-TR (PCL-5)         465          93.0      0.9262      0.0561 0.7828
#> 3    ICD-11 (PCL-5)         460          92.0      0.9135      0.0561 0.7804
#>      npv n_false_negative pct_false_negative n_false_positive
#> 1 1.0000                0                0.0                0
#> 2 0.1714               29                5.8              101
#> 3 0.1500               34                6.8              101
#>   pct_false_positive n_misclassified
#> 1                0.0               0
#> 2               20.2             130
#> 3               20.2             135
```

## Optimizing against the CAPS-5 diagnosis

To make the CAPS-5 the optimization target rather than a row in a
comparison, pass the clinician diagnosis to
[`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
as a fixed criterion. The optimized PCL-5 definitions are then reported
alongside it, and the symptom-frequency tools apply as in the [Comparing
diagnostic
criteria](https://tobiasrspiller.github.io/PTSDdiag/articles/comparing-criteria.md)
vignette.

``` r

comp <- compare_optimizations(
  ptsd,
  scenarios = list(
    "4/6 Hierarchical"     = list(n_symptoms = 6, n_required = 4, hierarchical = TRUE),
    "4/6 Non-hierarchical" = list(n_symptoms = 6, n_required = 4, hierarchical = FALSE),
    "CAPS-5 (reference)"   = list(type = "fixed", criterion = caps5_dx$PTSD_caps5,
                                  symptoms = 1:20)
  ),
  n_top         = 5,
  score_by      = "accuracy",
  show_progress = FALSE
)
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 1, 6, 7, 11, 16, 17
#> ℹ Evaluated 38760 combinations. Best: 1, 3, 6, 7, 11, 15
summarize_top_combinations(comp, top_n = 3, as_percent = TRUE)
#>               Approach Rank             Combination  TP  FN FP TN Sensitivity
#> 1     4/6 Hierarchical    1  symptom_1_6_7_11_16_17 411  54  0 35    88.38710
#> 2     4/6 Hierarchical    2  symptom_1_6_7_11_16_19 411  54  1 34    88.38710
#> 3     4/6 Hierarchical    3  symptom_4_6_7_11_16_19 410  55  0 35    88.17204
#> 4 4/6 Non-hierarchical    1   symptom_1_3_6_7_11_15 460   5  8 27    98.92473
#> 5 4/6 Non-hierarchical    2   symptom_3_5_6_7_11_15 457   8  6 29    98.27957
#> 6 4/6 Non-hierarchical    3  symptom_5_6_7_11_15_16 456   9  5 30    98.06452
#> 7   CAPS-5 (reference)    1 PTSD_CAPS.5..reference. 364 101 29  6    78.27957
#>   Specificity       PPV       NPV
#> 1   100.00000 100.00000 39.325843
#> 2    97.14286  99.75728 38.636364
#> 3   100.00000 100.00000 38.888889
#> 4    77.14286  98.29060 84.375000
#> 5    82.85714  98.70410 78.378378
#> 6    85.71429  98.91540 76.923077
#> 7    17.14286  92.62087  5.607477
```

## Interpreting agreement and disagreement

When the PCL-5 and CAPS-5 diagnoses agree closely, a simplified PCL-5
definition that reproduces the full PCL-5 diagnosis also reproduces the
clinician diagnosis, and the choice of reference is immaterial. When
they diverge, the choice of reference matters, and reporting performance
against both is desirable.

## See also

- [Getting
  started](https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.md)
  for the single-cohort derivation workflow.
- [Comparing diagnostic
  criteria](https://tobiasrspiller.github.io/PTSDdiag/articles/comparing-criteria.md)
  for multi-rule comparison and the symptom-frequency heatmap.
- [Validating abbreviated symptom
  definitions](https://tobiasrspiller.github.io/PTSDdiag/articles/validation.md)
  for internal and external validation.
