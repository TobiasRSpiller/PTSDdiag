# External Validation with PCL-5 Data

## 1. Introduction

A central question when developing simplified diagnostic criteria is
whether combinations optimised on one sample generalise to a different
population. `PTSDdiag` supports a derivation-validation framework where:

- Optimal symptom combinations are **derived** from a clinical sample
  (e.g., veterans with high PTSD prevalence)
- Those combinations are then **validated** on an independent sample
  (e.g., a general population with lower prevalence)

This vignette demonstrates this workflow using two simulated datasets
included in the package:

- `simulated_ptsd`: A clinical veteran sample (N = 5,000, ~94% PTSD
  prevalence)
- `simulated_ptsd_genpop`: A general population sample (N = 1,200, ~21%
  PTSD prevalence)

We use
[`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
and
[`optimize_combinations_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
to find the 10 best six-symptom combinations in the veteran data, then
apply them to the general population data using
[`apply_symptom_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md).

For a single-dataset workflow (optimisation and internal validation),
see the [Full Internal
Analysis](https://tobiasrspiller.github.io/PTSDdiag/articles/internal_analysis.md)
vignette. For validation against the CAPS-5 gold standard, see the
[External Validation
(CAPS-5)](https://tobiasrspiller.github.io/PTSDdiag/articles/external_validation_caps5.md)
vignette.

## 2. Loading packages

``` r

library("PTSDdiag")
```

## 3. Preparing the data

### 3.1. Derivation dataset (veterans)

The derivation dataset represents a clinical veteran sample with high
PTSD prevalence.

``` r

data("simulated_ptsd")
veterans <- rename_ptsd_columns(simulated_ptsd)
```

PTSD prevalence in this sample:

``` r

veterans_total <- calculate_ptsd_total(veterans)
veterans_dx <- create_ptsd_diagnosis_nonbinarized(veterans_total)
veterans_summary <- summarize_ptsd(veterans_dx)
print(veterans_summary)
#>   mean_total sd_total n_diagnosed
#> 1     57.772 12.36218        4710
```

### 3.2. Validation dataset (general population)

The validation dataset represents a general population sample with a
more realistic, lower PTSD prevalence.

``` r

data("simulated_ptsd_genpop")
genpop <- rename_ptsd_columns(simulated_ptsd_genpop)
```

PTSD prevalence in this sample:

``` r

genpop_total <- calculate_ptsd_total(genpop)
genpop_dx <- create_ptsd_diagnosis_nonbinarized(genpop_total)
genpop_summary <- summarize_ptsd(genpop_dx)
print(genpop_summary)
#>   mean_total sd_total n_diagnosed
#> 1   23.63667 15.47307         252
```

The prevalence difference matters: PPV and NPV are strongly affected by
base rates. A simplified criterion that performs well in a
high-prevalence sample may behave differently when most individuals do
not have PTSD.

## 4. Deriving optimal combinations

We use the veteran data to find the 10 best six-symptom combinations
(requiring 4 present for diagnosis), optimising to minimise total
misclassifications (`score_by = "false_cases"`).

### 4.1. Non-hierarchical (top 10)

The non-hierarchical approach selects the best symptoms regardless of
DSM-5 cluster membership.

``` r

results_nonhier <- optimize_combinations(
  veterans,
  n_symptoms = 6,
  n_required = 4,
  n_top = 10,
  score_by = "false_cases"
)

results_nonhier$best_symptoms
results_nonhier$summary
```

### 4.2. Hierarchical (top 10)

The hierarchical approach ensures that each combination includes at
least one symptom from each DSM-5 criterion cluster.

``` r

pcl5_clusters <- list(
  B = 1:5,     # Intrusion
  C = 6:7,     # Avoidance
  D = 8:14,    # Negative alterations in cognitions and mood
  E = 15:20    # Alterations in arousal and reactivity
)

results_hier <- optimize_combinations_clusters(
  veterans,
  n_symptoms = 6,
  n_required = 4,
  n_top = 10,
  score_by = "false_cases",
  clusters = pcl5_clusters
)

results_hier$best_symptoms
results_hier$summary
```

## 5. Sharing combinations across research groups

Derivation and validation may be performed by different research groups,
each with their own dataset.
[`write_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md)
and
[`read_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
enable this workflow via human-readable JSON files.

### 5.1. Exporting combinations

After deriving optimal combinations, export them along with the relevant
parameters:

``` r

write_combinations(
  results_nonhier$best_symptoms,
  file = "veteran_nonhier_top10.json",
  n_required = 4,
  score_by = "false_cases",
  description = "Top 10 non-hierarchical 6-symptom combinations from veteran sample (N=5000)"
)

write_combinations(
  results_hier$best_symptoms,
  file = "veteran_hier_top10.json",
  n_required = 4,
  clusters = pcl5_clusters,
  score_by = "false_cases",
  description = "Top 10 hierarchical 6-symptom combinations from veteran sample (N=5000)"
)
```

The resulting JSON files contain all information needed to apply the
combinations:

``` json
{
  "ptsddiag_version": "0.2.1",
  "created_at": "2025-06-01T12:00:00+0000",
  "description": "Top 10 non-hierarchical ...",
  "parameters": {
    "n_symptoms": 6,
    "n_required": 4,
    "score_by": "false_cases",
    "clusters": null
  },
  "combinations": [
    [1, 6, 8, 10, 15, 19]
  ],
  "combination_ids": ["1_6_8_10_15_19"],
  "ranks": [1]
}
```

### 5.2. Importing and applying combinations

A collaborator can load the file and apply the combinations to their own
data:

``` r

spec <- read_combinations("veteran_nonhier_top10.json")

spec$n_required
spec$clusters
spec$description

comparison <- apply_symptom_combinations(
  genpop,
  combinations = spec$combinations,
  n_required = spec$n_required,
  clusters = spec$clusters
)

metrics <- summarize_ptsd_changes(comparison)
create_readable_summary(metrics)
```

This workflow ensures that the exact same combinations and parameters
are used across research groups.

## 6. External validation

We now apply the veteran-derived combinations to the general population
sample and assess how well they reproduce the full DSM-5 diagnosis in
this new population.

### 6.1. Applying non-hierarchical combinations

[`apply_symptom_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
takes the general population data and the combinations derived from the
veteran sample. It returns a comparison dataframe with the full DSM-5
diagnosis (`PTSD_orig`) and the simplified diagnosis for each
combination.

``` r

comparison_nonhier <- apply_symptom_combinations(
  genpop,
  combinations = results_nonhier$best_symptoms,
  n_required = 4
)

head(comparison_nonhier)

metrics_nonhier <- summarize_ptsd_changes(comparison_nonhier)
summary_nonhier <- create_readable_summary(metrics_nonhier)
summary_nonhier
```

### 6.2. Applying hierarchical combinations

For hierarchical combinations, the cluster structure is additionally
passed so that the diagnosis check verifies cluster representation among
the present symptoms.

``` r

comparison_hier <- apply_symptom_combinations(
  genpop,
  combinations = results_hier$best_symptoms,
  n_required = 4,
  clusters = pcl5_clusters
)

metrics_hier <- summarize_ptsd_changes(comparison_hier)
summary_hier <- create_readable_summary(metrics_hier)
print(summary_hier)
```

## 7. Interpreting results

When comparing derivation and validation performance, several points
deserve attention:

- **Sensitivity** may decrease in the validation sample if the
  simplified criteria were overfit to the derivation sample’s symptom
  patterns.

- **Specificity** often changes substantially between high-prevalence
  and low-prevalence settings because the pool of true negatives is much
  larger in the general population.

- **PPV** is strongly influenced by base rates. In a low-prevalence
  setting (~20%), even a highly specific test will produce more false
  positives relative to true positives, typically resulting in lower PPV
  than in the derivation sample.

- **NPV** tends to be high in low-prevalence settings because most
  negative results are true negatives.

- **Hierarchical vs. non-hierarchical**: The hierarchical approach may
  show higher specificity in the general population because requiring
  cluster representation acts as an additional filter, reducing false
  positives. The non-hierarchical approach may show higher sensitivity
  because it is less restrictive.

## 8. Conclusion

[`apply_symptom_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
separates the application step from the summary step
([`summarize_ptsd_changes()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)),
giving users full flexibility to combine and compare results across
approaches and datasets.

For validation against the CAPS-5 clinician-administered gold standard,
see the [External Validation
(CAPS-5)](https://tobiasrspiller.github.io/PTSDdiag/articles/external_validation_caps5.md)
vignette.
