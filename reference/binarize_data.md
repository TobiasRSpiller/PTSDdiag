# Binarize PCL-5 symptom scores

Converts PCL-5 symptom scores from their original 0-4 scale to binary
values (0/1) based on the clinical threshold for symptom presence
(\>=2).

## Usage

``` r
binarize_data(data)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns with PCL-5 item scores
  (output of rename_ptsd_columns). Each symptom should be scored on a
  0-4 scale where:

  - 0 = Not at all

  - 1 = A little bit

  - 2 = Moderately

  - 3 = Quite a bit

  - 4 = Extremely

  Note: This function should only be used with raw symptom scores before
  calculating the total score, as it will convert all values in the
  dataframe to 0/1, which would invalidate any total score column if
  present.

## Value

A dataframe with the same structure as input but with all symptom scores
converted to binary values:

- 0 = Symptom absent (original scores 0-1)

- 1 = Symptom present (original scores 2-4)

## Details

The function implements the standard clinical threshold for PTSD symptom
presence where:

- Scores of 0-1 ("Not at all" and "A little bit") → 0 (symptom absent)

- Scores of 2-4 ("Moderately" to "Extremely") → 1 (symptom present)

## Examples

``` r
# Create sample data
sample_data <- data.frame(
  matrix(sample(0:4, 20 * 10, replace = TRUE),
         nrow = 10,
         ncol = 20)
)
colnames(sample_data) <- paste0("symptom_", 1:20)

# Binarize scores
binary_data <- binarize_data(sample_data)
binary_data # Should only show 0s and 1s
#>    symptom_1 symptom_2 symptom_3 symptom_4 symptom_5 symptom_6 symptom_7
#> 1          1         1         0         0         1         0         1
#> 2          0         1         1         0         1         1         1
#> 3          1         1         1         0         0         1         0
#> 4          1         0         1         1         1         0         1
#> 5          1         1         1         1         1         1         1
#> 6          1         1         0         1         1         0         1
#> 7          1         1         1         1         1         0         0
#> 8          0         1         0         0         1         1         1
#> 9          1         0         0         1         1         1         1
#> 10         0         1         1         0         1         0         1
#>    symptom_8 symptom_9 symptom_10 symptom_11 symptom_12 symptom_13 symptom_14
#> 1          1         0          1          1          0          0          0
#> 2          1         0          0          1          1          0          1
#> 3          0         1          0          0          1          1          1
#> 4          1         1          0          0          1          0          1
#> 5          1         0          1          1          0          1          0
#> 6          0         0          1          0          0          1          1
#> 7          1         1          1          1          1          0          1
#> 8          1         1          1          0          1          0          1
#> 9          1         1          1          0          0          0          1
#> 10         0         1          0          1          1          0          0
#>    symptom_15 symptom_16 symptom_17 symptom_18 symptom_19 symptom_20
#> 1           1          0          1          1          1          1
#> 2           0          1          1          0          1          0
#> 3           0          1          1          0          0          1
#> 4           1          1          0          1          1          1
#> 5           0          1          1          1          0          1
#> 6           1          1          0          0          0          0
#> 7           0          0          1          1          1          0
#> 8           1          0          0          0          0          1
#> 9           1          1          0          1          1          1
#> 10          1          0          1          0          1          0
```
