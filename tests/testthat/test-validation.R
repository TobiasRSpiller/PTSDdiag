test_that("holdout_validation works correctly", {
  # Create test data
  set.seed(42)
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 100, replace = TRUE),
           nrow = 100,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)
  
  # Test basic functionality
  results <- holdout_validation(test_data, train_ratio = 0.7, seed = 42)
  
  # Check structure of results
  expect_type(results, "list")
  expect_equal(names(results), c("without_clusters", "with_clusters"))
  
  # Check without_clusters results
  expect_type(results$without_clusters, "list")
  expect_equal(names(results$without_clusters), 
               c("best_combinations", "test_results", "summary"))
  expect_equal(length(results$without_clusters$best_combinations), 3)
  expect_true(all(sapply(results$without_clusters$best_combinations, length) == 6))
  
  # Check with_clusters results
  expect_type(results$with_clusters, "list")
  expect_equal(names(results$with_clusters), 
               c("best_combinations", "test_results", "summary"))
  expect_equal(length(results$with_clusters$best_combinations), 3)
  expect_true(all(sapply(results$with_clusters$best_combinations, length) == 6))
  
  # Check test_results structure
  expect_true("PTSD_orig" %in% names(results$without_clusters$test_results))
  expect_true("PTSD_orig" %in% names(results$with_clusters$test_results))
  
  # Check that test results have correct number of rows (nrow - floor(train_ratio * nrow))
  expected_test_rows <- nrow(test_data) - floor(0.7 * nrow(test_data))
  expect_equal(nrow(results$without_clusters$test_results), expected_test_rows)
  expect_equal(nrow(results$with_clusters$test_results), expected_test_rows)
  
  # Check that combinations from with_clusters have cluster representation
  for (combination in results$with_clusters$best_combinations) {
    has_cluster1 <- any(combination %in% 1:5)
    has_cluster2 <- any(combination %in% 6:7)
    has_cluster3 <- any(combination %in% 8:14)
    has_cluster4 <- any(combination %in% 15:20)
    expect_true(has_cluster1 && has_cluster2 && has_cluster3 && has_cluster4)
  }
})

test_that("holdout_validation handles different train_ratio values", {
  # Create test data
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)
  
  # Test with different train ratios (small search keeps the test fast)
  results_50 <- holdout_validation(test_data, train_ratio = 0.5, seed = 123,
                                   n_symptoms = 4, n_required = 3)
  results_80 <- holdout_validation(test_data, train_ratio = 0.8, seed = 123,
                                   n_symptoms = 4, n_required = 3)
  
  # Check that test set sizes are correct
  expect_equal(nrow(results_50$without_clusters$test_results), 25)
  expect_equal(nrow(results_80$without_clusters$test_results), 10)
})

test_that("holdout_validation handles different score_by options", {
  # Create test data
  set.seed(123)
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  # Test with different scoring methods (small search keeps the test fast)
  results_acc <- holdout_validation(test_data, score_by = "accuracy",    seed = 123,
                                    n_symptoms = 4, n_required = 3)
  results_sen <- holdout_validation(test_data, score_by = "sensitivity", seed = 123,
                                    n_symptoms = 4, n_required = 3)
  results_bac <- holdout_validation(test_data, score_by = "balanced_accuracy",
                                    seed = 123, n_symptoms = 4, n_required = 3)

  # All should return valid results
  expect_type(results_acc, "list")
  expect_type(results_sen, "list")
  expect_type(results_bac, "list")

  # Results might differ based on optimization criterion
  # but structure should be the same
  expect_equal(names(results_acc), names(results_sen))
  expect_equal(names(results_acc), names(results_bac))
})

test_that("legacy score_by values error with a migration hint", {
  # v <= 0.3.0 names were renamed in 0.3.1
  test_data <- as.data.frame(matrix(sample(0:4, 20 * 30, replace = TRUE),
                                    nrow = 30, ncol = 20))
  colnames(test_data) <- paste0("symptom_", 1:20)

  expect_error(
    holdout_validation(test_data, score_by = "false_cases", seed = 123),
    "accuracy"
  )
  expect_error(
    holdout_validation(test_data, score_by = "newly_nondiagnosed", seed = 123),
    "sensitivity"
  )
})

