# Calculate PTSD total score

Calculates the total PCL-5 (PTSD Checklist for DSM-5) score by summing
all 20 symptom scores. The total score ranges from 0 to 80, with higher
scores indicating greater symptom severity.

## Usage

``` r
calculate_ptsd_total(data)
```

## Arguments

- data:

  A dataframe containing standardized PCL-5 item scores (output of
  rename_ptsd_columns). Each symptom should be scored on a 0-4 scale
  where:

  - 0 = Not at all

  - 1 = A little bit

  - 2 = Moderately

  - 3 = Quite a bit

  - 4 = Extremely

## Value

A dataframe with all original columns plus an additional column "total"
containing the sum of all 20 symptom scores (range: 0-80)

## Details

Calculates the total score from PCL-5 items

## Examples

``` r
# Create sample data
sample_data <- data.frame(
  matrix(sample(0:4, 20 * 10, replace = TRUE),
         nrow = 10,
         ncol = 20)
)
colnames(sample_data) <- paste0("symptom_", 1:20)

# Calculate total scores
scores_with_total <- calculate_ptsd_total(sample_data)
print(scores_with_total$total)
#>  [1] 38 28 43 38 34 31 37 42 25 36
```
