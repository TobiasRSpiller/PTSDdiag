# Heatmap of PCL-5 symptom selection frequency across optimization scenarios

Visualises how often each of the 20 PCL-5 symptoms is selected across
the top combinations of each optimization scenario in a
[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md)
result. Replicates the symptom-frequency heatmap (Figure 1) of the
PTSDdiag preprint and helps identify "core" symptoms that recur across
data-driven combinations.

## Usage

``` r
plot_symptom_frequency(
  comparison,
  type = c("relative", "absolute"),
  show_overall = TRUE,
  overall_includes_fixed = FALSE,
  symptom_labels = NULL,
  low_colour = "#f7fbff",
  high_colour = "#084594"
)
```

## Arguments

- comparison:

  A `ptsdiag_comparison` object.

- type:

  `"relative"` (default; fill = `RelFreq`, percentage labels) or
  `"absolute"` (fill = `Count`).

- show_overall:

  Logical. Include the pooled `OVERALL` row. Default `TRUE`.

- overall_includes_fixed:

  Logical. If `TRUE`, fixed criteria contribute to the OVERALL row.
  Default `FALSE`.

- symptom_labels:

  Optional character vector of length 20 used to label the x-axis ticks.
  Default uses the numeric indices `1:20`.

- low_colour, high_colour:

  Gradient endpoints for the fill scale.

## Value

A `ggplot` object. Users can extend it with additional layers, themes,
or labels via the usual `+` operator.

## Details

Each tile shows the frequency with which a symptom appears in the stored
combinations of a scenario. Fixed criteria (e.g. ICD-11) appear as rows
with cells at `RelFreq = 1` on their included symptoms and `RelFreq = 0`
elsewhere. The optional `OVERALL` row pools across optimization
scenarios by default (set `overall_includes_fixed = TRUE` to include
fixed criteria in the pool). It is rendered in a separate facet so it is
visually distinct from the per-scenario rows.

Requires the ggplot2 package.

## See also

[`compare_optimizations`](https://tobiasrspiller.github.io/PTSDdiag/reference/compare_optimizations.md),
[`symptom_frequency`](https://tobiasrspiller.github.io/PTSDdiag/reference/symptom_frequency.md),
[`summarize_top_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/summarize_top_combinations.md).

## Examples

``` r
# \donttest{
# Use a 250-row subset and a small 4-symptom search to keep the example
# fast; omit `scenarios` to run the three default rules
ptsd_data <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                                 id_col = c("patient_id", "age", "sex"))
comp <- compare_optimizations(
  ptsd_data,
  scenarios = list(
    "3/4 Non-hierarchical" = list(n_symptoms = 4, n_required = 3,
                                  hierarchical = FALSE)
  ),
  include_icd11 = TRUE, n_top = 5, show_progress = FALSE
)
#> ℹ Evaluated 4845 combinations. Best: 6, 7, 12, 17
plot_symptom_frequency(comp)

# }
```
