# Getting started with PTSDdiag

PTSDdiag identifies simplified PTSD diagnostic criteria that maintain
classification accuracy against the full DSM-5-TR criteria.

## The problem addressed by PTSDdiag

PTSD as defined by the DSM-5-TR requires the presence of symptoms across
four clusters, drawing from a total of 20 symptoms. This polythetic,
hierarchical structure theoretically permits over 636,000 symptom
combinations qualifying for a diagnosis, yet empirical research has
shown that patients cluster around a limited number of distinct
profiles. The complexity of the full criteria creates a substantial
assessment burden and contributes to diagnostic heterogeneity that
complicates both clinical practice and research. The PTSDdiag package
implements a computational optimization approach that systematically
searches all possible subsets of a given size, identifies the
combinations that minimize misclassification relative to the full
DSM-5-TR criteria, and evaluates the robustness of the results across
multiple high-performing solutions. This vignette demonstrates a
complete workflow from a scored PCL-5 dataset to optimized symptom
combinations and summary output.

## Requirements for the input data

The optimization operates on the 20 PCL-5 items, so the package first
needs to know which columns hold those items and which columns identify
the participant.
[`rename_ptsd_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md)
does both: it renames the item columns to a canonical `symptom_1`
through `symptom_20`, and it leaves any identifier columns you name in
`id_col` untouched beside them.

Four caveats are worth mentioning.

- **Items are matched by position, not by name.** The first
  non-identifier column becomes `symptom_1`, the second becomes
  `symptom_2`, and so on. The item columns must therefore already be in
  the standard DSM-5-TR order (intrusive memories first, sleep
  disturbance last).
- **The data may contain only the 20 items and the columns you name in
  `id_col`.** Because matching is positional, the function cannot
  distinguish a stray column (an item from another questionnaire, a
  date) from a PCL-5 item. Rather than risk shifting every item by one
  position, it stops with an error whenever the number of non-identifier
  columns is not exactly 20. List the columns you want to keep (e.g.,
  identifiers, demographics) in `id_col`, and remove anything else
  before calling.
- **Items scoring needs to follow the PCL-5 convention.** Items need to
  be scored 0 to 4, and a symptom counts as present at a score of 2 or
  higher, following the DSM-5-TR.
- **Missing data is not permitted.** Missing data is handled explicitly
  by stopping the function because it could otherwise bias the results.

## Importing and preparing the data

We use the bundled `simulated_ptsd` dataset, which holds 5,000 simulated
records with three demographic columns (`patient_id`, `age`, `sex`)
followed by the 20 PCL-5 items (`S1`–`S20`).

``` r

library(PTSDdiag)
library(dplyr)

data("simulated_ptsd")
dim(simulated_ptsd)
#> [1] 5000   23
names(simulated_ptsd)[1:6]
#> [1] "patient_id" "age"        "sex"        "S1"         "S2"        
#> [6] "S3"
```

To keep this vignette quick to build we work with a 120-row subset; the
workflow is identical on the full dataset.

Before renaming anything,
[`check_pcl5_data()`](https://tobiasrspiller.github.io/PTSDdiag/reference/check_pcl5_data.md)
verifies the item columns in a single pass — exactly 20 non-identifier
columns, numeric, integer scores 0 to 4, no missing values — and reports
every problem at once rather than stopping at the first. On a freshly
exported data file this turns fixing the input into a one-iteration job.

``` r

check_pcl5_data(simulated_ptsd[1:120, ], id_col = c("patient_id", "age", "sex"))
#> ✔ Found exactly 20 non-ID columns; checking them positionally (DSM-5 item order
#>   assumed).
#> ✔ 120 rows.
#> ✔ All item columns are numeric.
#> ✔ No missing values.
#> ✔ All scores are integers between 0 and 4.
#> ✔ All checks passed -- data ready for the PTSDdiag workflow.
```

With the input verified, we rename. We pass the three demographic
columns to `id_col`. They stay attached to every participant through the
rest of the workflow, which is what later lets us describe the sample
without a separate merge.

``` r

ptsd <- rename_ptsd_columns(simulated_ptsd[1:120, ],
                            id_col = c("patient_id", "age", "sex"))
names(ptsd)[1:6]
#> [1] "patient_id" "age"        "sex"        "symptom_1"  "symptom_2" 
#> [6] "symptom_3"
```

The item columns are now `symptom_1` (intrusive memories) through
`symptom_20` (sleep disturbance), with the demographics preserved in
front.

## Defining the reference diagnosis

Every simplified definition is then judged against the full DSM-5-TR
diagnosis, so we need to compute the “true” diagnosis first.
[`create_ptsd_diagnosis_nonbinarized()`](https://tobiasrspiller.github.io/PTSDdiag/reference/create_ptsd_diagnosis_nonbinarized.md)
applies the DSM-5-TR algorithm to all 20 items and adds a logical
column, `PTSD_orig`, which is `TRUE` for participants who meet the
criteria and `FALSE` otherwise. This column is the outcome that the
optimization will try to reproduce with fewer symptoms.

A diagnosis requires at least one symptom from the intrusion cluster
(items 1–5), at least one from avoidance (items 6–7), at least two from
negative alterations in cognition and mood (items 8–14), and at least
two from alterations in arousal and reactivity (items 15–20), each
symptom counted as present at a score of 2 or higher.

``` r

ptsd <- ptsd %>%
  create_ptsd_diagnosis_nonbinarized()
```

[`calculate_ptsd_total()`](https://tobiasrspiller.github.io/PTSDdiag/reference/calculate_ptsd_total.md)
adds the PCL-5 sum score (range 0–80), a severity index we use to
describe the sample. We compute it on a separate descriptive copy rather
than in the analysis data, because the optimization functions expect
only the 20 items next to identifiers and the reference diagnosis and
warn when a total-score column is present.

``` r

desc <- calculate_ptsd_total(ptsd)
mean(desc$total)
#> [1] 57.98333
```

In this clinical-style sample, the mean PCL-5 total is 58 points and 92%
of participants meet the full criteria.

``` r

mean(ptsd$PTSD_orig) * 100
#> [1] 92.5
```

## Identifying a symptom subset

With the reference diagnosis in place,
[`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
searches for the symptom subset that reproduces it most closely. In this
example we test a simplified definition that requires four of the six
selected symptoms to be present, without taking the DSM-5-TR cluster
structure into account.

For a subset of six items, the function evaluates every possible
combination of the 20 symptoms. The number of combinations is
$`\binom{20}{6} = 38{,}760`$. To each one it applies the presence rule,
classifying a participant as positive when at least `n_required` of the
six selected symptoms are present (scored 2 or higher), and then ranks
the combinations by how often their decision disagrees with `PTSD_orig`.

Before running the search we choose the metric to optimize through the
`score_by` argument. Three options are available. The default,
`"balanced_accuracy"`, maximizes the mean of sensitivity and
specificity, so participants who meet the full criteria and participants
who do not carry equal weight. Setting it to `"accuracy"` instead
minimizes the total number of misclassifications, and `"sensitivity"`
minimizes false negatives only, which prioritizes not missing
participants who meet the full criteria at the cost of more false
positives. We use balanced accuracy here, and recommend it as the
standard choice, because diagnostic samples are rarely balanced: in this
sample 92% of participants meet the full criteria, so a rule that simply
diagnosed everyone would already reach 92% accuracy while being useless
for ruling anyone out. Balanced accuracy cannot be gamed this way,
because it scores performance in the diagnosed and the non-diagnosed
group separately.

Two further arguments shape the output. `n_top = 3` returns the three
best scoring subsets rather than a single winner, so that near optimal
solutions can be compared; the companion value `res$n_tied` reports how
many other combinations matched the top score exactly, which shows
whether the leading subset is uniquely best or one of several equivalent
solutions. `show_progress = FALSE` suppresses the progress bar.

``` r

res <- optimize_combinations(
  ptsd,
  n_symptoms    = 6,
  n_required    = 4,
  n_top         = 3,
  score_by      = "balanced_accuracy",
  show_progress = FALSE
)
res$best_symptoms
#> [[1]]
#> [1]  2  3  6  7 11 12
#> 
#> [[2]]
#> [1]  2  6  7 11 12 16
#> 
#> [[3]]
#> [1]  3  4  6  7 11 12
```

## Diagnostic performance metrics

The optimization maximizes one number, but a single score hides the kind
of error being made, and the two kinds carry different costs. A false
negative is a participant who meets the full DSM-5-TR criteria yet falls
below the simplified rule; a false positive is the reverse. Sensitivity
and specificity quantify these two error rates separately and are
properties of the rule itself rather than of the sample’s prevalence.
Positive and negative predictive values translate the rule to a
particular setting: because they depend on how common PTSD is, the same
six-symptom definition yields different predictive values in a specialty
clinic than in a community survey. Balanced accuracy, the mean of
sensitivity and specificity, is the single number the default
`score_by = "balanced_accuracy"` optimized for; plain accuracy, the
overall share of participants classified the same way as the full
criteria, is reported alongside it. Reporting all of these, together
with the underlying counts, is what lets a reader judge whether a
simplified definition is adequate for their purpose.

[`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
returns these metrics for the reference diagnosis and each top
combination in `res$summary`, including `Accuracy` and
`Balanced Accuracy` columns. This is the diagnostic-performance table.

``` r

res$summary
#>                 Scenario combination_id rank Total Diagnosed
#> 1              PTSD_orig           <NA>   NA     111 (92.5%)
#> 2  symptom_2_3_6_7_11_12  2_3_6_7_11_12    1    109 (90.83%)
#> 3 symptom_2_6_7_11_12_16 2_6_7_11_12_16    2       108 (90%)
#> 4  symptom_3_4_6_7_11_12  3_4_6_7_11_12    3    112 (93.33%)
#>   Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1            9 (7.5%)           111             9               0
#> 2          11 (9.17%)           109             9               0
#> 3            12 (10%)           108             9               0
#> 4           8 (6.67%)           111             8               1
#>   Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity    PPV
#> 1                   0        120           0       1.000      1.0000 1.0000
#> 2                   2        118           2       0.982      1.0000 1.0000
#> 3                   3        117           3       0.973      1.0000 1.0000
#> 4                   0        119           1       1.000      0.8889 0.9911
#>      NPV Accuracy Balanced Accuracy
#> 1 1.0000   1.0000            1.0000
#> 2 0.8182   0.9833            0.9910
#> 3 0.7500   0.9750            0.9865
#> 4 1.0000   0.9917            0.9444
```

## Where next

- [Comparing diagnostic
  criteria](https://tobiasrspiller.github.io/PTSDdiag/articles/comparing-criteria.md)
  — evaluate several subset sizes and hierarchical rules against each
  other, add ICD-11 as a benchmark, and identify the symptoms that recur
  across solutions.
- [Validating abbreviated symptom
  definitions](https://tobiasrspiller.github.io/PTSDdiag/articles/validation.md)
  — test whether a definition holds up under cross-validation and in an
  independent cohort.
- [CAPS-5
  workflow](https://tobiasrspiller.github.io/PTSDdiag/articles/caps5-workflow.md)
  — use the clinician-administered CAPS-5 as the reference instrument.
