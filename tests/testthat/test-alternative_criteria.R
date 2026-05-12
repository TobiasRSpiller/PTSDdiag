# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a 20-column PCL-5 dataframe from a named list of item -> score vectors.
# All unspecified items default to 0.
make_pcl5 <- function(...) {
  scores <- list(...)
  base   <- as.list(stats::setNames(rep(0L, 20L), paste0("symptom_", 1:20)))
  for (nm in names(scores)) base[[nm]] <- scores[[nm]]
  as.data.frame(base)
}

# 4 carefully constructed single-row PCL-5 cases for ICD-11 verification:
#   row1: all three ICD-11 clusters present -> TRUE
#   row2: no re-experiencing           -> FALSE
#   row3: no avoidance                 -> FALSE
#   row4: no sense-of-current-threat   -> FALSE
icd11_cases <- rbind(
  # row 1: all three ICD-11 clusters present; also meets DSM-5-TR
  #   (B: item 1; C: item 6; D: items 8,9; E: items 15,16) -> PTSD_orig TRUE
  make_pcl5(symptom_1 = 3, symptom_2 = 3, symptom_3 = 3,
            symptom_6 = 3, symptom_7  = 3,
            symptom_8 = 3, symptom_9  = 3,
            symptom_15 = 3, symptom_16 = 3, symptom_17 = 3),
  # row 2: re-experiencing absent (items 1-3 all 0) -> ICD-11 FALSE
  make_pcl5(symptom_6 = 3, symptom_7  = 3,
            symptom_16 = 3, symptom_17 = 3),
  # row 3: avoidance absent (items 6-7 all 0) -> ICD-11 FALSE
  make_pcl5(symptom_1 = 3, symptom_2 = 3, symptom_3 = 3,
            symptom_16 = 3, symptom_17 = 3),
  # row 4: sense-of-current-threat absent (items 16-17 all 0) -> ICD-11 FALSE
  make_pcl5(symptom_1 = 3, symptom_2 = 3, symptom_3 = 3,
            symptom_6 = 3, symptom_7  = 3)
)

# ---------------------------------------------------------------------------
# create_icd11_diagnosis()
# ---------------------------------------------------------------------------

test_that("create_icd11_diagnosis returns a data.frame with correct columns", {
  result <- create_icd11_diagnosis(icd11_cases)
  expect_true(is.data.frame(result))
  expect_equal(names(result), c("PTSD_orig", "PTSD_icd11"))
  expect_true(is.logical(result$PTSD_orig))
  expect_true(is.logical(result$PTSD_icd11))
  expect_equal(nrow(result), 4L)
})

test_that("create_icd11_diagnosis: patient meeting all clusters is TRUE", {
  result <- create_icd11_diagnosis(icd11_cases)
  expect_true(result$PTSD_icd11[1])
})

test_that("create_icd11_diagnosis: missing re-experiencing -> FALSE", {
  result <- create_icd11_diagnosis(icd11_cases)
  expect_false(result$PTSD_icd11[2])
})

test_that("create_icd11_diagnosis: missing avoidance -> FALSE", {
  result <- create_icd11_diagnosis(icd11_cases)
  expect_false(result$PTSD_icd11[3])
})

test_that("create_icd11_diagnosis: missing sense-of-current-threat -> FALSE", {
  result <- create_icd11_diagnosis(icd11_cases)
  expect_false(result$PTSD_icd11[4])
})

test_that("create_icd11_diagnosis output passes into summarize_ptsd_changes", {
  result  <- create_icd11_diagnosis(icd11_cases)
  metrics <- summarize_ptsd_changes(result)
  expect_true(is.data.frame(metrics))
  expect_true("PTSD_icd11" %in% metrics$column)
})

test_that("create_icd11_diagnosis errors on wrong column names", {
  bad <- icd11_cases
  names(bad)[1] <- "item_1"
  expect_error(create_icd11_diagnosis(bad))
})

test_that("create_icd11_diagnosis errors on values out of 0-4 range", {
  bad <- icd11_cases
  bad$symptom_1 <- 5L
  expect_error(create_icd11_diagnosis(bad))
})

test_that("create_icd11_diagnosis errors on missing values", {
  bad <- icd11_cases
  bad$symptom_1[1] <- NA_integer_
  expect_error(create_icd11_diagnosis(bad))
})

