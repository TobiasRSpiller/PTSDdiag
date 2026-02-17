# Create readable summary of PTSD diagnostic changes

Formats the output of summarize_ptsd_changes() into a more readable
table with proper labels and formatting of percentages and metrics.

## Usage

``` r
create_readable_summary(summary_stats)
```

## Arguments

- summary_stats:

  A dataframe output from summarize_ptsd_changes() containing raw
  diagnostic metrics and counts

## Value

A formatted dataframe with the following columns:

- Scenario: Name of the diagnostic criterion

- Total Diagnosed: Count and percentage of diagnosed cases

- Total Non-Diagnosed: Count and percentage of non-diagnosed cases

- True Positive: Count of cases diagnosed under both criteria

- True Negative: Count of cases not diagnosed under either criterion

- Newly Diagnosed: Count of new positive diagnoses (false positive)

- Newly Non-Diagnosed: Count of new negative diagnoses (false negative)

- True Cases: Total correctly classified cases

- False Cases: Total misclassified cases

- Sensitivity, Specificity, PPV, NPV: Diagnostic accuracy metrics (4
  decimals)

## Details

Reformats the diagnostic metrics into a presentation-ready format:

- Combines counts with percentages for diagnosed/non-diagnosed cases

- Rounds diagnostic accuracy metrics to 4 decimal places

- Provides clear column headers for all metrics

## Examples

``` r
# Using the output from summarize_ptsd_changes
n_cases <- 100
sample_data <- data.frame(
  PTSD_orig = sample(c(TRUE, FALSE), n_cases, replace = TRUE),
  PTSD_alt1 = sample(c(TRUE, FALSE), n_cases, replace = TRUE)
)

# Generate and format summary
diagnostic_metrics <- summarize_ptsd_changes(sample_data)
readable_summary <- create_readable_summary(diagnostic_metrics)
print(readable_summary)
#>    Scenario Total Diagnosed Total Non-Diagnosed True Positive True Negative
#> 1 PTSD_orig        57 (57%)            43 (43%)            57            43
#> 2 PTSD_alt1        60 (60%)            40 (40%)            33            16
#>   Newly Diagnosed Newly Non-Diagnosed True Cases False Cases Sensitivity
#> 1               0                   0        100           0      1.0000
#> 2              27                  24         49          51      0.5789
#>   Specificity  PPV NPV
#> 1      1.0000 1.00 1.0
#> 2      0.3721 0.55 0.4
```
