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
the held-out test set. We optimize by balanced accuracy, the package
default, which weighs performance in the diagnosed and the non-diagnosed
group equally; the [Getting
started](https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.md)
vignette explains this choice. To keep the vignette fast we work with a
250-row subset of the bundled data.

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
  score_by    = "balanced_accuracy",
  seed        = 42
)
ho$without_clusters$best_combinations
#> [[1]]
#> [1]  2  6  7 11 12 15
#> 
#> [[2]]
#> [1]  2  6  7 11 12 19
#> 
#> [[3]]
#> [1]  2  6  7 11 12 20
ho$without_clusters$summary
#>                 Scenario combination_id rank Total Diagnosed
#> 1              PTSD_orig           <NA>   NA     67 (89.33%)
#> 2 symptom_2_6_7_11_12_15 2_6_7_11_12_15    1        69 (92%)
#> 3 symptom_2_6_7_11_12_19 2_6_7_11_12_19    2        69 (92%)
#> 4 symptom_2_6_7_11_12_20 2_6_7_11_12_20    3     68 (90.67%)
#>   Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1          8 (10.67%)            67             8               0
#> 2              6 (8%)            67             6               2
#> 3              6 (8%)            67             6               2
#> 4           7 (9.33%)            65             5               3
#>   Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity    PPV
#> 1                   0         75           0      1.0000       1.000 1.0000
#> 2                   0         73           2      1.0000       0.750 0.9710
#> 3                   0         73           2      1.0000       0.750 0.9710
#> 4                   2         70           5      0.9701       0.625 0.9559
#>      NPV Accuracy Balanced Accuracy
#> 1 1.0000   1.0000            1.0000
#> 2 1.0000   0.9733            0.8750
#> 3 1.0000   0.9733            0.8750
#> 4 0.7143   0.9333            0.7976
```

`score_by = "balanced_accuracy"` maximizes the mean of sensitivity and
specificity; `score_by = "sensitivity"` remains the conservative
alternative when missing a true case is the costlier error, and
`score_by = "accuracy"` minimizes total misclassification. The `seed`
argument makes the split reproducible.

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
  score_by   = "balanced_accuracy",
  seed       = 42
)
cv$without_clusters$summary_by_fold
#>      Split                Scenario Total Diagnosed Total Non-Diagnosed
#> 1  Split 1               PTSD_orig     78 (92.86%)           6 (7.14%)
#> 2  Split 1  symptom_2_6_7_11_12_15     80 (95.24%)           4 (4.76%)
#> 3  Split 1  symptom_2_6_7_11_12_19     80 (95.24%)           4 (4.76%)
#> 4  Split 1  symptom_2_6_7_11_12_16     78 (92.86%)           6 (7.14%)
#> 5  Split 2               PTSD_orig     78 (93.98%)           5 (6.02%)
#> 6  Split 2  symptom_6_7_8_11_13_17     75 (90.36%)           8 (9.64%)
#> 7  Split 2 symptom_6_7_11_12_16_17     74 (89.16%)          9 (10.84%)
#> 8  Split 2    symptom_2_4_6_7_9_12     76 (91.57%)           7 (8.43%)
#> 9  Split 3               PTSD_orig     76 (91.57%)           7 (8.43%)
#> 10 Split 3  symptom_3_6_7_18_19_20     79 (95.18%)           4 (4.82%)
#> 11 Split 3   symptom_3_4_6_7_12_20     76 (91.57%)           7 (8.43%)
#> 12 Split 3  symptom_3_4_6_12_15_16     77 (92.77%)           6 (7.23%)
#>    True Positive True Negative Newly Diagnosed Newly Non-Diagnosed True Cases
#> 1             78             6               0                   0         84
#> 2             78             4               2                   0         82
#> 3             78             4               2                   0         82
#> 4             77             5               1                   1         82
#> 5             78             5               0                   0         83
#> 6             75             5               0                   3         80
#> 7             74             5               0                   4         79
#> 8             74             3               2                   4         77
#> 9             76             7               0                   0         83
#> 10            74             2               5                   2         76
#> 11            73             4               3                   3         77
#> 12            74             4               3                   2         78
#>    False Cases Sensitivity Specificity    PPV    NPV Accuracy Balanced Accuracy
#> 1            0      1.0000      1.0000 1.0000 1.0000   1.0000            1.0000
#> 2            2      1.0000      0.6667 0.9750 1.0000   0.9762            0.8333
#> 3            2      1.0000      0.6667 0.9750 1.0000   0.9762            0.8333
#> 4            2      0.9872      0.8333 0.9872 0.8333   0.9762            0.9103
#> 5            0      1.0000      1.0000 1.0000 1.0000   1.0000            1.0000
#> 6            3      0.9615      1.0000 1.0000 0.6250   0.9639            0.9808
#> 7            4      0.9487      1.0000 1.0000 0.5556   0.9518            0.9744
#> 8            6      0.9487      0.6000 0.9737 0.4286   0.9277            0.7744
#> 9            0      1.0000      1.0000 1.0000 1.0000   1.0000            1.0000
#> 10           7      0.9737      0.2857 0.9367 0.5000   0.9157            0.6297
#> 11           6      0.9605      0.5714 0.9605 0.5714   0.9277            0.7660
#> 12           5      0.9737      0.5714 0.9610 0.6667   0.9398            0.7726
#>     combination_id rank
#> 1             <NA>   NA
#> 2   2_6_7_11_12_15    1
#> 3   2_6_7_11_12_19    2
#> 4   2_6_7_11_12_16    3
#> 5             <NA>   NA
#> 6   6_7_8_11_13_17    1
#> 7  6_7_11_12_16_17    2
#> 8     2_4_6_7_9_12    3
#> 9             <NA>   NA
#> 10  3_6_7_18_19_20    1
#> 11   3_4_6_7_12_20    2
#> 12  3_4_6_12_15_16    3
cv$without_clusters$combinations_summary  # NULL if no combination repeats
#> # A tibble: 1 × 17
#>   Scenario  combination_id Splits_Appeared Total_Diagnosed Total_Non_Diagnosed
#>   <chr>     <chr>                    <int> <chr>           <chr>              
#> 1 PTSD_orig NA                           3 77.33 (92.8%)   6 (7.2%)           
#> # ℹ 12 more variables: True_Positive <dbl>, True_Negative <dbl>,
#> #   Newly_Diagnosed <dbl>, Newly_Non_Diagnosed <dbl>, True_Cases <dbl>,
#> #   False_Cases <dbl>, Sensitivity <dbl>, Specificity <dbl>, PPV <dbl>,
#> #   NPV <dbl>, Accuracy <dbl>, Balanced_Accuracy <dbl>
```

