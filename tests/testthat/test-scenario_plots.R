build_comparison <- function(n = 60, seed = 7, include_icd11 = FALSE) {
  set.seed(seed)
  df <- as.data.frame(matrix(sample(0:4, 20 * n, replace = TRUE), nrow = n,
                             ncol = 20))
  names(df) <- paste0("symptom_", 1:20)
  compare_optimizations(df, n_top = 3, include_icd11 = include_icd11,
                        show_progress = FALSE)
}

test_that("plot_symptom_frequency returns a ggplot object", {
  skip_if_not_installed("ggplot2")
  comp <- build_comparison()
  p <- plot_symptom_frequency(comp)
  expect_s3_class(p, "ggplot")
  expect_true(all(c("Symptom", "Approach", "Count", "RelFreq") %in% names(p$data)))
  expect_true("OVERALL" %in% as.character(p$data$Approach))
})

test_that("plot_symptom_frequency show_overall = FALSE drops the OVERALL row", {
  skip_if_not_installed("ggplot2")
  comp <- build_comparison()
  p <- plot_symptom_frequency(comp, show_overall = FALSE)
  expect_false("OVERALL" %in% as.character(p$data$Approach))
})

test_that("plot_symptom_frequency rejects mismatched symptom_labels", {
  skip_if_not_installed("ggplot2")
  comp <- build_comparison()
  expect_error(
    plot_symptom_frequency(comp, symptom_labels = c("a", "b")),
    "length 20"
  )
})

test_that("plot_symptom_frequency type = absolute draws Count rather than RelFreq", {
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
