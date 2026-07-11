# Validating a shared definition across sites

This vignette illustrates how two sites that cannot share patient-level
data, can still be used to derive and validate a simplified PTSD
definition.

## The multi-site problem

Collaborations across clinics, registries, or countries are often bound
by privacy rules and data-use agreements that forbid moving patient
records between sites. Hence, pooling data is often not possible.
However, as a simplified definition is fully described by the symptom
indices it uses and the number required, optimization can take place at
one site and validation at another without sharing the original data,
only the symptom sets constituting the new definitions.

In this vignette, one site has data from the veterans with a high PTSD
prevalence and another has population data with a low PTSD prevalence.
The first site derives a definition and inspects which symptoms its
optimization selects. It shares the definitions as a JSON file. The
general-population site then applies that definition locally, and we
compare how it performs in each sample.

## Requirements for the input data

Each site standardizes its own data with
[`rename_ptsd_columns()`](https://tobiasrspiller.github.io/PTSDdiag/reference/rename_ptsd_columns.md):
the 20 PCL-5 items in their standard order, scored 0 to 4, with no
missing values, plus any identifier columns named in `id_col`. The full
contract is in the [Getting
started](https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.md)
vignette. For this vignette, we subset the veteran sample to 250 rows to
keep the optimization fast.

## Site 1: deriving the definition in the veteran sample

The veteran site optimizes on its own data.
[`compare_optimizations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
runs the three default rules and returns one object holding the results;
nothing patient-level leaves the site.

``` r

library(PTSDdiag)
library(dplyr)

data("simulated_ptsd")
vet <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                           id_col = c("patient_id", "age", "sex"))

comp_vet <- compare_optimizations(
  vet,
  n_top         = 10,
  score_by      = "balanced_accuracy",
  show_progress = FALSE
)
```

Before sharing anything, the site can look at which symptoms its
optimization keeps selecting.
[`plot_symptom_frequency()`](https://tobiasrspiller.github.io/PTSDdiag/reference/plot_symptom_frequency.md)
shows, for each rule, how often each of the 20 symptoms appears among
the top combinations, with a pooled OVERALL row.

``` r

plot_symptom_frequency(comp_vet, type = "relative")
```

![Heatmap of PCL-5 symptom selection frequency in the veteran
sample](multi-site-validation_files/figure-html/figure-1.png)

The symptoms whose tiles are dark across the rules are the core symptoms
the derivation settles on. These are stable features of the veteran
sample, and the question for the collaboration is whether a definition
built from them also works elsewhere.

## Sharing the definitions without sharing data

Rather than commit to a single winner, the site carries forward the top
five combinations from each of the three rules, fifteen candidate
definitions in all. This is closer to real practice, where a
collaboration weighs several promising definitions rather than betting
on one.
[`extract_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/extract_definitions.md)
pulls them straight from the comparison object: it keeps the top `n`
combinations of each rule and reads, for each, how many symptoms must be
present and whether all four clusters are required, so the researcher
chooses only how many to carry.

``` r

definitions <- extract_definitions(comp_vet, n = 5)

# The shared object: only symptom numbers and the rule to apply them
lapply(definitions, function(d) d$symptoms)
#> $`4/6 Hierarchical`
#> $`4/6 Hierarchical`[[1]]
#> [1]  1  6  7 13 15 17
#> 
#> $`4/6 Hierarchical`[[2]]
#> [1]  1  3  7 13 15 17
#> 
#> $`4/6 Hierarchical`[[3]]
#> [1]  1  3  6 13 16 19
#> 
#> $`4/6 Hierarchical`[[4]]
#> [1]  1  4  6  7 11 17
#> 
#> $`4/6 Hierarchical`[[5]]
#> [1]  1  6  7 11 15 17
#> 
#> 
#> $`4/6 Non-hierarchical`
#> $`4/6 Non-hierarchical`[[1]]
#> [1]  6  7  8 11 13 17
#> 
#> $`4/6 Non-hierarchical`[[2]]
#> [1]  6  7 10 11 13 15
#> 
#> $`4/6 Non-hierarchical`[[3]]
#> [1]  4  6  7  8 11 17
#> 
#> $`4/6 Non-hierarchical`[[4]]
#> [1]  4  6  7 10 11 15
#> 
#> $`4/6 Non-hierarchical`[[5]]
#> [1]  6  7  8 11 13 18
#> 
#> 
#> $`3/6 Non-hierarchical`
#> $`3/6 Non-hierarchical`[[1]]
#> [1]  3  6  7 11 15 16
#> 
#> $`3/6 Non-hierarchical`[[2]]
#> [1]  4  6  7 12 15 19
#> 
#> $`3/6 Non-hierarchical`[[3]]
#> [1]  4  6  7 13 15 19
#> 
#> $`3/6 Non-hierarchical`[[4]]
#> [1]  6  7 10 12 15 19
#> 
#> $`3/6 Non-hierarchical`[[5]]
#> [1]  2  6  7  8 10 15
```

