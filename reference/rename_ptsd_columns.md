# Rename PTSD symptom (= PCL-5 item) columns

Standardizes column names in PCL-5 (PTSD Checklist for DSM-5) data by
renaming them to a consistent format (symptom_1 through symptom_20).
This standardization is essential for subsequent analyses using other
functions in the package.

## Usage

``` r
rename_ptsd_columns(data)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns, where each column
  represents a PCL-5 item score. The scores should be on a 0-4 scale
  where:

  - 0 = Not at all

  - 1 = A little bit

  - 2 = Moderately

  - 3 = Quite a bit

  - 4 = Extremely

## Value

A dataframe with the same data but renamed columns following the pattern
'symptom_1' through 'symptom_20'

## Details

The function assumes the input data contains exactly 20 columns
corresponding to the 20 items of the PCL-5. The columns are renamed
sequentially from symptom_1 to symptom_20, maintaining their original
order. The PCL-5 items correspond to different symptom clusters:

- symptom_1 to symptom_5: Intrusion symptoms (Criterion B)

- symptom_6 to symptom_7: Avoidance symptoms (Criterion C)

- symptom_8 to symptom_14: Negative alterations in cognitions and mood
  (Criterion D)

- symptom_15 to symptom_20: Alterations in arousal and reactivity
  (Criterion E)

## Examples

``` r
# Example with a sample PCL-5 dataset
sample_data <- data.frame(
  matrix(sample(0:4, 20 * 10, replace = TRUE),
         nrow = 10,
         ncol = 20)
)
renamed_data <- rename_ptsd_columns(sample_data)
colnames(renamed_data)  # Shows new column names
#>  [1] "symptom_1"  "symptom_2"  "symptom_3"  "symptom_4"  "symptom_5" 
#>  [6] "symptom_6"  "symptom_7"  "symptom_8"  "symptom_9"  "symptom_10"
#> [11] "symptom_11" "symptom_12" "symptom_13" "symptom_14" "symptom_15"
#> [16] "symptom_16" "symptom_17" "symptom_18" "symptom_19" "symptom_20"
```
