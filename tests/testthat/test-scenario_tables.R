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

# ---------------------------------------------------------------------------
# summarize_top_combinations()
# ---------------------------------------------------------------------------

test_that("summarize_top_combinations returns the documented columns", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  comp <- build_comparison()
  tbl  <- summarize_top_combinations(comp)
  expect_equal(
    names(tbl),
    c("Approach", "Rank", "Combination", "TP", "FN", "FP", "TN",
      "Sensitivity", "Specificity", "PPV", "NPV", "Accuracy",
      "Balanced Accuracy")
  )
  expect_false(any(tbl$Combination == "PTSD_orig"))
  expect_true(all(tbl$TP + tbl$FN + tbl$FP + tbl$TN == comp$n_rows))
  # Accuracy equals (TP + TN) / N
  expect_equal(tbl$Accuracy, (tbl$TP + tbl$TN) / comp$n_rows)
  # Balanced accuracy equals the mean of sensitivity and specificity
  expect_equal(tbl$`Balanced Accuracy`,
               (tbl$Sensitivity + tbl$Specificity) / 2)
})

test_that("summarize_top_combinations metrics are in [0, 1] by default and [0, 100] with as_percent", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  comp <- build_comparison()
  frac <- summarize_top_combinations(comp, as_percent = FALSE)
  pct  <- summarize_top_combinations(comp, as_percent = TRUE)

  expect_true(all(frac$Sensitivity >= 0 & frac$Sensitivity <= 1, na.rm = TRUE))
  expect_true(all(pct$Sensitivity  >= 0 & pct$Sensitivity  <= 100, na.rm = TRUE))
  expect_true(all(frac$Accuracy    >= 0 & frac$Accuracy    <= 1, na.rm = TRUE))
  expect_true(all(pct$Accuracy     >= 0 & pct$Accuracy     <= 100, na.rm = TRUE))
  # Conversion is consistent
  expect_equal(pct$Sensitivity, frac$Sensitivity * 100)
  expect_equal(pct$Accuracy,    frac$Accuracy * 100)
  expect_equal(pct$`Balanced Accuracy`, frac$`Balanced Accuracy` * 100)
})

test_that("summarize_top_combinations top_n caps optimize scenarios but keeps fixed at 1 row", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  comp <- build_comparison(include_icd11 = TRUE)
  tbl  <- summarize_top_combinations(comp, top_n = 2)
  counts <- table(tbl$Approach)
  expect_equal(unname(counts["ICD-11"]), 1L)
  for (label in setdiff(names(counts), "ICD-11")) {
    expect_true(counts[[label]] <= 2L)
  }
})

# ---------------------------------------------------------------------------
# symptom_frequency()
# ---------------------------------------------------------------------------

test_that("symptom_frequency returns 20 rows per scenario plus an OVERALL row when requested", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  comp <- build_comparison()
  freq <- symptom_frequency(comp, include_overall = TRUE)
  expect_equal(nrow(freq), 20 * (length(comp$scenarios) + 1))
  expect_true("OVERALL" %in% levels(freq$Approach))
  expect_setequal(unique(freq$Symptom), 1:20)
})

test_that("OVERALL Count equals the sum of optimize-scenario counts by default", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  comp <- build_comparison(include_icd11 = TRUE)
  freq <- symptom_frequency(comp, include_overall = TRUE,
                            overall_includes_fixed = FALSE)
  optimize_labels <- comp$config$label[comp$config$type == "optimize"]
  opt_only <- freq[freq$Approach %in% optimize_labels, ]
  totals <- tapply(opt_only$Count, opt_only$Symptom, sum)

  overall <- freq[freq$Approach == "OVERALL", ]
  overall <- overall[order(overall$Symptom), ]
  expect_equal(unname(overall$Count), as.integer(unname(totals)))
})

test_that("ICD-11 fixed scenario contributes Count = 1 on its 6 known symptoms", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  comp <- build_comparison(include_icd11 = TRUE)
  freq <- symptom_frequency(comp, include_overall = FALSE)
  icd <- freq[freq$Approach == "ICD-11", ]
  icd <- icd[order(icd$Symptom), ]
  expected <- integer(20)
  expected[c(2, 3, 6, 7, 17, 18)] <- 1L
  expect_equal(icd$Count, expected)
  expect_equal(icd$RelFreq, as.numeric(expected))  # n_combinations = 1
})

test_that("overall_includes_fixed = TRUE folds fixed scenarios into the OVERALL pool", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  comp <- build_comparison(include_icd11 = TRUE)
  freq_excl <- symptom_frequency(comp, overall_includes_fixed = FALSE)
  freq_incl <- symptom_frequency(comp, overall_includes_fixed = TRUE)
  excl <- freq_excl[freq_excl$Approach == "OVERALL", ]
  incl <- freq_incl[freq_incl$Approach == "OVERALL", ]
  # Including ICD-11 should add 1 to its 6 known symptoms
  delta <- incl$Count - excl$Count
  delta <- delta[order(freq_excl$Symptom[freq_excl$Approach == "OVERALL"])]
  expected_delta <- integer(20)
  expected_delta[c(2, 3, 6, 7, 17, 18)] <- 1L
  expect_equal(delta, expected_delta)
})

test_that("summary tables work on a compact comparison (CRAN smoke test)", {
  # The tests above share cached default-scenario comparisons (91,205
  # candidates each) and are CI-only; this compact 4-symptom search keeps the
  # core output structure exercised on CRAN itself.
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

  tab <- summarize_top_combinations(comp)
  expect_equal(names(tab),
               c("Approach", "Rank", "Combination", "TP", "FN", "FP", "TN",
                 "Sensitivity", "Specificity", "PPV", "NPV", "Accuracy",
                 "Balanced Accuracy"))
  expect_equal(tab$Rank, 1:3)
  expect_true(all(tab$TP + tab$FN + tab$FP + tab$TN == 60))

  freq <- symptom_frequency(comp)
  expect_equal(nrow(freq), 40)  # 20 symptoms x (scenario + OVERALL)
  expect_equal(freq$Count[freq$Approach == "OVERALL"],
               freq$Count[freq$Approach == "3/4 Non-hierarchical"])
})
