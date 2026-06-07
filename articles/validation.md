# Validating abbreviated symptom definitions

A symptom definition is only useful if it holds up beyond the sample it
was derived in. This vignette tests that, first by internal validation
on a single dataset and then by external validation in an independent
cohort.

## Why validation matters

The optimization fits the data it is given, so a definition that
reproduces the full diagnosis almost perfectly in one sample may owe
part of that fit to noise specific to that sample. Two questions
separate a real result from an artefact of fitting. Does the same rule
perform comparably on cases that were not used to derive it? And does it
transport to a cohort with a different case mix? The first is answered
by internal validation, holding out part of the sample or rotating
through folds. The second is answered by external validation, deriving
the rule in one cohort and applying it unchanged in another. Predictive
values make the second question pressing: because they depend on how
common PTSD is, a rule moved from a high-prevalence clinic to a
low-prevalence community sample will behave differently even if its
sensitivity and specificity are stable.

## Requirements for the input data

The input must be the 20 PCL-5 items in their standard order, scored 0
to 4, with no missing values, plus any identifier columns you name in
`id_col`. The full contract is described in the [Getting
started](https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.md)
vignette.

## Internal validation

[`holdout_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/holdout_validation.md)
partitions the sample into a training set and a test set, derives the
top combinations on the training set, and reports their performance on
the held-out test set. We optimize by sensitivity here, which directs
the search to minimize missed cases. To keep the vignette fast we work
with a 250-row subset of the bundled data.

``` r

library(PTSDdiag)
library(dplyr)

data("simulated_ptsd")
ptsd <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                            id_col = c("patient_id", "age", "sex"))

ho <- holdout_validation(
  ptsd,
  train_ratio = 0.7,
  n_symptoms  = 6,
  n_required  = 4,
  n_top       = 3,
  score_by    = "sensitivity",
  seed        = 42
)
ho$without_clusters$best_combinations
#> [[1]]
#> [1]  1  5  6  7 12 20
#> 
#> [[2]]
#> [1]  1  6 10 12 13 19
#> 
#> [[3]]
#> [1]  1  6 10 12 13 20
ho$without_clusters$summary
#>                  Scenario  combination_id rank Total Diagnosed
#> 1               PTSD_orig            <NA>   NA     67 (89.33%)
#> 2   symptom_1_5_6_7_12_20   1_5_6_7_12_20    1        69 (92%)
#> 3 symptom_1_6_10_12_13_19 1_6_10_12_13_19    2     71 (94.67%)
#> 4 symptom_1_6_10_12_13_20 1_6_10_12_13_20    3     70 (93.33%)
#>   Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1          8 (10.67%)            67             8               0
#> 2              6 (8%)            67             6               2
#> 3           4 (5.33%)            67             4               4
#> 4           5 (6.67%)            65             3               5
#>   Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity    PPV NPV
#> 1                   0         75           0      1.0000       1.000 1.0000 1.0
#> 2                   0         73           2      1.0000       0.750 0.9710 1.0
#> 3                   0         71           4      1.0000       0.500 0.9437 1.0
#> 4                   2         68           7      0.9701       0.375 0.9286 0.6
#>   Accuracy
#> 1   1.0000
#> 2   0.9733
#> 3   0.9467
#> 4   0.9067
```

`score_by = "sensitivity"` minimizes false negatives, the conservative
choice when missing a true case is the costlier error;
`score_by = "accuracy"` would minimize total misclassification. The
`seed` argument makes the split reproducible.

[`cross_validation()`](https://tobiasrspiller.github.io/PTSDdiag/reference/cross_validation.md)
extends the same logic to k folds, deriving on k minus one folds and
testing on the remaining one, then pooling the results. Combinations
that recur across folds are reported in `combinations_summary`.

``` r

