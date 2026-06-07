build_comparison <- function(n = 60, seed = 7, include_icd11 = FALSE) {
  set.seed(seed)
  df <- as.data.frame(matrix(sample(0:4, 20 * n, replace = TRUE), nrow = n,
                             ncol = 20))
  names(df) <- paste0("symptom_", 1:20)
  compare_optimizations(df, n_top = 3, include_icd11 = include_icd11,
                        show_progress = FALSE)
}

# ---------------------------------------------------------------------------
# summarize_top_combinations()
# ---------------------------------------------------------------------------

test_that("summarize_top_combinations returns the documented columns", {
  comp <- build_comparison()
  tbl  <- summarize_top_combinations(comp)
  expect_equal(
    names(tbl),
    c("Approach", "Rank", "Combination", "TP", "FN", "FP", "TN",
      "Sensitivity", "Specificity", "PPV", "NPV", "Accuracy")
  )
  expect_false(any(tbl$Combination == "PTSD_orig"))
  expect_true(all(tbl$TP + tbl$FN + tbl$FP + tbl$TN == comp$n_rows))
  # Accuracy equals (TP + TN) / N
  expect_equal(tbl$Accuracy, (tbl$TP + tbl$TN) / comp$n_rows)
})

test_that("summarize_top_combinations metrics are in [0, 1] by default and [0, 100] with as_percent", {
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
})

test_that("summarize_top_combinations top_n caps optimize scenarios but keeps fixed at 1 row", {
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
  comp <- build_comparison()
  freq <- symptom_frequency(comp, include_overall = TRUE)
  expect_equal(nrow(freq), 20 * (length(comp$scenarios) + 1))
  expect_true("OVERALL" %in% levels(freq$Approach))
  expect_setequal(unique(freq$Symptom), 1:20)
})

test_that("OVERALL Count equals the sum of optimize-scenario counts by default", {
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

test_that("ICD-11 fixed scenario contributes Count = 1 on its 7 known symptoms", {
  comp <- build_comparison(include_icd11 = TRUE)
  freq <- symptom_frequency(comp, include_overall = FALSE)
  icd <- freq[freq$Approach == "ICD-11", ]
  icd <- icd[order(icd$Symptom), ]
  expected <- integer(20)
  expected[c(1, 2, 3, 6, 7, 16, 17)] <- 1L
  expect_equal(icd$Count, expected)
  expect_equal(icd$RelFreq, as.numeric(expected))  # n_combinations = 1
})

test_that("overall_includes_fixed = TRUE folds fixed scenarios into the OVERALL pool", {
  comp <- build_comparison(include_icd11 = TRUE)
  freq_excl <- symptom_frequency(comp, overall_includes_fixed = FALSE)
  freq_incl <- symptom_frequency(comp, overall_includes_fixed = TRUE)
  excl <- freq_excl[freq_excl$Approach == "OVERALL", ]
  incl <- freq_incl[freq_incl$Approach == "OVERALL", ]
  # Including ICD-11 should add 1 to its 7 known symptoms
  delta <- incl$Count - excl$Count
  delta <- delta[order(freq_excl$Symptom[freq_excl$Approach == "OVERALL"])]
  expected_delta <- integer(20)
  expected_delta[c(1, 2, 3, 6, 7, 16, 17)] <- 1L
  expect_equal(delta, expected_delta)
})
