# External Validation of Simplified PTSD Criteria

## 1. Introduction

A key question when developing simplified diagnostic criteria is whether
combinations optimized on one sample generalize to a different
population. The `PTSDdiag` package supports a derivation-validation
framework where:

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

We will use
[`optimize_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
and
[`optimize_combinations_clusters()`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations_clusters.md)
to find the 10 best six-symptom combinations in the veteran data, then
apply them to the general population data using
[`apply_symptom_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md).

## 2. Loading Required Packages

``` r
library("PTSDdiag")
```

## 3. Preparing the Data

### 3.1. Derivation Dataset (Veterans)

The derivation dataset represents a clinical veteran sample with high
PTSD prevalence. We load it and standardize column names.

``` r
# Load the veteran sample
data("simulated_ptsd")

# Standardize column names
veterans <- rename_ptsd_columns(simulated_ptsd)
```

Let’s check the PTSD prevalence in this sample:

``` r
veterans_total <- calculate_ptsd_total(veterans)
veterans_dx <- create_ptsd_diagnosis_nonbinarized(veterans_total)
veterans_summary <- summarize_ptsd(veterans_dx)
print(veterans_summary)
#>   mean_total sd_total n_diagnosed
#> 1     57.772 12.36218        4710
```

### 3.2. Validation Dataset (General Population)

The validation dataset represents a general population sample with a
more realistic, lower PTSD prevalence.

``` r
# Load the general population sample
data("simulated_ptsd_genpop")

# Standardize column names
genpop <- rename_ptsd_columns(simulated_ptsd_genpop)
```

Let’s check the PTSD prevalence in this sample:

``` r
genpop_total <- calculate_ptsd_total(genpop)
genpop_dx <- create_ptsd_diagnosis_nonbinarized(genpop_total)
genpop_summary <- summarize_ptsd(genpop_dx)
print(genpop_summary)
#>   mean_total sd_total n_diagnosed
#> 1   23.63667 15.47307         252
```

The prevalence difference between the two samples is important:
diagnostic metrics like PPV and NPV are strongly affected by base rates.
A simplified criterion that works well in a high-prevalence sample may
perform differently when most individuals do not have PTSD.

## 4. Deriving Optimal Combinations

We use the veteran data to find the 10 best six-symptom combinations
(requiring 4 present for diagnosis), optimizing to minimize total
misclassifications (`score_by = "false_cases"`).

### 4.1. Non-Hierarchical (Top 10)

The non-hierarchical approach selects the best symptoms regardless of
which DSM-5 cluster they belong to.

``` r
results_nonhier <- optimize_combinations(
  veterans,
  n_symptoms = 6,
  n_required = 4,
  n_top = 10,
  score_by = "false_cases"
)

# View the 10 best symptom combinations
results_nonhier$best_symptoms

# View diagnostic metrics on the derivation sample
results_nonhier$summary
```

### 4.2. Hierarchical (Top 10)

The hierarchical approach ensures that each combination includes at
least one symptom from each DSM-5 criterion cluster, maintaining the
diagnostic structure.

``` r
# Define the PCL-5 cluster structure
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

# View the 10 best symptom combinations
results_hier$best_symptoms

# View diagnostic metrics on the derivation sample
results_hier$summary
```

## 5. Sharing Combinations Across Research Groups

In practice, the derivation and validation steps may be performed by
different research groups, each working with their own dataset. The
[`write_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/write_combinations.md)
and
[`read_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/read_combinations.md)
functions allow you to export derived combinations to a human-readable
JSON file and share them with collaborators.

### 5.1. Exporting Combinations

After deriving optimal combinations, export them along with the relevant
parameters:

``` r
# Export non-hierarchical combinations
write_combinations(
  results_nonhier$best_symptoms,
  file = "veteran_nonhier_top10.json",
  n_required = 4,
  score_by = "false_cases",
  description = "Top 10 non-hierarchical 6-symptom combinations from veteran sample (N=5000)"
)

# Export hierarchical combinations (include cluster structure)
write_combinations(
  results_hier$best_symptoms,
  file = "veteran_hier_top10.json",
  n_required = 4,
  clusters = pcl5_clusters,
  score_by = "false_cases",
  description = "Top 10 hierarchical 6-symptom combinations from veteran sample (N=5000)"
)
```

