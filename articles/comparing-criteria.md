# Comparing diagnostic criteria

This vignette evaluates a set of candidate definitions for PTSD on a
single sample, reports their diagnostic performance, and identifies the
symptoms that recur across the most accurate solutions.

## Why compare different definitions

As the differences between the DSM-5-TR and the ICD-11 illustrate, there
are numerous ways PTSD could be defined. With regard to the DSM-5-TR
definition, there are two relevant parameters that can be changed: the
number of items that must be present and whether the clusters structure
should be retained.
[`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
runs a set of different rules in one call so they can be compared
easily. Although fully customizable (see below) the default set contains
three example rules, as well as the option to add the ICD-11 criteria.
These rules are:

- **Four of six symptoms, hierarchical.** At least four of a total of
  six selected symptoms must be present, and the selected set must
  include at least one symptom from each DSM-5-TR cluster (B, C, D, E).
  This preserves the polythetic structure of the full criteria.
- **Four of six symptoms, without the cluster requirement.** The same
  number of symptoms, but any six symptoms may be chosen, not requiring
  the cluster structure.
- **Three of six symptoms, without the cluster requirement.** A lower
  threshold on six symptoms, more resembling the ICD-11 definition of
  PTSD.
- **ICD-11.** A fixed rule using six items (re-experiencing in the
  present, items 2, 3; avoidance, items 6, 7; sense of current threat,
  items 17, 18), requiring at least one symptom per cluster. This is the
  narrow mapping used across the published PCL-5-to-ICD-11 literature:
  ICD-11 re-experiencing must have a here-and-now quality, which
  nightmares and flashbacks capture but the PCL-5’s intrusive-memories
  item (item 1) does not.

## Requirements for the input data

The input must be the 20 PCL-5 items in their standard order, scored 0
to 4, with no missing values, plus any identifier columns you name in
`id_col`. For more details see the [Getting
started](https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.md)
vignette. As there, we keep `patient_id`, `age`, and `sex` attached with
`id_col` so that per-participant results remain linked to demographics.

## Running the comparison in one call

[`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
evaluates the three scenarios outlined above and returns one object that
holds the per-scenario results. We request the three default optimized
rules, add ICD-11 with `include_icd11 = TRUE`, and keep the ten best
combinations per optimized rule with `n_top = 10`. The default
`score_by = "balanced_accuracy"` ranks combinations by the mean of
sensitivity and specificity, so the high prevalence of the clinical
sample cannot dominate the ranking; the [Getting
started](https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.md)
vignette discusses this choice and the `"accuracy"` and `"sensitivity"`
alternatives. To keep the vignette fast we use a 120-row subset of the
bundled data.

``` r

library(PTSDdiag)

data("simulated_ptsd")
ptsd <- rename_ptsd_columns(simulated_ptsd[1:120, ],
                            id_col = c("patient_id", "age", "sex"))

comp <- compare_optimizations(
  ptsd,
  n_top         = 10,
  include_icd11 = TRUE,
  score_by      = "balanced_accuracy",
  show_progress = FALSE
)
print(comp)
```

The printed object lists each scenario with its best combination, so the
best performing combinations for each of the four scenarios are now
directly comparable.

## A performance table for the manuscript

[`summarize_top_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md)
collapses the object into one table with a single row per candidate
definition. Setting `as_percent = TRUE` reports the rates as
percentages, and `top_n` limits how many combinations per rule are
shown.

Each row carries the approach label, the rank within that approach, the
symptom combination, the four cell counts against the full diagnosis
(TP, FN, FP, TN), and the derived rates: sensitivity, specificity, PPV,
NPV, accuracy, and balanced accuracy. Balanced accuracy is the mean of
sensitivity and specificity, the quantity that the default
`score_by = "balanced_accuracy"` optimized for, so it is the natural
headline number when these definitions are compared; plain accuracy,
(TP + TN) divided by the sample size, is reported alongside it.

``` r

tbl <- summarize_top_combinations(comp, top_n = 10, as_percent = TRUE)
head(tbl, 12)
#>                Approach Rank            Combination  TP FN FP TN Sensitivity
#> 1      4/6 Hierarchical    1 symptom_1_4_7_11_15_17 103  8  0  9    92.79279
#> 2      4/6 Hierarchical    2 symptom_1_4_7_11_15_18 103  8  0  9    92.79279
#> 3      4/6 Hierarchical    3 symptom_1_5_7_11_15_17 103  8  0  9    92.79279
#> 4      4/6 Hierarchical    4 symptom_1_5_7_11_15_18 103  8  0  9    92.79279
#> 5      4/6 Hierarchical    5 symptom_1_6_7_11_15_17 102  9  0  9    91.89189
#> 6      4/6 Hierarchical    6 symptom_1_6_7_11_15_18 102  9  0  9    91.89189
#> 7      4/6 Hierarchical    7 symptom_5_6_7_11_15_16 102  9  0  9    91.89189
#> 8      4/6 Hierarchical    8 symptom_5_6_7_11_15_17 102  9  0  9    91.89189
#> 9      4/6 Hierarchical    9 symptom_5_6_7_11_15_18 102  9  0  9    91.89189
#> 10     4/6 Hierarchical   10 symptom_1_2_7_11_15_17 102  9  0  9    91.89189
#> 11 4/6 Non-hierarchical    1  symptom_2_3_6_7_11_12 109  2  0  9    98.19820
#> 12 4/6 Non-hierarchical    2 symptom_2_6_7_11_12_16 108  3  0  9    97.29730
#>    Specificity PPV      NPV Accuracy Balanced Accuracy
#> 1          100 100 52.94118 93.33333          96.39640
#> 2          100 100 52.94118 93.33333          96.39640
#> 3          100 100 52.94118 93.33333          96.39640
#> 4          100 100 52.94118 93.33333          96.39640
#> 5          100 100 50.00000 92.50000          95.94595
#> 6          100 100 50.00000 92.50000          95.94595
#> 7          100 100 50.00000 92.50000          95.94595
#> 8          100 100 50.00000 92.50000          95.94595
#> 9          100 100 50.00000 92.50000          95.94595
#> 10         100 100 50.00000 92.50000          95.94595
#> 11         100 100 81.81818 98.33333          99.09910
#> 12         100 100 75.00000 97.50000          98.64865
```

## Core symptoms across definitions

Which symptoms a rule selects can itself be of interest. If the same
symptoms are part of the best performing combination in different
scenarios, they are the symptoms carrying most of the diagnostic signal.
[`plot_symptom_frequency()`](https://tobiasrspiller.github.io/PTSDdiag/reference/plot_symptom_frequency.md)
shows, for each scenario, how often each of the 20 symptoms appears
among its top combinations, with a pooled OVERALL row across the
optimized rules (if `overall_includes_fixed = TRUE`). The more frequent
a symptom is, the darker its color.

``` r

plot_symptom_frequency(comp, type = "relative")
```

![Heatmap of PCL-5 symptom selection frequency across optimization
scenarios](comparing-criteria_files/figure-html/heatmap-1.png)

The same information in raw counts is available through
[`symptom_frequency()`](https://tobiasrspiller.github.io/PTSDdiag/reference/symptom_frequency.md).
Reshaping it to one row per item and one column per rule gives the table
behind the figure, in which the OVERALL column pools the three optimized
rules.

``` r

freq   <- symptom_frequency(comp)
counts <- xtabs(Count ~ Symptom + Approach, data = freq)
wide   <- as.data.frame.matrix(counts, optional = TRUE)
wide   <- cbind(Symptom = as.integer(rownames(wide)), wide)

knitr::kable(
  wide,
  row.names = FALSE,
  caption = "Number of times each PCL-5 item is selected among the top combinations - ICD-11 not included"
)
```

| Symptom | 4/6 Hierarchical | 4/6 Non-hierarchical | 3/6 Non-hierarchical | ICD-11 | OVERALL |
|---:|---:|---:|---:|---:|---:|
| 1 | 7 | 0 | 4 | 0 | 11 |
| 2 | 1 | 2 | 6 | 1 | 9 |
| 3 | 0 | 4 | 0 | 1 | 4 |
| 4 | 2 | 2 | 0 | 0 | 4 |
| 5 | 5 | 5 | 6 | 0 | 16 |
| 6 | 5 | 10 | 10 | 1 | 25 |
| 7 | 10 | 10 | 9 | 1 | 29 |
| 8 | 0 | 0 | 6 | 0 | 6 |
| 9 | 0 | 1 | 2 | 0 | 3 |
| 10 | 0 | 0 | 5 | 0 | 5 |
| 11 | 10 | 10 | 0 | 0 | 20 |
| 12 | 0 | 10 | 8 | 0 | 18 |
| 13 | 0 | 1 | 0 | 0 | 1 |
| 14 | 0 | 0 | 2 | 0 | 2 |
| 15 | 10 | 2 | 0 | 0 | 12 |
| 16 | 1 | 1 | 2 | 0 | 4 |
| 17 | 5 | 1 | 0 | 1 | 6 |
| 18 | 4 | 0 | 0 | 1 | 4 |
| 19 | 0 | 1 | 0 | 0 | 1 |
| 20 | 0 | 0 | 0 | 0 | 0 |

Number of times each PCL-5 item is selected among the top combinations -
ICD-11 not included {.table}

## Customising the scenarios

The `scenarios` argument takes a named list. Each entry is either an
optimized rule (`type = "optimize"`, with `n_symptoms`, `n_required`,
and `hierarchical`) or a fixed criterion (`type = "fixed"`, with
`criterion = "icd11"`, `"caps5"`, or a logical diagnosis vector you
supply). This is how you vary the subset size, supply custom clusters,
or benchmark against a criterion you have already derived from another
dataset (also see [Validating abbreviated symptom
definitions](https://tobiasrspiller.github.io/PTSDdiag/articles/validation.md))

``` r

my_scenarios <- list(
  "5/7 Hierarchical"     = list(n_symptoms = 7, n_required = 5, hierarchical = TRUE),
  "4/6 Hierarchical"     = list(n_symptoms = 6, n_required = 4, hierarchical = TRUE),
  "4/6 Non-hierarchical" = list(n_symptoms = 6, n_required = 4, hierarchical = FALSE),
  "ICD-11"               = list(type = "fixed", criterion = "icd11")
)

compare_optimizations(ptsd, scenarios = my_scenarios, n_top = 10,
                      score_by = "balanced_accuracy", show_progress = FALSE)
```

## See also

- [Getting
  started](https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.md)
  for the single-definition workflow and the full input contract.
- [Validating abbreviated symptom
  definitions](https://tobiasrspiller.github.io/PTSDdiag/articles/validation.md)
  for internal and cross-cohort tests of whether a definition
  generalizes.
- [CAPS-5
  workflow](https://tobiasrspiller.github.io/PTSDdiag/articles/caps5-workflow.md)
  for using the clinician-administered CAPS-5 as the reference
  instrument.
