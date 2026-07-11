# ---------------------------------------------------------------------------
# score_all_combinations()
# ---------------------------------------------------------------------------

make_score_data <- function(n, seed) {
  set.seed(seed)
  df <- as.data.frame(matrix(sample(0:4, 20 * n, replace = TRUE),
                             nrow = n, ncol = 20))
  names(df) <- paste0("symptom_", 1:20)
  df
}

test_that("score_all_combinations scores the complete candidate set", {
  df <- make_score_data(60, 101)

  curve <- score_all_combinations(df, n_symptoms = 3, n_required = 2,
                                  show_progress = FALSE)

  expect_equal(nrow(curve), choose(20, 3))
  expect_equal(curve$rank, seq_len(nrow(curve)))
  expect_equal(attr(curve, "n_combinations"), choose(20, 3))

  # the 2x2 always partitions the sample
  expect_true(all(curve$tp + curve$fn + curve$fp + curve$tn == nrow(df)))

  # ranking is monotone in the scoring metric
  expect_true(all(diff(curve$balanced_accuracy) <= 0))
})

test_that("score_all_combinations agrees with optimize_combinations at the top", {
  df <- make_score_data(60, 101)

  curve <- score_all_combinations(df, n_symptoms = 3, n_required = 2,
                                  show_progress = FALSE)
  opt <- optimize_combinations(df, n_symptoms = 3, n_required = 2, n_top = 5,
                               show_progress = FALSE)

  # compare scores, not IDs: ties are broken differently (first-encountered
  # in the optimizer, lexicographic here), but the score multiset must match
  opt_ids <- vapply(opt$best_symptoms, paste, character(1), collapse = "_")
  opt_ba  <- sort(curve$balanced_accuracy[match(opt_ids, curve$combination_id)],
                  decreasing = TRUE)
  expect_equal(opt_ba, curve$balanced_accuracy[1:5])
})

test_that("score_all_combinations metrics match summarize_ptsd_changes", {
  df <- make_score_data(50, 102)

  curve <- score_all_combinations(df, n_symptoms = 3, n_required = 2,
                                  show_progress = FALSE)

  combo <- c(2, 9, 17)
  applied <- apply_symptom_combinations(df, list(combo), n_required = 2)
  stats <- summarize_ptsd_changes(applied)
  s <- stats[stats$column == "symptom_2_9_17", ]
  row <- curve[curve$combination_id == "2_9_17", ]

  expect_equal(row$tp, s$true_positive)
  expect_equal(row$fn, s$newly_nondiagnosed)
  expect_equal(row$fp, s$newly_diagnosed)
  expect_equal(row$tn, s$true_negative)
  expect_equal(row$sensitivity, s$sensitivity)
  expect_equal(row$specificity, s$specificity)
  expect_equal(row$balanced_accuracy, s$balanced_accuracy)
})

test_that("score_all_combinations cluster mode uses the constrained candidate set", {
  df <- make_score_data(60, 103)
  clusters <- list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)

  curve <- score_all_combinations(df, n_symptoms = 4, n_required = 2,
                                  clusters = clusters, show_progress = FALSE)

  # one item per cluster: 5 * 2 * 7 * 6 = 420 candidates
  expect_equal(nrow(curve), 420)

  # every candidate spans all four clusters
  spans <- vapply(strsplit(curve$combination_id, "_"), function(x) {
    v <- as.integer(x)
    any(v %in% 1:5) && any(v %in% 6:7) &&
      any(v %in% 8:14) && any(v %in% 15:20)
  }, logical(1))
  expect_true(all(spans))
})

test_that("chunk_size never changes the result", {
  df <- make_score_data(40, 104)

  a <- score_all_combinations(df, n_symptoms = 3, n_required = 2,
                              chunk_size = 1, show_progress = FALSE)
  b <- score_all_combinations(df, n_symptoms = 3, n_required = 2,
                              chunk_size = 7, show_progress = FALSE)
  c <- score_all_combinations(df, n_symptoms = 3, n_required = 2,
                              chunk_size = 10000, show_progress = FALSE)

  expect_identical(a, b)
  expect_identical(b, c)
})

test_that("score_all_combinations validates its inputs", {
  df <- make_score_data(20, 105)

  expect_error(score_all_combinations(df, chunk_size = 0,
                                      show_progress = FALSE),
               "positive integer")
  expect_error(score_all_combinations(df, score_by = "nonsense",
                                      show_progress = FALSE),
               "score_by")

  # single-class reference: balanced accuracy is undefined, accuracy works
  zeros <- as.data.frame(matrix(0L, nrow = 10, ncol = 20))
  names(zeros) <- paste0("symptom_", 1:20)
  expect_error(score_all_combinations(zeros, n_symptoms = 3, n_required = 2,
                                      show_progress = FALSE),
               "balanced_accuracy")
  ok <- score_all_combinations(zeros, n_symptoms = 3, n_required = 2,
                               score_by = "accuracy", show_progress = FALSE)
  expect_equal(nrow(ok), choose(20, 3))
})
