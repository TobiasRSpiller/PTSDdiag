test_that("analyze_best_six_symptoms_four_required works correctly", {
  # Create small test dataset
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  # Test deprecation warning is issued
  rlang::local_options(lifecycle_verbosity = "warning")
  expect_warning(
    analyze_best_six_symptoms_four_required(test_data, score_by = "false_cases"),
    class = "lifecycle_warning_deprecated"
  )

  # Test basic functionality (suppress deprecation warning)
  results <- suppressWarnings(
    analyze_best_six_symptoms_four_required(test_data, score_by = "false_cases")
  )

  # Check structure of results
  expect_type(results, "list")
  expect_equal(length(results$best_symptoms), 3)
  expect_true(all(sapply(results$best_symptoms, length) == 6))

  # Check that symptoms are valid
  expect_true(all(unlist(results$best_symptoms) >= 1))
  expect_true(all(unlist(results$best_symptoms) <= 20))

  # Check invalid scoring method
  expect_error(
    suppressWarnings(analyze_best_six_symptoms_four_required(test_data, "invalid_method")),
    ("score_by must be one of: false_cases, newly_nondiagnosed")
  )
})

test_that("analyze_best_six_symptoms_four_required_clusters works correctly", {
  # Create small test dataset
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50,
           ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  # Test deprecation warning is issued
  rlang::local_options(lifecycle_verbosity = "warning")
  expect_warning(
    analyze_best_six_symptoms_four_required_clusters(test_data, score_by = "false_cases"),
    class = "lifecycle_warning_deprecated"
  )

  # Test basic functionality (suppress deprecation warning)
  results <- suppressWarnings(
    analyze_best_six_symptoms_four_required_clusters(test_data, score_by = "false_cases")
  )

  # Check structure of results
  expect_type(results, "list")
  expect_equal(length(results$best_symptoms), 3)
  expect_true(all(sapply(results$best_symptoms, length) == 6))

  # Check that each combination has representation from all clusters
  for (combination in results$best_symptoms) {
    # Check if combination includes symptoms from each cluster
    has_cluster1 <- any(combination %in% 1:5)
    has_cluster2 <- any(combination %in% 6:7)
    has_cluster3 <- any(combination %in% 8:14)
    has_cluster4 <- any(combination %in% 15:20)

    expect_true(has_cluster1 && has_cluster2 && has_cluster3 && has_cluster4)
  }

  # Check invalid scoring method
  expect_error(
    suppressWarnings(analyze_best_six_symptoms_four_required_clusters(test_data, "invalid_method")),
    ("score_by must be one of: false_cases, newly_nondiagnosed")
  )
})

test_that("optimize_combinations returns data.frame by default and DT when requested", {
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  # Default: data.frame

  results <- optimize_combinations(test_data, n_symptoms = 4, n_required = 3,
                                   n_top = 2, score_by = "false_cases")
  expect_true(is.data.frame(results$summary))
  expect_true("Scenario" %in% names(results$summary))

  # DT = TRUE: htmlwidget
  skip_if_not_installed("DT")
  results_dt <- optimize_combinations(test_data, n_symptoms = 4, n_required = 3,
                                      n_top = 2, score_by = "false_cases", DT = TRUE)
  expect_s3_class(results_dt$summary, "datatables")
})

test_that("optimize_combinations_clusters returns data.frame by default and DT when requested", {
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  clusters <- list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)

  # Default: data.frame
  results <- optimize_combinations_clusters(test_data, n_symptoms = 5, n_required = 4,
                                            n_top = 2, score_by = "false_cases",
                                            clusters = clusters)
  expect_true(is.data.frame(results$summary))

  # DT = TRUE: htmlwidget
  skip_if_not_installed("DT")
  results_dt <- optimize_combinations_clusters(test_data, n_symptoms = 5, n_required = 4,
                                               n_top = 2, score_by = "false_cases",
                                               clusters = clusters, DT = TRUE)
  expect_s3_class(results_dt$summary, "datatables")
})

test_that("optimize_combinations summary includes combination_id and rank", {
  set.seed(42)
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  results <- optimize_combinations(test_data, n_symptoms = 4, n_required = 3,
                                   n_top = 2, score_by = "false_cases")
  summary <- results$summary

  # Check combination_id and rank columns exist

  expect_true("combination_id" %in% names(summary))
  expect_true("rank" %in% names(summary))

  # PTSD_orig row should have NA for both
  orig_row <- summary[summary$Scenario == "PTSD_orig", ]
  expect_true(is.na(orig_row$combination_id))
  expect_true(is.na(orig_row$rank))

  # Non-PTSD_orig rows should have valid IDs and sequential ranks
  combo_rows <- summary[summary$Scenario != "PTSD_orig", ]
  expect_equal(nrow(combo_rows), 2)
  expect_equal(combo_rows$rank, c(1L, 2L))

  # combination_id should match Scenario without "symptom_" prefix
  for (i in seq_len(nrow(combo_rows))) {
    expected_id <- sub("^symptom_", "", combo_rows$Scenario[i])
    expect_equal(combo_rows$combination_id[i], expected_id)
  }

  # combination_id should be sorted indices joined by "_"
  for (i in seq_along(results$best_symptoms)) {
    expected_id <- paste(sort(results$best_symptoms[[i]]), collapse = "_")
    expect_equal(combo_rows$combination_id[i], expected_id)
  }
})

test_that("combination IDs are consistent across optimize -> write -> read pipeline", {
  set.seed(42)
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  # Optimize
  results <- optimize_combinations(test_data, n_symptoms = 4, n_required = 3,
                                   n_top = 2, score_by = "false_cases")

  # Write
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))
  write_combinations(results, tmp, n_required = 3, score_by = "false_cases")

  # Read
  spec <- read_combinations(tmp)

  # Check combination_ids round-trip
  expect_true("combination_ids" %in% names(spec))
  expect_true("ranks" %in% names(spec))

  # IDs should match the summary
  summary_ids <- results$summary$combination_id[!is.na(results$summary$combination_id)]
  expect_equal(spec$combination_ids, summary_ids)
  expect_equal(spec$ranks, c(1L, 2L))
})

test_that("read_combinations falls back gracefully for old JSON files without IDs", {
  # Create a JSON file without combination_ids/ranks (simulating v0.2.0 format)
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  old_format <- list(
    ptsddiag_version = "0.2.0",
    created_at = "2025-01-01T00:00:00+0000",
    description = "old format",
    parameters = list(
      n_symptoms = 4,
      n_required = 3,
      score_by = "false_cases",
      clusters = NULL
    ),
    combinations = list(c(1, 2, 3, 4), c(5, 6, 7, 8))
  )
  jsonlite::write_json(old_format, path = tmp, pretty = TRUE, auto_unbox = TRUE,
                       null = "null")

  spec <- suppressMessages(read_combinations(tmp))

  # Should compute IDs from combinations
  expect_equal(spec$combination_ids, c("1_2_3_4", "5_6_7_8"))
  expect_equal(spec$ranks, c(1L, 2L))
})
