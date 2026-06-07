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

We pass the three demographic columns to `id_col`. They stay attached to
every participant through the rest of the workflow, which is what later
lets us describe the sample without a separate merge.

``` r

ptsd <- rename_ptsd_columns(simulated_ptsd,
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
  create_ptsd_diagnosis_nonbinarized() %>%
  calculate_ptsd_total()
```

[`calculate_ptsd_total()`](https://tobiasrspiller.github.io/PTSDdiag/reference/calculate_ptsd_total.md)
adds the PCL-5 sum score (range 0–80), a severity index we will use to
describe the sample. In this clinical-style dataset, 94% of participants
meet the full criteria.

``` r

mean(ptsd$PTSD_orig) * 100
#> [1] 94.2
```

Here is the rewritten section. All prose now sits before the code, the
example is framed as a four-of-six definition that ignores the cluster
structure, the combination count is given explicitly, the `score_by`
choice is explained with both options and a rationale, and `n_top` and
`show_progress` are covered. No dashes used.

------------------------------------------------------------------------

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
`score_by` argument. Two options are available. Setting it to
`"accuracy"` minimizes the total number of misclassifications, counting
false positives and false negatives equally. Setting it to
`"sensitivity"` minimizes false negatives only, which prioritizes not
missing participants who meet the full criteria, at the cost of more
false positives. In this example we optimize for accuracy, because our
aim is a simplified definition that agrees with the full DSM-5-TR
diagnosis overall rather than one tuned toward a single type of error.

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
  score_by      = "accuracy",
  show_progress = FALSE
)
#> Warning: "total" column detected. This function should only be used with raw symptom
#> scores.
#> "total" column detected. This function should only be used with raw symptom
#> scores.
res$best_symptoms
#> [[1]]
#> [1]  6  7  9 16 17 19
#> 
#> [[2]]
#> [1]  4  6  7  9 17 19
#> 
#> [[3]]
#> [1]  4  6  7  9 12 17
```

## Diagnostic performance metrics

The optimization minimizes the total number of misclassified
participants, but a single error count hides the kind of error being
made, and the two kinds carry different costs. A false negative is a
participant who meets the full DSM-5-TR criteria yet falls below the
simplified rule; a false positive is the reverse. Sensitivity and
specificity quantify these two error rates separately and are properties
of the rule itself, largely stable across samples. Positive and negative
predictive values translate the rule to a particular setting: because
they depend on how common PTSD is, the same six-symptom definition
yields different predictive values in a specialty clinic than in a
community survey. Accuracy, the overall share of participants classified
the same way as the full criteria, is the single number
`score_by = "accuracy"` optimized for. Reporting all of these, alongside
the underlying counts, is what lets a reader judge whether a simplified
definition is adequate for their purpose.

[`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
returns these metrics for the reference diagnosis and each top
combination in `res$summary`, including an `Accuracy` column. This is
the diagnostic-performance table.

``` r

res$summary
#>                 Scenario combination_id rank Total Diagnosed
#> 1              PTSD_orig           <NA>   NA    4710 (94.2%)
#> 2 symptom_6_7_9_16_17_19 6_7_9_16_17_19    1   4678 (93.56%)
#> 3  symptom_4_6_7_9_17_19  4_6_7_9_17_19    2    4685 (93.7%)
#> 4  symptom_4_6_7_9_12_17  4_6_7_9_12_17    3   4681 (93.62%)
#>   Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1          290 (5.8%)          4710           290               0
#> 2         322 (6.44%)          4598           210              80
#> 3          315 (6.3%)          4601           206              84
#> 4         319 (6.38%)          4598           207              83
#>   Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity    PPV
#> 1                   0       5000           0      1.0000      1.0000 1.0000
#> 2                 112       4808         192      0.9762      0.7241 0.9829
#> 3                 109       4807         193      0.9769      0.7103 0.9821
#> 4                 112       4805         195      0.9762      0.7138 0.9823
#>      NPV Accuracy
#> 1 1.0000   1.0000
#> 2 0.6522   0.9616
#> 3 0.6540   0.9614
#> 4 0.6489   0.9610
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
