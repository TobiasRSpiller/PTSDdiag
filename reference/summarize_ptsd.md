# Summarize PTSD scores and diagnoses

Creates a summary of PCL-5 total scores and PTSD diagnoses, including
mean total score, standard deviation, and number of positive diagnoses.

## Usage

``` r
summarize_ptsd(data)
```

## Arguments

- data:

  A dataframe containing at minimum:

  - A 'total' column with PCL-5 total scores (from calculate_ptsd_total)

  - A 'PTSD_Diagnosis' column with TRUE/FALSE values (from
    determine_ptsd_diagnosis)

## Value

A dataframe with one row containing:

- mean_total: Mean PCL-5 total score

- sd_total: Standard deviation of PCL-5 total scores

- n_diagnosed: Number of positive PTSD diagnoses

## Details

This function calculates key summary statistics for PCL-5 data:

- Mean total score (severity indicator)

- Standard deviation of total scores (variability in severity)

- Count of positive PTSD diagnoses (prevalence in the sample)

## Examples

``` r
# Create sample data
sample_data <- data.frame(
  total = sample(0:80, 100, replace = TRUE),
  PTSD_Diagnosis = sample(c(TRUE, FALSE), 100, replace = TRUE)
)

# Generate summary statistics
summary_stats <- summarize_ptsd(sample_data)
print(summary_stats)
#>   mean_total sd_total n_diagnosed
#> 1      40.83 21.92322          58
```
