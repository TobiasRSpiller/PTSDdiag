# Summarize changes in PTSD diagnostic metrics

Compares different PTSD diagnostic criteria by calculating diagnostic
accuracy metrics and changes in diagnosis status relative to a baseline
criterion.

## Usage

``` r
summarize_ptsd_changes(data)
```

## Arguments

- data:

  A dataframe where:

  - Each column represents a different diagnostic criterion

  - Must include a column named "PTSD_orig" as the baseline criterion

  - Values are logical (TRUE/FALSE) indicating whether PTSD criteria are
    met

  - Each row represents one case/participant

## Value

A dataframe containing the following columns for each diagnostic
criterion:

- column: Name of the diagnostic criterion

- diagnosed: Number of cases diagnosed as PTSD

- non_diagnosed: Number of cases not diagnosed as PTSD

- diagnosed_percent: Percentage of cases diagnosed

- non_diagnosed_percent: Percentage of cases not diagnosed

- newly_diagnosed: Cases diagnosed under new but not baseline criterion
  (false positive)

- newly_nondiagnosed: Cases diagnosed under baseline but not new
  criterion (false negative)

- true_positive: Cases diagnosed under both criteria

- true_negative: Cases not diagnosed under either criterion

- true_cases: Sum of true positives and true negatives

- false_cases: Sum of newly diagnosed (false positive) and newly
  non-diagnosed (false negative)

- sensitivity, specificity, ppv, npv: Standard diagnostic accuracy
  metrics

## Details

The function calculates multiple diagnostic metrics comparing each
diagnostic criterion to a baseline criterion (PTSD_orig):

Basic counts:

- Number and percentage of diagnosed/non-diagnosed cases per criterion

- Number of newly diagnosed (false positive) and newly non-diagnosed
  (false negative) cases

- True positive and true negative cases

Diagnostic accuracy metrics:

- Sensitivity: Proportion of true PTSD cases correctly identified

- Specificity: Proportion of non-PTSD cases correctly identified

- PPV (Positive Predictive Value): Probability that a positive diagnosis
  is correct

- NPV (Negative Predictive Value): Probability that a negative diagnosis
  is correct

## Examples

``` r
# Create sample diagnostic data
set.seed(123)
n_cases <- 100
sample_data <- data.frame(
  PTSD_orig = sample(c(TRUE, FALSE), n_cases, replace = TRUE),
  PTSD_alt1 = sample(c(TRUE, FALSE), n_cases, replace = TRUE),
  PTSD_alt2 = sample(c(TRUE, FALSE), n_cases, replace = TRUE)
)

# Calculate diagnostic metrics
diagnostic_metrics <- summarize_ptsd_changes(sample_data)
diagnostic_metrics
#>              column diagnosed non_diagnosed newly_diagnosed newly_nondiagnosed
#> PTSD_orig PTSD_orig        57            43               0                  0
#> PTSD_alt1 PTSD_alt1        46            54              20                 31
#> PTSD_alt2 PTSD_alt2        51            49              26                 32
#>           true_positive true_negative true_cases false_cases sensitivity
#> PTSD_orig            57            43        100           0   1.0000000
#> PTSD_alt1            26            23         49          51   0.4561404
#> PTSD_alt2            25            17         42          58   0.4385965
#>           specificity       ppv       npv diagnosed_percent
#> PTSD_orig   1.0000000 1.0000000 1.0000000                57
#> PTSD_alt1   0.5348837 0.5652174 0.4259259                46
#> PTSD_alt2   0.3953488 0.4901961 0.3469388                51
#>           non_diagnosed_percent
#> PTSD_orig                    43
#> PTSD_alt1                    54
#> PTSD_alt2                    49
```
