# Tests for the balanced_accuracy metric and score_by option (added in 0.3.5)

test_that("summarize_ptsd_changes computes balanced accuracy as (sens + spec) / 2", {
  data <- data.frame(
    PTSD_orig = c(TRUE, TRUE, FALSE, FALSE),
    PTSD_alt  = c(TRUE, FALSE, FALSE, FALSE)  # sens 0.5, spec 1
  )
  stats <- summarize_ptsd_changes(data)

  expect_equal(stats$balanced_accuracy,
               (stats$sensitivity + stats$specificity) / 2)
  expect_equal(stats$balanced_accuracy[stats$column == "PTSD_alt"], 0.75)
  expect_equal(stats$balanced_accuracy[stats$column == "PTSD_orig"], 1)
})

test_that("balanced accuracy is NA when a class is missing, and still renders", {
  # All baseline-positive: specificity undefined, so balanced accuracy is NA
  data <- data.frame(
    PTSD_orig = c(TRUE, TRUE, TRUE),
    PTSD_alt  = c(TRUE, FALSE, TRUE)
  )
  stats <- summarize_ptsd_changes(data)
  alt <- stats[stats$column == "PTSD_alt", ]

  expect_true(is.na(alt$specificity))
  expect_true(is.na(alt$balanced_accuracy))

  # create_readable_summary tolerates NA metrics
  readable <- create_readable_summary(stats)
  expect_true(is.na(readable$`Balanced Accuracy`[readable$Scenario == "PTSD_alt"]))
})

test_that("optimize_combinations accepts balanced_accuracy and rejects unknown values", {
  set.seed(42)
  test_data <- data.frame(matrix(sample(0:4, 20 * 40, replace = TRUE),
                                 nrow = 40, ncol = 20))
  colnames(test_data) <- paste0("symptom_", 1:20)

  res <- optimize_combinations(test_data, n_symptoms = 3, n_required = 2,
                               score_by = "balanced_accuracy",
                               show_progress = FALSE)
  expect_type(res, "list")
  expect_true("Balanced Accuracy" %in% names(res$summary))

  expect_error(
    optimize_combinations(test_data, n_symptoms = 3, n_required = 2,
                          score_by = "bacc", show_progress = FALSE),
    "must be one of"
  )
})

test_that("balanced_accuracy aborts when the baseline has only one class", {
  # Every item scored 3 -> every participant meets the full criteria
  one_class <- data.frame(matrix(3, nrow = 6, ncol = 20))
  colnames(one_class) <- paste0("symptom_", 1:20)

  expect_error(
    optimize_combinations(one_class, n_symptoms = 3, n_required = 2,
                          score_by = "balanced_accuracy",
                          show_progress = FALSE),
    "requires both diagnosed and non-diagnosed cases"
  )
  # The default is balanced_accuracy, so the default call aborts too
  expect_error(
    optimize_combinations(one_class, n_symptoms = 3, n_required = 2,
                          show_progress = FALSE),
    "requires both diagnosed and non-diagnosed cases"
  )
  # "accuracy" remains available for single-class data
  res <- optimize_combinations(one_class, n_symptoms = 3, n_required = 2,
                               score_by = "accuracy", show_progress = FALSE)
  expect_type(res, "list")
})

test_that("accuracy and balanced_accuracy can pick different winners under imbalance", {
  # Baseline: 9 positives, 1 negative.
  # Combination 1: FN = 2, FP = 0 -> 2 errors, balanced error 2/9
  # Combination 2: FN = 0, FP = 1 -> 1 error,  balanced error 1/1
  baseline <- c(rep(TRUE, 9), FALSE)
  fake_diagnose <- function(binarized_data, combo) {
    if (identical(combo, 1L)) {
      c(rep(TRUE, 7), FALSE, FALSE, FALSE)  # misses 2 positives
    } else {
      rep(TRUE, 10)                         # flags the negative
    }
  }

  top_acc <- PTSDdiag:::.find_top_n(
    list(1L, 2L), binarized_data = NULL, baseline_results = baseline,
    score_by = "accuracy", n_top = 1, diagnose_fn = fake_diagnose,
    show_progress = FALSE
  )
  top_bac <- PTSDdiag:::.find_top_n(
    list(1L, 2L), binarized_data = NULL, baseline_results = baseline,
    score_by = "balanced_accuracy", n_top = 1, diagnose_fn = fake_diagnose,
    show_progress = FALSE
  )

  expect_equal(top_acc$top[[1]]$combination, 2L)
  expect_equal(top_bac$top[[1]]$combination, 1L)
})

test_that("balanced_accuracy round-trips through write/read_combinations", {
  combos <- list(c(1, 6, 8, 10, 15, 19), c(2, 7, 9, 11, 16, 20))
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  write_combinations(combos, tmp, n_required = 4,
                     score_by = "balanced_accuracy")
  spec <- read_combinations(tmp)

  expect_equal(spec$parameters$score_by, "balanced_accuracy")
})
