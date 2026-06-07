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
    analyze_best_six_symptoms_four_required(test_data, score_by = "accuracy"),
    class = "lifecycle_warning_deprecated"
  )

  # Test basic functionality (suppress deprecation warning)
  results <- suppressWarnings(
    analyze_best_six_symptoms_four_required(test_data, score_by = "accuracy")
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
    "must be one of"
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
    analyze_best_six_symptoms_four_required_clusters(test_data, score_by = "accuracy"),
    class = "lifecycle_warning_deprecated"
  )

  # Test basic functionality (suppress deprecation warning)
  results <- suppressWarnings(
    analyze_best_six_symptoms_four_required_clusters(test_data, score_by = "accuracy")
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
    "must be one of"
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
                                   n_top = 2, score_by = "accuracy")
  expect_true(is.data.frame(results$summary))
  expect_true("Scenario" %in% names(results$summary))

  # DT = TRUE: htmlwidget
  skip_if_not_installed("DT")
  results_dt <- optimize_combinations(test_data, n_symptoms = 4, n_required = 3,
                                      n_top = 2, score_by = "accuracy", DT = TRUE)
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
                                            n_top = 2, score_by = "accuracy",
                                            clusters = clusters)
  expect_true(is.data.frame(results$summary))

  # DT = TRUE: htmlwidget
  skip_if_not_installed("DT")
  results_dt <- optimize_combinations_clusters(test_data, n_symptoms = 5, n_required = 4,
                                               n_top = 2, score_by = "accuracy",
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
                                   n_top = 2, score_by = "accuracy")
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
                                   n_top = 2, score_by = "accuracy")

  # Write
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))
  write_combinations(results, tmp, n_required = 3, score_by = "accuracy")

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

test_that("optimize_combinations returns n_tied count", {
  set.seed(42)
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  results <- optimize_combinations(test_data, n_symptoms = 4, n_required = 3,
                                   n_top = 2, score_by = "accuracy")

  expect_true("n_tied" %in% names(results))
  expect_true(is.integer(results$n_tied))
  expect_true(results$n_tied >= 0L)
})

test_that("optimize_combinations_clusters returns n_tied count", {
  set.seed(42)
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE),
           nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  clusters <- list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)
  results <- optimize_combinations_clusters(test_data, n_symptoms = 5,
               n_required = 4, n_top = 2, score_by = "accuracy",
               clusters = clusters)

  expect_true("n_tied" %in% names(results))
  expect_true(is.integer(results$n_tied))
  expect_true(results$n_tied >= 0L)
})

# ---------------------------------------------------------------------------
# id_col / carry-through round-trip
# ---------------------------------------------------------------------------

test_that("optimize_combinations carries ID columns into diagnosis_comparison", {
  set.seed(7)
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:60),
    age        = sample(20:70, 60, replace = TRUE),
    matrix(sample(0:4, 20 * 60, replace = TRUE), nrow = 60, ncol = 20),
    stringsAsFactors = FALSE
  )
  sym <- rename_ptsd_columns(raw, id_col = c("patient_id", "age"))
  res <- optimize_combinations(sym, n_symptoms = 6, n_required = 4,
                               n_top = 2, show_progress = FALSE)
  expect_equal(names(res$diagnosis_comparison)[1:2], c("patient_id", "age"))
  expect_equal(res$diagnosis_comparison$patient_id, raw$patient_id)
  expect_equal(nrow(res$diagnosis_comparison), nrow(raw))
})

test_that("optimize_combinations gives identical numeric results with vs without id_col", {
  set.seed(11)
  base <- data.frame(matrix(sample(0:4, 20 * 80, replace = TRUE),
                            nrow = 80, ncol = 20))
  names(base) <- paste0("symptom_", 1:20)
  with_id <- base
  with_id$patient_id <- sprintf("P%03d", 1:80)
  with_id <- with_id[, c("patient_id", paste0("symptom_", 1:20))]

  res_plain <- optimize_combinations(base, n_symptoms = 6, n_required = 4,
                                     n_top = 3, show_progress = FALSE)
  res_id    <- optimize_combinations(with_id, n_symptoms = 6, n_required = 4,
                                     n_top = 3, show_progress = FALSE)

  expect_equal(res_plain$best_symptoms, res_id$best_symptoms)
  expect_equal(res_plain$n_tied, res_id$n_tied)
  # diagnosis_comparison content is the same once IDs are stripped
  expect_equal(
    res_plain$diagnosis_comparison,
    res_id$diagnosis_comparison[, names(res_plain$diagnosis_comparison)]
  )
})

test_that("optimize_combinations_clusters carries ID columns through", {
  set.seed(13)
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:50),
    matrix(sample(0:4, 20 * 50, replace = TRUE), nrow = 50, ncol = 20),
    stringsAsFactors = FALSE
  )
  sym <- rename_ptsd_columns(raw, id_col = "patient_id")
  clusters <- list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)
  res <- optimize_combinations_clusters(
    sym, n_symptoms = 6, n_required = 4, n_top = 2,
    clusters = clusters, show_progress = FALSE
  )
  expect_equal(names(res$diagnosis_comparison)[1], "patient_id")
  expect_equal(res$diagnosis_comparison$patient_id, raw$patient_id)
})

test_that("apply_symptom_combinations carries ID columns through", {
  set.seed(17)
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:40),
    matrix(sample(0:4, 20 * 40, replace = TRUE), nrow = 40, ncol = 20),
    stringsAsFactors = FALSE
  )
  sym <- rename_ptsd_columns(raw, id_col = "patient_id")
  combos <- list(c(1, 6, 8, 10, 15, 19), c(2, 7, 9, 11, 16, 20))
  out <- apply_symptom_combinations(sym, combos, n_required = 4)
  expect_equal(names(out)[1], "patient_id")
  expect_equal(out$patient_id, raw$patient_id)

  # Demographics join-back recovers full dataframe
  joined <- merge(raw[, "patient_id", drop = FALSE], out, by = "patient_id")
  expect_equal(nrow(joined), nrow(raw))
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
      score_by = "accuracy",
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