cv <- cross_validation(
  ptsd,
  k          = 3,
  n_symptoms = 6,
  n_required = 4,
  n_top      = 3,
  score_by   = "sensitivity",
  seed       = 42
)
cv$without_clusters$summary_by_fold
#>      Split               Scenario Total Diagnosed Total Non-Diagnosed
#> 1  Split 1              PTSD_orig     78 (92.86%)           6 (7.14%)
#> 2  Split 1   symptom_1_3_6_7_9_13     78 (92.86%)           6 (7.14%)
#> 3  Split 1  symptom_1_3_6_7_11_13     78 (92.86%)           6 (7.14%)
#> 4  Split 1  symptom_1_5_6_7_12_20     80 (95.24%)           4 (4.76%)
#> 5  Split 2              PTSD_orig     78 (93.98%)           5 (6.02%)
#> 6  Split 2  symptom_1_3_5_6_12_15     78 (93.98%)           5 (6.02%)
#> 7  Split 2 symptom_1_3_5_12_15_17     77 (92.77%)           6 (7.23%)
#> 8  Split 2 symptom_1_3_6_11_12_15     78 (93.98%)           5 (6.02%)
#> 9  Split 3              PTSD_orig     76 (91.57%)           7 (8.43%)
#> 10 Split 3  symptom_1_3_6_8_11_20     77 (92.77%)           6 (7.23%)
#> 11 Split 3 symptom_1_3_6_11_12_20     79 (95.18%)           4 (4.82%)
#> 12 Split 3 symptom_1_3_6_11_15_20     78 (93.98%)           5 (6.02%)
#>    True Positive True Negative Newly Diagnosed Newly Non-Diagnosed True Cases
#> 1             78             6               0                   0         84
#> 2             77             5               1                   1         82
#> 3             77             5               1                   1         82
#> 4             78             4               2                   0         82
#> 5             78             5               0                   0         83
#> 6             77             4               1                   1         81
#> 7             76             4               1                   2         80
#> 8             77             4               1                   1         81
#> 9             76             7               0                   0         83
#> 10            73             3               4                   3         76
#> 11            75             3               4                   1         78
#> 12            74             3               4                   2         77
#>    False Cases Sensitivity Specificity    PPV    NPV Accuracy combination_id
#> 1            0      1.0000      1.0000 1.0000 1.0000   1.0000           <NA>
#> 2            2      0.9872      0.8333 0.9872 0.8333   0.9762   1_3_6_7_9_13
#> 3            2      0.9872      0.8333 0.9872 0.8333   0.9762  1_3_6_7_11_13
#> 4            2      1.0000      0.6667 0.9750 1.0000   0.9762  1_5_6_7_12_20
#> 5            0      1.0000      1.0000 1.0000 1.0000   1.0000           <NA>
#> 6            2      0.9872      0.8000 0.9872 0.8000   0.9759  1_3_5_6_12_15
#> 7            3      0.9744      0.8000 0.9870 0.6667   0.9639 1_3_5_12_15_17
#> 8            2      0.9872      0.8000 0.9872 0.8000   0.9759 1_3_6_11_12_15
#> 9            0      1.0000      1.0000 1.0000 1.0000   1.0000           <NA>
#> 10           7      0.9605      0.4286 0.9481 0.5000   0.9157  1_3_6_8_11_20
#> 11           5      0.9868      0.4286 0.9494 0.7500   0.9398 1_3_6_11_12_20
#> 12           6      0.9737      0.4286 0.9487 0.6000   0.9277 1_3_6_11_15_20
#>    rank
#> 1    NA
#> 2     1
#> 3     2
#> 4     3
#> 5    NA
#> 6     1
#> 7     2
#> 8     3
#> 9    NA
#> 10    1
#> 11    2
#> 12    3
cv$without_clusters$combinations_summary  # NULL if no combination repeats
#> # A tibble: 1 × 16
#>   Scenario  combination_id Splits_Appeared Total_Diagnosed Total_Non_Diagnosed
#>   <chr>     <chr>                    <int> <chr>           <chr>              
#> 1 PTSD_orig NA                           3 77.33 (92.8%)   6 (7.2%)           
#> # ℹ 11 more variables: True_Positive <dbl>, True_Negative <dbl>,
#> #   Newly_Diagnosed <dbl>, Newly_Non_Diagnosed <dbl>, True_Cases <dbl>,
#> #   False_Cases <dbl>, Sensitivity <dbl>, Specificity <dbl>, PPV <dbl>,
#> #   NPV <dbl>, Accuracy <dbl>
```

## External validation in a second cohort

To test generalizability of the definitions with based on fewer
symptoms, one needs to test the derived defintions in a second,
independent dataset. The package ships a second simulated dataset,
`simulated_ptsd_genpop`, whose PTSD prevalence is about 21%, well below
the 94% of the inlcuded clinical sample. Deriving in the clinical sample
and validating in the community sample therefore probes exactly the
prevalence shift described above. We again use a 250-row subset of each
for speed.

The combinations are derived once, written to a small JSON file, and
read back before being applied. The export step is what makes the rule
portable across sites and analysts, without a need for data sharing or
manual transcription.

``` r