The resulting JSON files are human-readable and contain all information
needed to apply the combinations:

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
    [1, 6, 8, 10, 15, 19],
    ...
  ],
  "combination_ids": ["1_6_8_10_15_19", ...],
  "ranks": [1, ...]
}
```

### 5.2. Importing and Applying Combinations

A collaborator can load the file and apply the combinations to their own
data:

``` r
# Read combinations from file
spec <- read_combinations("veteran_nonhier_top10.json")

# Inspect what was loaded
spec$n_required
spec$clusters
spec$description

# Apply to local dataset
comparison <- apply_symptom_combinations(
  genpop,
  combinations = spec$combinations,
  n_required = spec$n_required,
  clusters = spec$clusters
)

# Compute diagnostic accuracy
metrics <- summarize_ptsd_changes(comparison)
create_readable_summary(metrics)
```

This workflow ensures that the exact same combinations and parameters
are used across research groups, improving replicability.

## 6. External Validation

Now we apply the veteran-derived combinations to the general population
sample and assess how well they reproduce the full DSM-5 diagnosis in
this new population.

### 6.1. Applying Non-Hierarchical Combinations

[`apply_symptom_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
takes the general population data and the combinations derived from the
veteran sample. It returns a comparison dataframe with the full DSM-5
diagnosis (`PTSD_orig`) and the simplified diagnosis for each
combination.

``` r
# Apply the 10 non-hierarchical combinations to general population data
comparison_nonhier <- apply_symptom_combinations(
  genpop,
  combinations = results_nonhier$best_symptoms,
  n_required = 4
)

# Inspect the comparison dataframe
head(comparison_nonhier)

# Calculate diagnostic accuracy metrics
metrics_nonhier <- summarize_ptsd_changes(comparison_nonhier)
summary_nonhier <- create_readable_summary(metrics_nonhier)
summary_nonhier
```

### 6.2. Applying Hierarchical Combinations

For hierarchical combinations, we additionally pass the cluster
structure so that the diagnosis check verifies cluster representation
among the present symptoms.

``` r
# Apply the 10 hierarchical combinations to general population data
comparison_hier <- apply_symptom_combinations(
  genpop,
  combinations = results_hier$best_symptoms,
  n_required = 4,
  clusters = pcl5_clusters
)

# Calculate diagnostic accuracy metrics
metrics_hier <- summarize_ptsd_changes(comparison_hier)
summary_hier <- create_readable_summary(metrics_hier)
print(summary_hier)
```

## 7. Interpreting Results

When comparing derivation and validation performance, several points are
important to consider:

- **Sensitivity** may decrease in the validation sample if the
  simplified criteria were overfit to the derivation sample’s specific
  symptom patterns.

- **Specificity** often changes substantially between high-prevalence
  and low-prevalence settings because the pool of true negatives is much
  larger in the general population.

- **PPV (Positive Predictive Value)** is strongly influenced by base
  rates. In a low-prevalence setting (~20%), even a highly specific test
  will have more false positives relative to true positives. This
  typically results in lower PPV compared to the derivation sample.

- **NPV (Negative Predictive Value)** tends to be high in low-prevalence
  settings because most negative results are true negatives.

- **Hierarchical vs. Non-Hierarchical**: The hierarchical approach may
  show higher specificity in the general population because requiring
  cluster representation acts as an additional filter, reducing false
  positives. The non-hierarchical approach may show higher sensitivity
  because it is less restrictive.

## 8. Conclusion

The
[`apply_symptom_combinations()`](https://tobiasrspiller.github.io/PTSDdiag/reference/apply_symptom_combinations.md)
function enables a straightforward derivation-validation workflow:
derive optimal combinations on one dataset and test their
generalizability on another. By separating the application step
(creating diagnosis columns) from the summary step
([`summarize_ptsd_changes()`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_ptsd_changes.md)),
users have full flexibility to combine, compare, and analyze results
across multiple approaches and datasets.
