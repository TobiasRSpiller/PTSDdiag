make_comp <- function(n = 200, seed = 7) {
  set.seed(seed)
  df <- as.data.frame(matrix(sample(0:4, 20 * n, replace = TRUE), nrow = n,
                             ncol = 20))
  names(df) <- paste0("symptom_", 1:20)
  compare_optimizations(df, n_top = 8, show_progress = FALSE)
}

# ---------------------------------------------------------------------------
# extract_definitions()
# ---------------------------------------------------------------------------

test_that("extract_definitions returns one entry per optimize scenario with rules from config", {
  comp <- make_comp()
  defs <- extract_definitions(comp, n = 5)

  expect_equal(names(defs),
               c("4/6 Hierarchical", "4/6 Non-hierarchical", "3/6 Non-hierarchical"))
  expect_true(all(vapply(defs, function(d) length(d$symptoms), integer(1)) == 5))
  expect_equal(defs[["4/6 Hierarchical"]]$n_required, 4)
  expect_true(defs[["4/6 Hierarchical"]]$hierarchical)
  expect_equal(defs[["3/6 Non-hierarchical"]]$n_required, 3)
  expect_false(defs[["3/6 Non-hierarchical"]]$hierarchical)
})

test_that("extract_definitions caps n at the number available and validates inputs", {
  comp <- make_comp()
  defs <- extract_definitions(comp, n = 50)  # more than n_top
  expect_true(all(vapply(defs, function(d) length(d$symptoms), integer(1)) == 8))

  expect_error(extract_definitions(comp, n = 0), "positive integer")
  expect_error(extract_definitions(list(), n = 5), "ptsdiag_comparison")
})

test_that("extract_definitions skips fixed scenarios", {
  set.seed(11)
  df <- as.data.frame(matrix(sample(0:4, 20 * 200, replace = TRUE), nrow = 200,
                             ncol = 20))
  names(df) <- paste0("symptom_", 1:20)
  comp <- compare_optimizations(df, n_top = 5, include_icd11 = TRUE,
                                show_progress = FALSE)
  defs <- extract_definitions(comp, n = 3)
  expect_false("ICD-11" %in% names(defs))
  expect_equal(length(defs), 3)
})

# ---------------------------------------------------------------------------
# evaluate_definitions()
# ---------------------------------------------------------------------------

test_that("evaluate_definitions returns a performance table with Accuracy and ICD-11", {
  comp <- make_comp()
  defs <- extract_definitions(comp, n = 2)

  set.seed(21)
  newdata <- as.data.frame(matrix(sample(0:4, 20 * 150, replace = TRUE),
                                  nrow = 150, ncol = 20))
  names(newdata) <- paste0("symptom_", 1:20)

  tbl <- evaluate_definitions(newdata, defs, include_icd11 = TRUE)
  expect_true("Accuracy" %in% names(tbl))
  expect_true("Scenario" %in% names(tbl))
  # reference + 2 defs x 3 rules + ICD-11 = 1 + 6 + 1 = 8 rows
  expect_equal(nrow(tbl), 8)
  expect_true(any(tbl$Scenario == "ICD-11"))
  expect_true(any(tbl$Scenario == "PTSD_orig"))
})

test_that("evaluate_definitions can omit ICD-11", {
  comp <- make_comp()
  defs <- extract_definitions(comp, n = 1)
  set.seed(22)
  newdata <- as.data.frame(matrix(sample(0:4, 20 * 120, replace = TRUE),
                                  nrow = 120, ncol = 20))
  names(newdata) <- paste0("symptom_", 1:20)

  tbl <- evaluate_definitions(newdata, defs, include_icd11 = FALSE)
  expect_false(any(tbl$Scenario == "ICD-11"))
  # reference + 1 def x 3 rules = 4 rows
  expect_equal(nrow(tbl), 4)
})

test_that("evaluate_definitions validates the definitions object", {
  set.seed(23)
  newdata <- as.data.frame(matrix(sample(0:4, 20 * 50, replace = TRUE),
                                  nrow = 50, ncol = 20))
  names(newdata) <- paste0("symptom_", 1:20)
  expect_error(evaluate_definitions(newdata, list()), "non-empty")
})

test_that("extract -> evaluate round-trips and carries id columns in input", {
  set.seed(31)
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:200),
    matrix(sample(0:4, 20 * 200, replace = TRUE), nrow = 200, ncol = 20),
    stringsAsFactors = FALSE
  )
  d <- rename_ptsd_columns(raw, id_col = "patient_id")
  comp <- compare_optimizations(d, n_top = 5, show_progress = FALSE)
  defs <- extract_definitions(comp, n = 2)
  tbl  <- evaluate_definitions(d, defs)
  expect_s3_class(tbl, "data.frame")
  expect_true("Accuracy" %in% names(tbl))
})