data("simulated_ptsd_genpop")

# Derive in the clinical sample
deriv <- optimize_combinations(ptsd, 
                               n_symptoms = 6, 
                               n_required = 4,
                               n_top = 5, 
                               score_by = "accuracy",
                               show_progress = FALSE)

# Export for reuse
tmp <- tempfile(fileext = ".json")
write_combinations(deriv$best_symptoms, tmp, 
                   n_required = 4,
                   score_by = "accuracy",
                   description = "Six-symptom, four-required definition")

# A second analyst reads the file and applies it to the community sample.
# simulated_ptsd_genpop also carries paired CAPS-5 columns (C1..C20); here we
# use only the PCL-5 items, so we select those before standardising.
spec   <- read_combinations(tmp)
genpop <- rename_ptsd_columns(
  simulated_ptsd_genpop[1:250, c("patient_id", "age", "sex", paste0("S", 1:20))],
  id_col = c("patient_id", "age", "sex")
)

applied <- apply_symptom_combinations(genpop, spec$combinations,
                                      n_required = spec$n_required)
summarize_ptsd_changes(applied) %>%
  create_readable_summary()
#>                 Scenario Total Diagnosed Total Non-Diagnosed True Positive
#> 1              PTSD_orig      52 (20.8%)         198 (79.2%)            52
#> 2 symptom_1_6_7_12_15_18        45 (18%)           205 (82%)            42
#> 3 symptom_2_6_7_11_12_15        45 (18%)           205 (82%)            41
#> 4 symptom_2_6_7_11_12_19      47 (18.8%)         203 (81.2%)            44
#> 5 symptom_2_6_7_12_15_17        45 (18%)           205 (82%)            40
#> 6  symptom_3_5_6_7_12_15      46 (18.4%)         204 (81.6%)            41
#>   True Negative Newly Diagnosed Newly Non-Diagnosed True Cases False Cases
#> 1           198               0                   0        250           0
#> 2           195               3                  10        237          13
#> 3           194               4                  11        235          15
#> 4           195               3                   8        239          11
#> 5           193               5                  12        233          17
#> 6           193               5                  11        234          16
#>   Sensitivity Specificity    PPV    NPV Accuracy
#> 1      1.0000      1.0000 1.0000 1.0000    1.000
#> 2      0.8077      0.9848 0.9333 0.9512    0.948
#> 3      0.7885      0.9798 0.9111 0.9463    0.940
#> 4      0.8462      0.9848 0.9362 0.9606    0.956
#> 5      0.7692      0.9747 0.8889 0.9415    0.932
#> 6      0.7885      0.9747 0.8913 0.9461    0.936
```

Compare this table with the derivation performance. Sensitivity and
specificity, which are properties of the rule, should remain close to
their values in the clinical sample. The predictive values will move: in
the lower-prevalence community sample, PPV falls and NPV rises, so a
positive result from the same rule is less likely to correspond to a
true case than it was in the clinic. This is not a failure of the rule
but a property of applying any fixed criterion across settings with
different PTSD prevalence rates.

## See also

- [Getting
  started](https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.md)
  for the single-cohort derivation workflow.
- [Comparing diagnostic
  criteria](https://tobiasrspiller.github.io/PTSDdiag/articles/comparing-criteria.md)
  for the symptom-frequency heatmap and multi-rule comparison.
- [CAPS-5
  workflow](https://tobiasrspiller.github.io/PTSDdiag/articles/caps5-workflow.md)
  for validation against a clinician-administered reference.
