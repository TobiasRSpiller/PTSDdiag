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

## The bundled paired data

The general-population dataset `simulated_ptsd_genpop` ships both
instruments for the same participants: the PCL-5 items `S1`–`S20` and
paired CAPS-5 severity ratings `C1`–`C20`, simulated so the two total
scores correlate about 0.8 (the level usually reported empirically).
Because both come from one data frame, the PCL-5 and CAPS-5 views
describe the same people in the same row order, which is exactly what a
paired-instrument comparison requires.

To analyse one instrument we standardise its 20 columns and park
everything else, including the other instrument’s columns, in `id_col`,
so `rename_*` sees exactly 20 item columns. We use a 500-row subset for
speed.

``` r

library(PTSDdiag)

data("simulated_ptsd_genpop")
gp   <- simulated_ptsd_genpop[1:500, ]
demo <- c("patient_id", "age", "sex")

# PCL-5 view: rename S1..S20; carry the CAPS-5 columns through untouched
ptsd  <- rename_ptsd_columns(gp,  id_col = c(demo, paste0("C", 1:20)))

# CAPS-5 view: rename C1..C20; carry the PCL-5 columns through untouched
caps5 <- rename_caps5_columns(gp, id_col = c(demo, paste0("S", 1:20)))
```

## Computing the CAPS-5 diagnosis

[`create_caps5_diagnosis()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_caps5_diagnosis.md)
applies the DSM-5-TR algorithm to the CAPS-5 severity scores, using the
same clusters and the same presence threshold of 2 or higher as the
PCL-5 diagnosis. It returns a single logical column, `PTSD_caps5`.

``` r

caps5_dx <- create_caps5_diagnosis(caps5)
mean(caps5_dx$PTSD_caps5) * 100
#> [1] 20.4
```

## Comparing the PCL-5 and CAPS-5 diagnoses

[`compare_diagnostic_systems()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
builds one summary table that scores each diagnostic system against a
chosen reference. Setting `reference = "caps5"` makes the CAPS-5 the
standard, so the PCL-5 diagnosis and ICD-11 are evaluated against it.
Each row reports sensitivity, specificity, PPV, NPV, and accuracy
against the reference, together with the counts of false positives,
false negatives, and total misclassifications.

``` r

compare_diagnostic_systems(
  ptsd,
  caps5_data = caps5,
  icd11      = TRUE,
  reference  = "caps5"
)
#>              system n_diagnosed pct_diagnosed sensitivity specificity   ppv
#> 1 DSM-5-TR (CAPS-5)         102          20.4      1.0000      1.0000 1.000
#> 2  DSM-5-TR (PCL-5)         105          21.0      0.6176      0.8945 0.600
#> 3    ICD-11 (PCL-5)         113          22.6      0.5882      0.8668 0.531
#>      npv n_false_negative pct_false_negative n_false_positive
#> 1 1.0000                0                0.0                0
#> 2 0.9013               39                7.8               42
#> 3 0.8915               42                8.4               53
#>   pct_false_positive n_misclassified accuracy
#> 1                0.0               0    1.000
#> 2                8.4              81    0.838
#> 3               10.6              95    0.810
```

Because the two instruments are correlated here rather than random, the
self-report PCL-5 diagnosis agrees substantially with the clinician
CAPS-5 reference. Sensitivity is the share of CAPS-5-positive
participants the PCL-5 rule also calls positive, and accuracy is the
overall share classified the same way.

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
#> ℹ Evaluated 13685 combinations. Best: 2, 6, 7, 10, 13, 18 (5 additional tied)
#> ℹ Evaluated 38760 combinations. Best: 7, 10, 11, 13, 15, 18 (1 additional tied)
summarize_top_combinations(comp, top_n = 3, as_percent = TRUE)
#>               Approach Rank              Combination TP FN FP  TN Sensitivity
#> 1     4/6 Hierarchical    1   symptom_2_6_7_10_13_18 74 31  1 394    70.47619
#> 2     4/6 Hierarchical    2   symptom_3_4_6_10_13_18 73 32  0 395    69.52381
#> 3     4/6 Hierarchical    3   symptom_1_4_6_11_13_18 73 32  0 395    69.52381
#> 4 4/6 Non-hierarchical    1 symptom_7_10_11_13_15_18 91 14  5 390    86.66667
#> 5 4/6 Non-hierarchical    2 symptom_7_10_11_15_18_19 91 14  5 390    86.66667
#> 6 4/6 Non-hierarchical    3  symptom_3_7_10_15_18_19 91 14  6 389    86.66667
#> 7   CAPS-5 (reference)    1  PTSD_CAPS.5..reference. 63 42 39 356    60.00000
#>   Specificity       PPV      NPV Accuracy
#> 1    99.74684  98.66667 92.70588     93.6
#> 2   100.00000 100.00000 92.50585     93.6
#> 3   100.00000 100.00000 92.50585     93.6
#> 4    98.73418  94.79167 96.53465     96.2
#> 5    98.73418  94.79167 96.53465     96.2
#> 6    98.48101  93.81443 96.52605     96.0
#> 7    90.12658  61.76471 89.44724     83.8
```

## Interpreting agreement and disagreement

When the PCL-5 and CAPS-5 diagnoses agree closely, as they do in this
paired sample, a simplified PCL-5 definition that reproduces the full
PCL-5 diagnosis also largely reproduces the clinician diagnosis, so the
choice of reference matters little. When the instruments diverge, the
choice of reference matters, and reporting performance against both is
the honest course; the fixed-criterion mechanism above makes that choice
explicit.

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
