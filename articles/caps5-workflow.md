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
so `rename_*` sees exactly 20 item columns. We use a 250-row subset for
speed.

``` r

library(PTSDdiag)

data("simulated_ptsd_genpop")
gp   <- simulated_ptsd_genpop[1:250, ]
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
#> [1] 20
```

## Comparing the PCL-5 and CAPS-5 diagnoses

[`compare_diagnostic_systems()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_diagnostic_systems.md)
builds one summary table that scores each diagnostic system against a
chosen reference. Setting `reference = "caps5"` makes the CAPS-5 the
standard, so the PCL-5 diagnosis and ICD-11 are evaluated against it.
Each row reports sensitivity, specificity, PPV, NPV, accuracy, and
balanced accuracy against the reference, together with the counts of
false positives, false negatives, and total misclassifications.

``` r

compare_diagnostic_systems(
  ptsd,
  caps5_data = caps5,
  icd11      = TRUE,
  reference  = "caps5"
)
#>              system n_diagnosed pct_diagnosed sensitivity specificity    ppv
#> 1 DSM-5-TR (CAPS-5)          50          20.0        1.00        1.00 1.0000
#> 2  DSM-5-TR (PCL-5)          52          20.8        0.64        0.90 0.6154
#> 3    ICD-11 (PCL-5)          56          22.4        0.60        0.87 0.5357
#>      npv n_false_negative pct_false_negative n_false_positive
#> 1 1.0000                0                0.0                0
#> 2 0.9091               18                7.2               20
#> 3 0.8969               20                8.0               26
#>   pct_false_positive n_misclassified accuracy balanced_accuracy
#> 1                0.0               0    1.000             1.000
#> 2                8.0              38    0.848             0.770
#> 3               10.4              46    0.816             0.735
```

Because the two instruments are correlated here rather than random, the
self-report PCL-5 diagnosis agrees substantially with the clinician
CAPS-5 reference. Sensitivity is the share of CAPS-5-positive
participants the PCL-5 rule also calls positive, accuracy is the overall
share classified the same way, and balanced accuracy averages
performance in the CAPS-5-positive and CAPS-5-negative groups.

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
  score_by      = "balanced_accuracy",
  show_progress = FALSE
)
#> ℹ Generated 13685 valid cluster-constrained combinations
#> ℹ Evaluated 13685 combinations. Best: 1, 5, 6, 7, 11, 18
#> ℹ Evaluated 38760 combinations. Best: 7, 10, 11, 15, 18, 19
summarize_top_combinations(comp, top_n = 3, as_percent = TRUE)
#>               Approach Rank              Combination TP FN FP  TN Sensitivity
#> 1     4/6 Hierarchical    1    symptom_1_5_6_7_11_18 39 13  0 198    75.00000
#> 2     4/6 Hierarchical    2   symptom_3_6_7_11_13_15 38 14  0 198    73.07692
#> 3     4/6 Hierarchical    3    symptom_2_3_6_7_11_18 38 14  0 198    73.07692
#> 4 4/6 Non-hierarchical    1 symptom_7_10_11_15_18_19 47  5  1 197    90.38462
#> 5 4/6 Non-hierarchical    2  symptom_3_7_10_15_18_19 47  5  2 196    90.38462
#> 6 4/6 Non-hierarchical    3  symptom_3_7_11_15_18_19 47  5  2 196    90.38462
#> 7   CAPS-5 (reference)    1  PTSD_CAPS.5..reference. 32 20 18 180    61.53846
#>   Specificity       PPV      NPV Accuracy Balanced Accuracy
#> 1   100.00000 100.00000 93.83886     94.8          87.50000
#> 2   100.00000 100.00000 93.39623     94.4          86.53846
#> 3   100.00000 100.00000 93.39623     94.4          86.53846
#> 4    99.49495  97.91667 97.52475     97.6          94.93978
#> 5    98.98990  95.91837 97.51244     97.2          94.68726
#> 6    98.98990  95.91837 97.51244     97.2          94.68726
#> 7    90.90909  64.00000 90.00000     84.8          76.22378
```

## Validating derived definitions against the CAPS-5 diagnosis

At a validation site the definitions arrive already derived (see
[Validating a shared definition across
sites](https://tobiasrspiller.github.io/PTSDdiag/articles/multi-site-validation.md)),
and the question becomes how each performs against the local clinician
diagnosis.
[`evaluate_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md)
takes the clinician standard through its `reference` argument: a logical
vector, a 0/1-coded column, or the name of a carry-through column in the
data. Participants without a clinician interview — `NA` in the reference
— are excluded automatically, with a message reporting how many. A
`"Full 20-item PCL-5"` ceiling row is added by default: the complete
PCL-5 diagnosis scored against the same reference. That row separates
the cost of dropping items from the intrinsic PCL-5-vs-CAPS-5
disagreement, and no reduced definition can be expected to beat it. Here
we extract the top three combinations per optimized rule from the
comparison above and request the tidy table layout.

``` r

definitions <- extract_definitions(comp, n = 3)

evaluate_definitions(ptsd, definitions,
                     reference = caps5_dx$PTSD_caps5, tidy = TRUE)
#>               Approach Rank           Combination TP FN FP  TN Sensitivity
#> 1     4/6 Hierarchical    1    1, 5, 6, 7, 11, 18 28 22 11 189        0.56
#> 2     4/6 Hierarchical    2   3, 6, 7, 11, 13, 15 22 28 16 184        0.44
#> 3     4/6 Hierarchical    3    2, 3, 6, 7, 11, 18 27 23 11 189        0.54
#> 4 4/6 Non-hierarchical    1 7, 10, 11, 15, 18, 19 31 19 17 183        0.62
#> 5 4/6 Non-hierarchical    2  3, 7, 10, 15, 18, 19 30 20 19 181        0.60
#> 6 4/6 Non-hierarchical    3  3, 7, 11, 15, 18, 19 30 20 19 181        0.60
#> 7   Full 20-item PCL-5    1                  <NA> 32 18 20 180        0.64
#> 8               ICD-11    1    2, 3, 6, 7, 17, 18 30 20 26 174        0.60
#>   Specificity       PPV       NPV Accuracy Balanced Accuracy
#> 1       0.945 0.7179487 0.8957346    0.868            0.7525
#> 2       0.920 0.5789474 0.8679245    0.824            0.6800
#> 3       0.945 0.7105263 0.8915094    0.864            0.7425
#> 4       0.915 0.6458333 0.9059406    0.856            0.7675
#> 5       0.905 0.6122449 0.9004975    0.844            0.7525
#> 6       0.905 0.6122449 0.9004975    0.844            0.7525
#> 7       0.900 0.6153846 0.9090909    0.848            0.7700
#> 8       0.870 0.5357143 0.8969072    0.816            0.7350
```

The `Combination` column is `NA` for the ceiling row, which applies all
20 items rather than a subset. Comparing each definition’s balanced
accuracy with the ceiling shows how much of the disagreement with the
CAPS-5 is attributable to simplification and how much the full
instrument shares.

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