test_that("holdout_validation validates input correctly", {
  # Create test data
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)
  
  # Test invalid train_ratio
  expect_error(
    holdout_validation(test_data, train_ratio = 0),
    "must be between 0 and 1"
  )
  expect_error(
    holdout_validation(test_data, train_ratio = 1),
    "must be between 0 and 1"
  )
  expect_error(
    holdout_validation(test_data, train_ratio = 1.5),
    "must be between 0 and 1"
  )
  
  # Test invalid score_by
  expect_error(
    holdout_validation(test_data, score_by = "invalid"),
    "must be one of"
  )
  
  # Test with wrong number of columns (missing symptom_* names)
  wrong_cols <- test_data[, 1:15]
  expect_error(
    holdout_validation(wrong_cols),
    "must contain columns named"
  )

  # Test with wrong column names
  wrong_names <- test_data
  colnames(wrong_names) <- paste0("col_", 1:20)
  expect_error(
    holdout_validation(wrong_names),
    "must contain columns named"
  )
})

test_that("cross_validation works correctly", {
  # Create test data
  set.seed(42)
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 100, replace = TRUE),
           nrow = 100,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)
  
  # Test basic functionality with k=3 and a small search for speed
  results <- cross_validation(test_data, k = 3, seed = 42,
                              n_symptoms = 4, n_required = 3)
  
  # Check structure of results
  expect_type(results, "list")
  expect_equal(names(results), c("without_clusters", "with_clusters"))
  
  # Check without_clusters results
  expect_type(results$without_clusters, "list")
  expect_equal(names(results$without_clusters), 
               c("fold_results", "summary_by_fold", "combinations_summary"))
  expect_equal(length(results$without_clusters$fold_results), 3)  # k=3 folds
  
  # Check with_clusters results
  expect_type(results$with_clusters, "list")
  expect_equal(names(results$with_clusters), 
               c("fold_results", "summary_by_fold", "combinations_summary"))
  expect_equal(length(results$with_clusters$fold_results), 3)  # k=3 folds
  
  # Check that each fold has results
  for (i in 1:3) {
    expect_true("PTSD_orig" %in% names(results$without_clusters$fold_results[[i]]))
    expect_true("PTSD_orig" %in% names(results$with_clusters$fold_results[[i]]))
  }
})

test_that("cross_validation handles different k values", {
  # Create test data
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)
  
  # Test with different k values (small search keeps the test fast)
  results_2 <- cross_validation(test_data, k = 2, seed = 123,
                                n_symptoms = 4, n_required = 3)
  results_5 <- cross_validation(test_data, k = 5, seed = 123,
                                n_symptoms = 4, n_required = 3)
  
  # Check that number of folds is correct
  expect_equal(length(results_2$without_clusters$fold_results), 2)
  expect_equal(length(results_5$without_clusters$fold_results), 5)
  
  # Each fold should have approximately equal size
  fold_sizes_2 <- sapply(results_2$without_clusters$fold_results, nrow)
  fold_sizes_5 <- sapply(results_5$without_clusters$fold_results, nrow)
  
  # Allow for small differences due to stratified splitting
  expect_true(max(fold_sizes_2) - min(fold_sizes_2) <= 3)
  expect_true(max(fold_sizes_5) - min(fold_sizes_5) <= 3)
})

test_that("cross_validation validates input correctly", {
  # Create test data
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)
  
  # Test invalid k values
  expect_error(
    cross_validation(test_data, k = 1),
    "must be a single integer between 2"
  )
  expect_error(
    cross_validation(test_data, k = 51),
    "must be a single integer between 2"
  )
  
  # Test invalid score_by
  expect_error(
    cross_validation(test_data, score_by = "invalid"),
    "must be one of"
  )
  
  # Test with wrong number of columns (missing symptom_* names)
  wrong_cols <- test_data[, 1:15]
  expect_error(
    cross_validation(wrong_cols),
    "must contain columns named"
  )

  # Test with non-dataframe input
  expect_error(
    cross_validation(as.matrix(test_data)),
    "must be a data frame"
  )
})

