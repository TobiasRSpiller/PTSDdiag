# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

make_test_data <- function(n = 60, seed = 7, id = TRUE) {
  set.seed(seed)
  df <- as.data.frame(matrix(sample(0:4, 20 * n, replace = TRUE), nrow = n,
                             ncol = 20))
  names(df) <- paste0("symptom_", 1:20)
  if (id) df <- cbind(patient_id = sprintf("P%03d", seq_len(n)), df,
                      stringsAsFactors = FALSE)
  df
}

# ---------------------------------------------------------------------------
# compare_optimizations(): defaults and structure
# ---------------------------------------------------------------------------

test_that("compare_optimizations() defaults to the three preprint scenarios", {
  set.seed(11)
  data <- make_test_data(n = 80, id = FALSE)
  comp <- compare_optimizations(data, n_top = 3, show_progress = FALSE)

  expect_s3_class(comp, "ptsdiag_comparison")
  expect_equal(names(comp$scenarios),
               c("4/6 Hierarchical", "4/6 Non-hierarchical",
                 "3/6 Non-hierarchical"))
  expect_equal(comp$config$type, rep("optimize", 3))
  expect_equal(comp$config$n_top, rep(3L, 3))
  expect_equal(comp$n_rows, nrow(data))
})

test_that("compare_optimizations() honours custom scenarios with varying n_symptoms", {
  set.seed(13)
  data <- make_test_data(n = 60, id = FALSE)
  scenarios <- list(
    "3/5 Hier" = list(n_symptoms = 5, n_required = 3, hierarchical = TRUE),
    "3/4 Hier" = list(n_symptoms = 4, n_required = 3, hierarchical = TRUE)
  )
  comp <- compare_optimizations(data, scenarios = scenarios, n_top = 2,
                                show_progress = FALSE)
  expect_equal(comp$config$n_symptoms, c(5L, 4L))
  expect_equal(comp$config$n_required, c(3L, 3L))
  expect_true(all(lengths(comp$scenarios[[1]]$best_symptoms) == 5))
})

test_that("compare_optimizations() carries id_col through every scenario", {
  set.seed(17)
  data_with_id <- make_test_data(n = 60, id = TRUE)
  # One hierarchical and one non-hierarchical scenario cover both code paths
  # at a fraction of the default scenarios' cost
  scenarios <- list(
    "3/4 Hier" = list(n_symptoms = 4, n_required = 3, hierarchical = TRUE),
    "3/4 NH"   = list(n_symptoms = 4, n_required = 3, hierarchical = FALSE)
  )
  comp <- compare_optimizations(data_with_id, scenarios = scenarios,
                                n_top = 2, show_progress = FALSE)
  for (res in comp$scenarios) {
    expect_true("patient_id" %in% names(res$diagnosis_comparison))
    expect_equal(res$diagnosis_comparison$patient_id, data_with_id$patient_id)
  }
})

# ---------------------------------------------------------------------------
# Validation errors
# ---------------------------------------------------------------------------

test_that("compare_optimizations() errors on hierarchical n_symptoms < n_clusters", {
  set.seed(21)
  data <- make_test_data(n = 40, id = FALSE)
  scenarios <- list(
    "3/3 Hier" = list(n_symptoms = 3, n_required = 3, hierarchical = TRUE)
  )
  expect_error(
    compare_optimizations(data, scenarios = scenarios, n_top = 1,
                          show_progress = FALSE),
    "at least the number of clusters"
  )
})

test_that("compare_optimizations() rejects duplicate scenario labels", {
  data <- make_test_data(n = 40, id = FALSE)
  scenarios <- list(
    "Same" = list(n_symptoms = 6, n_required = 4, hierarchical = TRUE),
    "Same" = list(n_symptoms = 6, n_required = 4, hierarchical = FALSE)
  )
  expect_error(
    compare_optimizations(data, scenarios = scenarios, n_top = 1,
                          show_progress = FALSE),
    "Duplicate scenario"
  )
})

test_that("compare_optimizations() rejects unnamed scenarios", {
  data <- make_test_data(n = 40, id = FALSE)
  scenarios <- list(
    list(n_symptoms = 6, n_required = 4, hierarchical = TRUE)
  )
  expect_error(
    compare_optimizations(data, scenarios = scenarios, n_top = 1,
                          show_progress = FALSE),
    "must be named"
  )
})

# ---------------------------------------------------------------------------
# include_icd11 and fixed scenarios
# ---------------------------------------------------------------------------

test_that("include_icd11 = TRUE adds an ICD-11 fixed scenario", {
  set.seed(29)
  data <- make_test_data(n = 80, id = FALSE)
  scenarios <- list(
    "3/4 NH" = list(n_symptoms = 4, n_required = 3, hierarchical = FALSE)
  )
  comp <- compare_optimizations(data, scenarios = scenarios, n_top = 2,
                                include_icd11 = TRUE, show_progress = FALSE)
  expect_true("ICD-11" %in% names(comp$scenarios))
  expect_equal(attr(comp$scenarios[["ICD-11"]], "type"), "fixed")
  expect_equal(comp$scenarios[["ICD-11"]]$best_symptoms[[1]],
               c(1, 2, 3, 6, 7, 17, 18))
  # Diagnosis column matches create_icd11_diagnosis output
  ref <- create_icd11_diagnosis(data)$PTSD_icd11
  expect_equal(comp$scenarios[["ICD-11"]]$diagnosis_comparison$PTSD_icd11, ref)
})

test_that("Fixed scenario accepts a user-supplied logical vector", {
  set.seed(31)
  data <- make_test_data(n = 50, id = FALSE)
  my_dx <- sample(c(TRUE, FALSE), 50, replace = TRUE)
  scenarios <- list(
    "4/6 NH" = list(n_symptoms = 6, n_required = 4, hierarchical = FALSE),
    "My DX"  = list(type = "fixed", criterion = my_dx, symptoms = c(1, 6, 15))
  )
  comp <- compare_optimizations(data, scenarios = scenarios, n_top = 2,
                                show_progress = FALSE)
  expect_equal(attr(comp$scenarios[["My DX"]], "type"), "fixed")
  expect_equal(comp$scenarios[["My DX"]]$best_symptoms[[1]], c(1, 6, 15))
})

test_that("Fixed scenario rejects length-mismatched logical vector", {
  data <- make_test_data(n = 50, id = FALSE)
  bad_dx <- c(TRUE, FALSE)
  scenarios <- list("X" = list(type = "fixed", criterion = bad_dx,
                               symptoms = 1))
  expect_error(
    compare_optimizations(data, scenarios = scenarios, n_top = 1,
                          show_progress = FALSE),
    "Lengths must match"
  )
})

test_that("Fixed scenario rejects unknown criterion string", {
  data <- make_test_data(n = 50, id = FALSE)
  scenarios <- list("X" = list(type = "fixed", criterion = "unknown"))
  expect_error(
    compare_optimizations(data, scenarios = scenarios, n_top = 1,
                          show_progress = FALSE),
    "unknown"
  )
})

# ---------------------------------------------------------------------------
# print method
# ---------------------------------------------------------------------------

test_that("print.ptsdiag_comparison runs without error", {
  set.seed(41)
  data <- make_test_data(n = 60, id = FALSE)
  scenarios <- list(
    "3/4 NH" = list(n_symptoms = 4, n_required = 3, hierarchical = FALSE)
  )
  comp <- compare_optimizations(data, scenarios = scenarios, n_top = 1,
                                include_icd11 = TRUE, show_progress = FALSE)
  expect_invisible(print(comp))
})
