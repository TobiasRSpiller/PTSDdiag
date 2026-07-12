# Building the default-scenario comparison is the expensive part of this
# file, so each variant is built once and reused (all tests are read-only).
.comparison_cache <- new.env(parent = emptyenv())
build_comparison <- function(n = 60, seed = 7, include_icd11 = FALSE) {
  key <- paste(n, seed, include_icd11, sep = "_")
  if (is.null(.comparison_cache[[key]])) {
    set.seed(seed)
    df <- as.data.frame(matrix(sample(0:4, 20 * n, replace = TRUE), nrow = n,
                               ncol = 20))
    names(df) <- paste0("symptom_", 1:20)
    .comparison_cache[[key]] <- compare_optimizations(
      df, n_top = 3, include_icd11 = include_icd11, show_progress = FALSE
    )
  }
  .comparison_cache[[key]]
}

test_that("plot_symptom_frequency returns a ggplot object", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  skip_if_not_installed("ggplot2")
  comp <- build_comparison()
  p <- plot_symptom_frequency(comp)
  expect_s3_class(p, "ggplot")
  expect_true(all(c("Symptom", "Approach", "Count", "RelFreq") %in% names(p$data)))
  expect_true("OVERALL" %in% as.character(p$data$Approach))
})

test_that("plot_symptom_frequency show_overall = FALSE drops the OVERALL row", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  skip_if_not_installed("ggplot2")
  comp <- build_comparison()
  p <- plot_symptom_frequency(comp, show_overall = FALSE)
  expect_false("OVERALL" %in% as.character(p$data$Approach))
})

test_that("plot_symptom_frequency rejects mismatched symptom_labels", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  skip_if_not_installed("ggplot2")
  comp <- build_comparison()
  expect_error(
    plot_symptom_frequency(comp, symptom_labels = c("a", "b")),
    "length 20"
  )
})

test_that("plot_symptom_frequency type = absolute draws Count rather than RelFreq", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  skip_if_not_installed("ggplot2")
  comp <- build_comparison()
  p_rel <- plot_symptom_frequency(comp, type = "relative")
  p_abs <- plot_symptom_frequency(comp, type = "absolute")
  expect_s3_class(p_rel, "ggplot")
  expect_s3_class(p_abs, "ggplot")
  # The two plots use different fill scales / data mappings; both should
  # render without error.
  expect_true(inherits(p_rel$scales$scales[[1]], "Scale"))
})

test_that("plot_symptom_frequency works on a compact comparison (CRAN smoke test)", {
  skip_if_not_installed("ggplot2")
  # The tests above share a cached default-scenario comparison (91,205
  # candidates) and are CI-only; this compact 4-symptom search keeps the plot
  # path exercised on CRAN itself.
  set.seed(7)
  df <- as.data.frame(matrix(sample(0:4, 20 * 60, replace = TRUE),
                             nrow = 60, ncol = 20))
  names(df) <- paste0("symptom_", 1:20)
  comp <- compare_optimizations(
    df,
    scenarios = list("3/4 Non-hierarchical" = list(n_symptoms = 4,
                                                   n_required = 3,
                                                   hierarchical = FALSE)),
    n_top = 3, show_progress = FALSE
  )
  p <- plot_symptom_frequency(comp)
  expect_s3_class(p, "ggplot")
})