## External validation in a second cohort

To test the generalizability of definitions based on fewer symptoms, one
needs to evaluate the derived definitions in a second, independent
dataset. The package ships a second simulated dataset,
`simulated_ptsd_genpop`, whose PTSD prevalence is about 21%, well below
the 94% of the included clinical sample. Deriving in the clinical sample
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
                               score_by = "balanced_accuracy",
                               show_progress = FALSE)

# Export for reuse
tmp <- tempfile(fileext = ".json")
write_combinations(deriv$best_symptoms, tmp,
                   n_required = 4,
                   score_by = "balanced_accuracy",
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
#>                  Scenario Total Diagnosed Total Non-Diagnosed True Positive
#> 1               PTSD_orig      52 (20.8%)         198 (79.2%)            52
#> 2  symptom_6_7_8_11_13_17        45 (18%)           205 (82%)            42
#> 3 symptom_6_7_10_11_13_15        45 (18%)           205 (82%)            43
#> 4   symptom_4_6_7_8_11_17      43 (17.2%)         207 (82.8%)            41
#> 5  symptom_4_6_7_10_11_15        45 (18%)           205 (82%)            42
#> 6  symptom_6_7_8_11_13_18        45 (18%)           205 (82%)            42
#>   True Negative Newly Diagnosed Newly Non-Diagnosed True Cases False Cases
#> 1           198               0                   0        250           0
#> 2           195               3                  10        237          13
#> 3           196               2                   9        239          11
#> 4           196               2                  11        237          13
#> 5           195               3                  10        237          13
#> 6           195               3                  10        237          13
#>   Sensitivity Specificity    PPV    NPV Accuracy Balanced Accuracy
#> 1      1.0000      1.0000 1.0000 1.0000    1.000            1.0000
#> 2      0.8077      0.9848 0.9333 0.9512    0.948            0.8963
#> 3      0.8269      0.9899 0.9556 0.9561    0.956            0.9084
#> 4      0.7885      0.9899 0.9535 0.9469    0.948            0.8892
#> 5      0.8077      0.9848 0.9333 0.9512    0.948            0.8963
#> 6      0.8077      0.9848 0.9333 0.9512    0.948            0.8963
```

Compare this table with the derivation performance. The predictive
values move with prevalence: in the lower-prevalence community sample,
PPV falls and NPV rises, so a positive result from the same rule is less
likely to correspond to a true case than it was in the clinic.
Sensitivity and specificity are often more stable, but they are not
immune to differences in case mix: here sensitivity is lower in the
community sample, whose symptom profiles are milder than the clinic’s,
while specificity is slightly higher. Neither shift is a failure of the
rule; both are properties of applying any fixed criterion across
settings that differ in prevalence and severity, and revealing them is
exactly what external validation is for.

## How special is the winning subset?

Internal and external validation both look at the top of the ranking. A
complementary question is how the rest of the candidate set behaves: if
thousands of subsets perform nearly as well as the winner, the specific
winning items should not be over-interpreted, because many symptom sets
are effectively interchangeable.
[`score_all_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/score_all_combinations.md)
answers this by scoring every candidate combination — here all
$`\binom{20}{4} = 4{,}845`$ four-symptom subsets — and returning the
complete ranked table, the exhaustive companion to
[`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md).
Plotting the ranking metric against rank typically shows a plateau of
near-optimal subsets before performance falls away; the width of that
plateau is the interchangeability of the solution.

``` r

curve <- score_all_combinations(ptsd, n_symptoms = 4, n_required = 3,
                                show_progress = FALSE)
nrow(curve)
#> [1] 4845
head(curve, 3)
#>   rank combination_id  tp fn fp tn sensitivity specificity ppv       npv
#> 1    1      6_7_12_17 227  5  0 18   0.9784483           1   1 0.7826087
#> 2    2       4_6_7_12 226  6  0 18   0.9741379           1   1 0.7500000
#> 3    3       4_6_7_19 225  7  0 18   0.9698276           1   1 0.7200000
#>   accuracy balanced_accuracy
#> 1    0.980         0.9892241
#> 2    0.976         0.9870690
#> 3    0.972         0.9849138

plot(curve$rank, curve$balanced_accuracy, type = "l", log = "x",
     xlab = "Combination rank (log scale)", ylab = "Balanced accuracy")
```

![Balanced accuracy of every four-symptom combination by
rank](validation_files/figure-html/all-combinations-1.png)

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