This object is everything the other site needs, and it holds nothing but
symptom numbers and rules. No participant, score, or demographic is in
it, so it can be shared freely.

In a real collaboration the definitions travel as files rather than as
an R object.
[`write_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md)
serializes one rule’s combinations to a small JSON file; the optional
`label` stores the rule’s display name in the file, so tables produced
at the receiving site are labelled by the derivation site automatically.
A temporary file stands in for the transfer here.

``` r

json_file <- tempfile(fileext = ".json")
write_combinations(
  definitions[["4/6 Hierarchical"]]$symptoms, json_file,
  n_required  = 4,
  clusters    = list(B = 1:5, C = 6:7, D = 8:14, E = 15:20),
  label       = "4/6 Hierarchical",
  description = "Top 5 hierarchical combinations, veteran derivation sample"
)
#> ✔ Combinations written to /tmp/RtmpOKoo85/file1f475a80ddea.json
```

At the other end,
[`read_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
imports the file and
[`as_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/as_definitions.md)
turns one or several imported files into the same definitions structure
[`extract_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/extract_definitions.md)
produces — `lapply(files, read_combinations)` handles a whole folder of
rules in one line. The round trip reproduces the shared definition
exactly:

``` r

received <- as_definitions(read_combinations(json_file))

all.equal(received[["4/6 Hierarchical"]]$symptoms,
          definitions[["4/6 Hierarchical"]]$symptoms)
#> [1] TRUE
```

## Evaluating every definition in a sample

Alongside the fifteen derived definitions we include ICD-11 as a fixed
published benchmark. ICD-11 is the same rule everywhere, so each site
computes it locally and nothing about it is shared.
[`evaluate_definitions()`](https://tobiasrspiller.github.io/PTSDdiag/reference/evaluate_definitions.md)
applies each shared definition with its own rule, adds ICD-11, and
scores all of them against the sample’s full DSM-5-TR diagnosis. Because
it needs only the definitions and a data frame, the identical call runs
at either site.

## Performance in the derivation sample

The veteran site records how every definition performs on its own
patients, the baseline the other site will be read against.

``` r

evaluate_definitions(vet, definitions, include_icd11 = TRUE)
#>                                       Scenario Total Diagnosed
#> 1                                    PTSD_orig     232 (92.8%)
#> 2       4/6 Hierarchical (1, 6, 7, 13, 15, 17)     213 (85.2%)
#> 3       4/6 Hierarchical (1, 3, 7, 13, 15, 17)     213 (85.2%)
#> 4       4/6 Hierarchical (1, 3, 6, 13, 16, 19)     213 (85.2%)
#> 5        4/6 Hierarchical (1, 4, 6, 7, 11, 17)     213 (85.2%)
#> 6       4/6 Hierarchical (1, 6, 7, 11, 15, 17)     212 (84.8%)
#> 7   4/6 Non-hierarchical (6, 7, 8, 11, 13, 17)       230 (92%)
#> 8  4/6 Non-hierarchical (6, 7, 10, 11, 13, 15)       230 (92%)
#> 9    4/6 Non-hierarchical (4, 6, 7, 8, 11, 17)     229 (91.6%)
#> 10  4/6 Non-hierarchical (4, 6, 7, 10, 11, 15)     229 (91.6%)
#> 11  4/6 Non-hierarchical (6, 7, 8, 11, 13, 18)     229 (91.6%)
#> 12  3/6 Non-hierarchical (3, 6, 7, 11, 15, 16)     237 (94.8%)
#> 13  3/6 Non-hierarchical (4, 6, 7, 12, 15, 19)     237 (94.8%)
#> 14  3/6 Non-hierarchical (4, 6, 7, 13, 15, 19)     237 (94.8%)
#> 15 3/6 Non-hierarchical (6, 7, 10, 12, 15, 19)     237 (94.8%)
#> 16   3/6 Non-hierarchical (2, 6, 7, 8, 10, 15)     236 (94.4%)
#> 17                                      ICD-11     222 (88.8%)
#>    Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1            18 (7.2%)           232            18               0
#> 2           37 (14.8%)           213            18               0
#> 3           37 (14.8%)           213            18               0
#> 4           37 (14.8%)           213            18               0
#> 5           37 (14.8%)           213            18               0
#> 6           38 (15.2%)           212            18               0
#> 7              20 (8%)           229            17               1
#> 8              20 (8%)           229            17               1
#> 9            21 (8.4%)           228            17               1
#> 10           21 (8.4%)           228            17               1
#> 11           21 (8.4%)           228            17               1
#> 12           13 (5.2%)           232            13               5
#> 13           13 (5.2%)           232            13               5
#> 14           13 (5.2%)           232            13               5
#> 15           13 (5.2%)           232            13               5
#> 16           14 (5.6%)           231            13               5
#> 17          28 (11.2%)           220            16               2
#>    Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity    PPV
#> 1                    0        250           0      1.0000      1.0000 1.0000
#> 2                   19        231          19      0.9181      1.0000 1.0000
#> 3                   19        231          19      0.9181      1.0000 1.0000
#> 4                   19        231          19      0.9181      1.0000 1.0000
#> 5                   19        231          19      0.9181      1.0000 1.0000
#> 6                   20        230          20      0.9138      1.0000 1.0000
#> 7                    3        246           4      0.9871      0.9444 0.9957
#> 8                    3        246           4      0.9871      0.9444 0.9957
#> 9                    4        245           5      0.9828      0.9444 0.9956
#> 10                   4        245           5      0.9828      0.9444 0.9956
#> 11                   4        245           5      0.9828      0.9444 0.9956
#> 12                   0        245           5      1.0000      0.7222 0.9789
#> 13                   0        245           5      1.0000      0.7222 0.9789
#> 14                   0        245           5      1.0000      0.7222 0.9789
#> 15                   0        245           5      1.0000      0.7222 0.9789
#> 16                   1        244           6      0.9957      0.7222 0.9788
#> 17                  12        236          14      0.9483      0.8889 0.9910
#>       NPV Accuracy Balanced Accuracy
#> 1  1.0000    1.000            1.0000
#> 2  0.4865    0.924            0.9591
#> 3  0.4865    0.924            0.9591
#> 4  0.4865    0.924            0.9591
#> 5  0.4865    0.924            0.9591
#> 6  0.4737    0.920            0.9569
#> 7  0.8500    0.984            0.9658
#> 8  0.8500    0.984            0.9658
#> 9  0.8095    0.980            0.9636
#> 10 0.8095    0.980            0.9636
#> 11 0.8095    0.980            0.9636
#> 12 1.0000    0.980            0.8611
#> 13 1.0000    0.980            0.8611
#> 14 1.0000    0.980            0.8611
#> 15 1.0000    0.980            0.8611
#> 16 0.9286    0.976            0.8590
#> 17 0.5714    0.944            0.9186
```

The first row is the full DSM-5-TR diagnosis itself, the reference.
Below it are the fifteen derived definitions, grouped by rule, followed
by ICD-11, each scored against the reference.

## Validating in the general-population sample

The general-population site receives only the definitions printed above.
It runs the same evaluation on its own patients. The veteran site never
sees these records, and this site never sees the veteran records.

``` r

data("simulated_ptsd_genpop")

# simulated_ptsd_genpop also carries paired CAPS-5 columns (C1..C20); here we
# use only the PCL-5 items, so we select those before standardising.
genpop <- rename_ptsd_columns(
  simulated_ptsd_genpop[, c("patient_id", "age", "sex", paste0("S", 1:20))],
  id_col = c("patient_id", "age", "sex")
)

evaluate_definitions(genpop, definitions, include_icd11 = TRUE)
#>                                       Scenario Total Diagnosed
#> 1                                    PTSD_orig       252 (21%)
#> 2       4/6 Hierarchical (1, 6, 7, 13, 15, 17)     138 (11.5%)
#> 3       4/6 Hierarchical (1, 3, 7, 13, 15, 17)    137 (11.42%)
#> 4       4/6 Hierarchical (1, 3, 6, 13, 16, 19)     150 (12.5%)
#> 5        4/6 Hierarchical (1, 4, 6, 7, 11, 17)    158 (13.17%)
#> 6       4/6 Hierarchical (1, 6, 7, 11, 15, 17)    148 (12.33%)
#> 7   4/6 Non-hierarchical (6, 7, 8, 11, 13, 17)    224 (18.67%)
#> 8  4/6 Non-hierarchical (6, 7, 10, 11, 13, 15)    223 (18.58%)
#> 9    4/6 Non-hierarchical (4, 6, 7, 8, 11, 17)    224 (18.67%)
#> 10  4/6 Non-hierarchical (4, 6, 7, 10, 11, 15)    226 (18.83%)
#> 11  4/6 Non-hierarchical (6, 7, 8, 11, 13, 18)       228 (19%)
#> 12  3/6 Non-hierarchical (3, 6, 7, 11, 15, 16)    322 (26.83%)
#> 13  3/6 Non-hierarchical (4, 6, 7, 12, 15, 19)    333 (27.75%)
#> 14  3/6 Non-hierarchical (4, 6, 7, 13, 15, 19)    332 (27.67%)
#> 15 3/6 Non-hierarchical (6, 7, 10, 12, 15, 19)    345 (28.75%)
#> 16   3/6 Non-hierarchical (2, 6, 7, 8, 10, 15)    346 (28.83%)
#> 17                                      ICD-11    259 (21.58%)
#>    Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1            948 (79%)           252           948               0
#> 2         1062 (88.5%)           135           945               3
#> 3        1063 (88.58%)           135           946               2
#> 4         1050 (87.5%)           141           939               9
#> 5        1042 (86.83%)           156           946               2
#> 6        1052 (87.67%)           145           945               3
#> 7         976 (81.33%)           207           931              17
#> 8         977 (81.42%)           205           930              18
#> 9         976 (81.33%)           206           930              18
#> 10        974 (81.17%)           202           924              24
#> 11           972 (81%)           208           928              20
#> 12        878 (73.17%)           227           853              95
#> 13        867 (72.25%)           225           840             108
#> 14        868 (72.33%)           225           841             107
#> 15        855 (71.25%)           230           833             115
#> 16        854 (71.17%)           225           827             121
#> 17        941 (78.42%)           214           903              45
#>    Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity    PPV
#> 1                    0       1200           0      1.0000      1.0000 1.0000
#> 2                  117       1080         120      0.5357      0.9968 0.9783
#> 3                  117       1081         119      0.5357      0.9979 0.9854
#> 4                  111       1080         120      0.5595      0.9905 0.9400
#> 5                   96       1102          98      0.6190      0.9979 0.9873
#> 6                  107       1090         110      0.5754      0.9968 0.9797
#> 7                   45       1138          62      0.8214      0.9821 0.9241
#> 8                   47       1135          65      0.8135      0.9810 0.9193
#> 9                   46       1136          64      0.8175      0.9810 0.9196
#> 10                  50       1126          74      0.8016      0.9747 0.8938
#> 11                  44       1136          64      0.8254      0.9789 0.9123
#> 12                  25       1080         120      0.9008      0.8998 0.7050
#> 13                  27       1065         135      0.8929      0.8861 0.6757
#> 14                  27       1066         134      0.8929      0.8871 0.6777
#> 15                  22       1063         137      0.9127      0.8787 0.6667
#> 16                  27       1052         148      0.8929      0.8724 0.6503
#> 17                  38       1117          83      0.8492      0.9525 0.8263
#>       NPV Accuracy Balanced Accuracy
#> 1  1.0000   1.0000            1.0000
#> 2  0.8898   0.9000            0.7663
#> 3  0.8899   0.9008            0.7668
#> 4  0.8943   0.9000            0.7750
#> 5  0.9079   0.9183            0.8085
#> 6  0.8983   0.9083            0.7861
#> 7  0.9539   0.9483            0.9017
#> 8  0.9519   0.9458            0.8973
#> 9  0.9529   0.9467            0.8992
#> 10 0.9487   0.9383            0.8881
#> 11 0.9547   0.9467            0.9021
#> 12 0.9715   0.9000            0.9003
#> 13 0.9689   0.8875            0.8895
#> 14 0.9689   0.8883            0.8900
#> 15 0.9743   0.8858            0.8957
#> 16 0.9684   0.8767            0.8826
#> 17 0.9596   0.9308            0.9009
```

Both tables are built the same way, so they line up row for row with the
derivation table above.

## A tidy table for downstream analysis

The tables above are formatted for reading. For filtering, plotting, or
combining results across sites, request the same evaluation as a plain
analysis table with `tidy = TRUE`: one row per combination with
`Approach`, `Rank`, `Combination`, the 2x2 counts, and numeric metrics.
The layout matches
[`summarize_top_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md)
on the derivation side, so tables from both sites stack with
[`rbind()`](https://rdrr.io/r/base/cbind.html) — no label parsing
required.

``` r

tidy_gp <- evaluate_definitions(genpop, definitions, tidy = TRUE)
head(tidy_gp)
#>               Approach Rank         Combination  TP  FN FP  TN Sensitivity
#> 1     4/6 Hierarchical    1 1, 6, 7, 13, 15, 17 135 117  3 945   0.5357143
#> 2     4/6 Hierarchical    2 1, 3, 7, 13, 15, 17 135 117  2 946   0.5357143
#> 3     4/6 Hierarchical    3 1, 3, 6, 13, 16, 19 141 111  9 939   0.5595238
#> 4     4/6 Hierarchical    4  1, 4, 6, 7, 11, 17 156  96  2 946   0.6190476
#> 5     4/6 Hierarchical    5 1, 6, 7, 11, 15, 17 145 107  3 945   0.5753968
#> 6 4/6 Non-hierarchical    1 6, 7, 8, 11, 13, 17 207  45 17 931   0.8214286
#>   Specificity       PPV       NPV  Accuracy Balanced Accuracy
#> 1   0.9968354 0.9782609 0.8898305 0.9000000         0.7662749
#> 2   0.9978903 0.9854015 0.8899341 0.9008333         0.7668023
#> 3   0.9905063 0.9400000 0.8942857 0.9000000         0.7750151
#> 4   0.9978903 0.9873418 0.9078695 0.9183333         0.8084690
#> 5   0.9968354 0.9797297 0.8982890 0.9083333         0.7861161
#> 6   0.9820675 0.9241071 0.9538934 0.9483333         0.9017480
```

## Reading the two tables together

Each definition keeps its character across the two samples: the
hierarchical rule is the most specific and the least sensitive, the
three-of-six rule the most sensitive and the least specific, and the
four-of-six and ICD-11 rules fall between them. What changes with the
sample is the absolute level of performance. The positive predictive
value of every definition falls in the lower-prevalence community
sample, so a positive result there is less likely to mark a true case
than in the clinic. Sensitivity also drops, most visibly for the strict
hierarchical rule, because the community sample’s symptom profiles are
milder, while specificity holds or rises. These shifts are exactly what
external validation is meant to reveal, and they are why a definition
should not be transported across settings on its derivation performance
alone.

The agreement on core symptoms in the figure and the performance of
every definition in the two tables were obtained without moving a single
patient record between the sites. In a full collaboration the second
site would also optimize, and the two sites would combine their
selections into a cross-site consensus; the [Validating abbreviated
symptom
definitions](https://tobiasrspiller.github.io/PTSDdiag/articles/validation.md)
vignette covers the external-validation logic and the JSON mechanism in
more depth.

## See also

- [Getting
  started](https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.md)
  for the single-cohort derivation workflow.
- [Comparing diagnostic
  criteria](https://tobiasrspiller.github.io/PTSDdiag/articles/comparing-criteria.md)
  for the symptom-frequency tools and multi-rule comparison.
- [Validating abbreviated symptom
  definitions](https://tobiasrspiller.github.io/PTSDdiag/articles/validation.md)
  for internal and external validation.
- [CAPS-5
  workflow](https://tobiasrspiller.github.io/PTSDdiag/articles/caps5-workflow.md)
  for validation against a clinician-administered reference.