test_that("create_icd11_diagnosis errors on non-data.frame input", {
  expect_error(create_icd11_diagnosis(as.matrix(icd11_cases)))
})

# ---------------------------------------------------------------------------
# compare_diagnostic_systems()
# ---------------------------------------------------------------------------

# Reusable comparison df: one pre-specified combination applied to icd11_cases
combo_df <- apply_symptom_combinations(
  icd11_cases,
  combinations = list(c(1, 6, 8, 10, 15, 19)),
  n_required   = 1L
)

test_that("compare_diagnostic_systems returns a data.frame with 12 columns", {
  result <- compare_diagnostic_systems(icd11_cases, combo_df, icd11 = TRUE)
  expect_true(is.data.frame(result))
  expect_equal(ncol(result), 12L)
  expect_equal(names(result)[1], "system")
})

test_that("compare_diagnostic_systems icd11=TRUE includes DSM-5-TR and ICD-11 rows", {
  result <- compare_diagnostic_systems(icd11_cases, combo_df, icd11 = TRUE)
  expect_true("DSM-5-TR" %in% result$system)
  expect_true("ICD-11"   %in% result$system)
})

test_that("compare_diagnostic_systems icd11=FALSE omits ICD-11 row", {
  result <- compare_diagnostic_systems(icd11_cases, combo_df, icd11 = FALSE)
  expect_true("DSM-5-TR"  %in% result$system)
  expect_false("ICD-11"   %in% result$system)
})

test_that("compare_diagnostic_systems DSM-5-TR row has perfect metrics", {
  result  <- compare_diagnostic_systems(icd11_cases, combo_df, icd11 = FALSE)
  ref_row <- result[result$system == "DSM-5-TR", ]
  expect_equal(ref_row$sensitivity,      1)
  expect_equal(ref_row$specificity,      1)
  expect_equal(ref_row$n_false_negative, 0L)
  expect_equal(ref_row$n_false_positive, 0L)
  expect_equal(ref_row$n_misclassified,  0L)
})

test_that("compare_diagnostic_systems labels override ... column names", {
  result <- compare_diagnostic_systems(
    icd11_cases, combo_df,
    icd11  = FALSE,
    labels = "My Combo"
  )
  expect_true("My Combo" %in% result$system)
})

test_that("compare_diagnostic_systems warns on mismatched labels length", {
  expect_warning(
    compare_diagnostic_systems(icd11_cases, combo_df,
                               icd11 = FALSE, labels = c("A", "B")),
    regexp = "labels"
  )
})

test_that("compare_diagnostic_systems errors with icd11=FALSE and no ... inputs", {
  expect_error(
    compare_diagnostic_systems(icd11_cases, icd11 = FALSE),
    regexp = "No diagnostic systems"
  )
})

test_that("compare_diagnostic_systems errors on mismatched PTSD_orig", {
  # Build a comparison df whose PTSD_orig has been manually flipped so it
  # differs from what .validate_pcl5_data + create_ptsd_diagnosis_binarized
  # would compute from icd11_cases.  icd11_cases row 1 has PTSD_orig = TRUE
  # (meets DSM-5-TR), rows 2-4 are FALSE, so reversing produces a genuine mismatch.
  bad_df           <- combo_df
  bad_df$PTSD_orig <- rev(bad_df$PTSD_orig)
  expect_error(
    compare_diagnostic_systems(icd11_cases, bad_df, icd11 = FALSE),
    regexp = "PTSD_orig"
  )
})

test_that("compare_diagnostic_systems errors when ... input lacks PTSD_orig", {
  no_orig <- combo_df[, setdiff(names(combo_df), "PTSD_orig"), drop = FALSE]
  expect_error(
    compare_diagnostic_systems(icd11_cases, no_orig, icd11 = FALSE),
    regexp = "PTSD_orig"
  )
})

test_that("compare_diagnostic_systems errors when ... input is not a data.frame", {
  expect_error(
    compare_diagnostic_systems(icd11_cases, "not_a_df", icd11 = FALSE),
    regexp = "data.frame"
  )
})

test_that("compare_diagnostic_systems icd11=TRUE with no ... has 2 rows", {
  result <- compare_diagnostic_systems(icd11_cases, icd11 = TRUE)
  expect_equal(nrow(result), 2L)
  expect_equal(result$system, c("DSM-5-TR", "ICD-11"))
})