test_that("cross_validation combinations_summary works correctly", {
  # Create test data with patterns that might repeat across folds
  set.seed(123)
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 100, replace = TRUE, 
                  prob = c(0.3, 0.3, 0.2, 0.1, 0.1)),  # Skewed distribution
           nrow = 100,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)
  
  # Run cross-validation (small search makes repeats across folds more
  # likely and keeps the test fast)
  results <- cross_validation(test_data, k = 5, seed = 123,
                              n_symptoms = 4, n_required = 3)
  
  # Check combinations_summary structure if it exists (can be NULL)
  if (!is.null(results$without_clusters$combinations_summary)) {
    # Default is data.frame (DT = FALSE)
    summary_data <- results$without_clusters$combinations_summary
    expect_true(is.data.frame(summary_data))
    expect_true("Splits_Appeared" %in% names(summary_data))
    expect_true("Sensitivity" %in% names(summary_data))
    expect_true("Specificity" %in% names(summary_data))
    expect_true("PPV" %in% names(summary_data))
    expect_true("NPV" %in% names(summary_data))
    expect_true("Accuracy" %in% names(summary_data))
    expect_true("Balanced_Accuracy" %in% names(summary_data))

    # Splits_Appeared should be > 1 for all rows
    expect_true(all(summary_data$Splits_Appeared > 1))
  }

  # Same for with_clusters
  if (!is.null(results$with_clusters$combinations_summary)) {
    summary_data <- results$with_clusters$combinations_summary
    expect_true(is.data.frame(summary_data))
    expect_true("Splits_Appeared" %in% names(summary_data))
    expect_true(all(summary_data$Splits_Appeared > 1))
  }
})

test_that("holdout_validation produces consistent results with same seed", {
  # Create test data
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)
  
  # Run twice with same seed (small search keeps the test fast)
  results1 <- holdout_validation(test_data, seed = 42,
                                 n_symptoms = 4, n_required = 3)
  results2 <- holdout_validation(test_data, seed = 42,
                                 n_symptoms = 4, n_required = 3)

  # Results should be identical
  expect_equal(results1$without_clusters$best_combinations,
               results2$without_clusters$best_combinations)
  expect_equal(results1$with_clusters$best_combinations,
               results2$with_clusters$best_combinations)

  # Run with different seed
  results3 <- holdout_validation(test_data, seed = 123,
                                 n_symptoms = 4, n_required = 3)
  
  # Results might differ (though not guaranteed for small datasets)
  # At least the structure should be the same
  expect_equal(names(results1), names(results3))
})

test_that("holdout_validation returns data.frame by default and DT when requested", {
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE), nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  results <- holdout_validation(test_data, seed = 42,
                                n_symptoms = 4, n_required = 3)
  expect_true(is.data.frame(results$without_clusters$summary))
  expect_true(is.data.frame(results$with_clusters$summary))

  skip_if_not_installed("DT")
  results_dt <- holdout_validation(test_data, seed = 42, DT = TRUE,
                                   n_symptoms = 4, n_required = 3)
  expect_s3_class(results_dt$without_clusters$summary, "datatables")
  expect_s3_class(results_dt$with_clusters$summary, "datatables")
})

test_that("cross_validation returns data.frame by default and DT when requested", {
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 100, replace = TRUE), nrow = 100, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  results <- cross_validation(test_data, k = 3, seed = 42,
                              n_symptoms = 4, n_required = 3)
  expect_true(is.data.frame(results$without_clusters$summary_by_fold))
  expect_true(is.data.frame(results$with_clusters$summary_by_fold))

  skip_if_not_installed("DT")
  results_dt <- cross_validation(test_data, k = 3, seed = 42, DT = TRUE,
                                 n_symptoms = 4, n_required = 3)
  expect_s3_class(results_dt$without_clusters$summary_by_fold, "datatables")
  expect_s3_class(results_dt$with_clusters$summary_by_fold, "datatables")
})

test_that("cross_validation produces consistent results with same seed", {
  # Create test data
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  # Run twice with same seed (small search keeps the test fast)
  results1 <- cross_validation(test_data, k = 3, seed = 42,
                               n_symptoms = 4, n_required = 3)
  results2 <- cross_validation(test_data, k = 3, seed = 42,
                               n_symptoms = 4, n_required = 3)

  # Check that fold assignments are the same
  for (i in 1:3) {
    expect_equal(nrow(results1$without_clusters$fold_results[[i]]),
                 nrow(results2$without_clusters$fold_results[[i]]))
  }
})

test_that("holdout_validation restores user RNG state", {
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE), nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  # After holdout_validation returns, the user's RNG stream should resume
  # exactly as if the function was never called.
  set.seed(99)
  expected <- runif(1)

  set.seed(99)
  holdout_validation(test_data, seed = 555, n_symptoms = 4, n_required = 3)
  actual <- runif(1)

  expect_equal(actual, expected)
})

test_that("cross_validation restores user RNG state", {
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE), nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  set.seed(99)
  expected <- runif(1)

  set.seed(99)
  cross_validation(test_data, k = 2, seed = 555,
                   n_symptoms = 4, n_required = 3)
  actual <- runif(1)

  expect_equal(actual, expected)
})

test_that("cross_validation rejects non-integer k", {
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE), nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  expect_error(
    cross_validation(test_data, k = 3.5),
    "must be a single integer"
  )
  expect_error(
    cross_validation(test_data, k = 2.1),
    "must be a single integer"
  )
})

test_that("holdout_validation rejects train_ratio that produces empty splits", {
  # With 3 rows: floor(0.01 * 3) = 0 → empty train set
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 3, replace = TRUE), nrow = 3, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  expect_error(
    holdout_validation(test_data, train_ratio = 0.01),
    "produces an empty training or test set"
  )

  # With 1 row: floor(0.7 * 1) = 0 → empty train set
  test_data_1 <- data.frame(
    matrix(sample(0:4, 20, replace = TRUE), nrow = 1, ncol = 20)
  )
  colnames(test_data_1) <- paste0("symptom_", 1:20)

  expect_error(
    holdout_validation(test_data_1, train_ratio = 0.7),
    "produces an empty training or test set"
  )
})

# ---------------------------------------------------------------------------
# id_col carry-through through validation
# ---------------------------------------------------------------------------

test_that("holdout_validation carries ID columns into test_results", {
  set.seed(31)
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:120),
    age        = sample(20:70, 120, replace = TRUE),
    matrix(sample(0:4, 20 * 120, replace = TRUE), nrow = 120, ncol = 20),
    stringsAsFactors = FALSE
  )
  sym <- rename_ptsd_columns(raw, id_col = c("patient_id", "age"))

  res <- holdout_validation(sym, train_ratio = 0.7, seed = 99,
                            n_symptoms = 4, n_required = 3, n_top = 2)
  tw <- res$without_clusters$test_results
  expect_true(all(c("patient_id", "age") %in% names(tw)))
  expect_true(all(tw$patient_id %in% raw$patient_id))
  expect_equal(length(unique(tw$patient_id)), nrow(tw))

  # Demographics merge back recovers exactly the test subset
  joined <- merge(raw[, c("patient_id", "age")], tw, by = "patient_id")
  expect_equal(nrow(joined), nrow(tw))
})

test_that("cross_validation carries ID columns into every fold_results entry", {
  skip_if_not_installed("rsample")
  set.seed(37)
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:200),
    matrix(sample(0:4, 20 * 200, replace = TRUE), nrow = 200, ncol = 20),
    stringsAsFactors = FALSE
  )
  sym <- rename_ptsd_columns(raw, id_col = "patient_id")

  res <- cross_validation(sym, k = 4, seed = 99,
                          n_symptoms = 4, n_required = 3, n_top = 2)
  folds_w <- res$without_clusters$fold_results
  expect_length(folds_w, 4)

  for (fold in folds_w) {
    expect_true("patient_id" %in% names(fold))
    expect_true(all(fold$patient_id %in% raw$patient_id))
  }

  # Fold patient IDs are disjoint and partition the input rows
  all_ids <- unlist(lapply(folds_w, `[[`, "patient_id"), use.names = FALSE)
  expect_equal(length(all_ids), length(unique(all_ids)))
  expect_setequal(all_ids, raw$patient_id)
})
