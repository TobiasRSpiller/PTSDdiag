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

# ---------------------------------------------------------------------------
# create_caps5_diagnosis()
# ---------------------------------------------------------------------------

test_that("create_caps5_diagnosis returns a data.frame with PTSD_caps5 column", {
  result <- create_caps5_diagnosis(icd11_cases)
  expect_true(is.data.frame(result))
  expect_equal(names(result), "PTSD_caps5")
  expect_true(is.logical(result$PTSD_caps5))
  expect_equal(nrow(result), 4L)
})

test_that("create_caps5_diagnosis agrees with create_ptsd_diagnosis_binarized", {
  result_caps5 <- create_caps5_diagnosis(icd11_cases)$PTSD_caps5
  result_binar <- create_ptsd_diagnosis_binarized(icd11_cases)$PTSD_orig
  expect_identical(result_caps5, result_binar)
})

test_that("create_caps5_diagnosis: all criteria met -> TRUE", {
  all_met <- make_pcl5(
    symptom_1 = 3, symptom_6 = 3, symptom_8 = 3, symptom_9 = 3,
    symptom_15 = 3, symptom_16 = 3
  )
  expect_true(create_caps5_diagnosis(all_met)$PTSD_caps5)
})

test_that("create_caps5_diagnosis: criterion B not met -> FALSE", {
  no_b <- make_pcl5(
    symptom_6 = 3, symptom_8 = 3, symptom_9 = 3,
    symptom_15 = 3, symptom_16 = 3
  )
  expect_false(create_caps5_diagnosis(no_b)$PTSD_caps5)
})

test_that("create_caps5_diagnosis errors on wrong column names", {
  bad <- icd11_cases
  names(bad)[1] <- "item_1"
  expect_error(create_caps5_diagnosis(bad))
})

test_that("create_caps5_diagnosis errors on values out of 0-4 range", {
  bad <- icd11_cases
  bad$symptom_1 <- 5L
  expect_error(create_caps5_diagnosis(bad))
})

test_that("create_caps5_diagnosis errors on non-data.frame input", {
  expect_error(create_caps5_diagnosis(as.matrix(icd11_cases)))
})

# ---------------------------------------------------------------------------
# compare_diagnostic_systems() — CAPS-5 extension
# ---------------------------------------------------------------------------

# Build CAPS-5 cases with different scores than icd11_cases so diagnoses differ.
# Row 1: meets DSM-5-TR on CAPS-5 (same as PCL-5)
# Row 2: also meets DSM-5-TR on CAPS-5 (differs from PCL-5 where it's FALSE)
# Row 3: does not meet
# Row 4: does not meet
caps5_cases <- rbind(
  make_pcl5(symptom_1 = 3, symptom_2 = 3, symptom_3 = 3,
            symptom_6 = 3, symptom_7 = 3,
            symptom_8 = 3, symptom_9 = 3,
            symptom_15 = 3, symptom_16 = 3, symptom_17 = 3),
  make_pcl5(symptom_1 = 3, symptom_6 = 3,
            symptom_8 = 3, symptom_9 = 3,
            symptom_15 = 3, symptom_16 = 3),
  make_pcl5(),
  make_pcl5()
)

test_that("compare_diagnostic_systems backward compat: no caps5_data", {
  result <- compare_diagnostic_systems(icd11_cases, combo_df, icd11 = TRUE)
  expect_true("DSM-5-TR" %in% result$system)
  expect_true("ICD-11"   %in% result$system)
  # Labels are NOT disambiguated when caps5_data is NULL
  expect_false("DSM-5-TR (PCL-5)" %in% result$system)
})

test_that("compare_diagnostic_systems with caps5_data adds CAPS-5 row", {
  result <- compare_diagnostic_systems(
    icd11_cases, combo_df,
    icd11 = TRUE, caps5_data = caps5_cases
  )
  expect_true("DSM-5-TR (PCL-5)"  %in% result$system)
  expect_true("DSM-5-TR (CAPS-5)" %in% result$system)
  expect_true("ICD-11 (PCL-5)"    %in% result$system)
  expect_equal(ncol(result), 12L)
})

test_that("compare_diagnostic_systems caps5 reference has perfect metrics", {
  result <- compare_diagnostic_systems(
    icd11_cases, caps5_data = caps5_cases,
    icd11 = TRUE, reference = "caps5"
  )
  ref_row <- result[result$system == "DSM-5-TR (CAPS-5)", ]
  expect_equal(ref_row$sensitivity,      1)
  expect_equal(ref_row$specificity,      1)
  expect_equal(ref_row$n_false_negative, 0L)
  expect_equal(ref_row$n_false_positive, 0L)
  expect_equal(ref_row$n_misclassified,  0L)
})

test_that("compare_diagnostic_systems caps5 reference includes PCL-5 comparison", {
  result <- compare_diagnostic_systems(
    icd11_cases, caps5_data = caps5_cases,
    icd11 = FALSE, reference = "caps5"
  )
  expect_true("DSM-5-TR (PCL-5)" %in% result$system)
})

test_that("compare_diagnostic_systems reference='caps5' requires caps5_data", {
  expect_error(
    compare_diagnostic_systems(icd11_cases, icd11 = TRUE, reference = "caps5"),
    regexp = "caps5_data"
  )
})

test_that("compare_diagnostic_systems caps5_data row count must match", {
  bad_caps5 <- caps5_cases[1:2, ]
  expect_error(
    compare_diagnostic_systems(icd11_cases, caps5_data = bad_caps5, icd11 = TRUE),
    regexp = "rows"
  )
})

test_that("compare_diagnostic_systems relaxes PTSD_orig check with caps5_data", {
  # apply_symptom_combinations on caps5 data produces different PTSD_orig
  caps5_combos <- apply_symptom_combinations(
    caps5_cases, combinations = list(c(1, 6, 8, 10, 15, 19)), n_required = 1L
  )
  # This should NOT error despite different PTSD_orig
  result <- compare_diagnostic_systems(
    icd11_cases, caps5_combos,
    caps5_data = caps5_cases, icd11 = FALSE
  )
  expect_true(is.data.frame(result))
  expect_equal(ncol(result), 12L)
})

test_that("compare_diagnostic_systems strict check still works without caps5_data", {
  bad_df <- combo_df
  bad_df$PTSD_orig <- rev(bad_df$PTSD_orig)
  expect_error(
    compare_diagnostic_systems(icd11_cases, bad_df, icd11 = FALSE),
    regexp = "PTSD_orig"
  )
})

test_that("compare_diagnostic_systems errors on duplicate column names in ...", {
  # Same combo applied to both datasets produces identical column names
  pcl5_combos <- apply_symptom_combinations(
    icd11_cases, combinations = list(c(1, 6, 8, 10, 15, 19)), n_required = 1L
  )
  caps5_combos <- apply_symptom_combinations(
    caps5_cases, combinations = list(c(1, 6, 8, 10, 15, 19)), n_required = 1L
  )
  expect_error(
    compare_diagnostic_systems(
      icd11_cases, pcl5_combos, caps5_combos,
      caps5_data = caps5_cases, icd11 = FALSE
    ),
    regexp = "Duplicate"
  )
})

test_that("compare_diagnostic_systems labels work with caps5_data", {
  result <- compare_diagnostic_systems(
    icd11_cases, combo_df,
    caps5_data = caps5_cases, icd11 = FALSE,
    labels = "My Combo"
  )
  expect_true("My Combo" %in% result$system)
  # Built-in labels should not be overridden
  expect_true("DSM-5-TR (PCL-5)"  %in% result$system)
  expect_true("DSM-5-TR (CAPS-5)" %in% result$system)
})

test_that("compare_diagnostic_systems caps5_data only (no ... no icd11)", {
  result <- compare_diagnostic_systems(
    icd11_cases, caps5_data = caps5_cases,
    icd11 = FALSE, reference = "pcl5"
  )
  expect_equal(nrow(result), 2L)
  expect_equal(result$system, c("DSM-5-TR (PCL-5)", "DSM-5-TR (CAPS-5)"))
})

# ---------------------------------------------------------------------------
# id_col carry-through
# ---------------------------------------------------------------------------

test_that("create_icd11_diagnosis prepends ID columns when present", {
  data_with_id <- icd11_cases
  data_with_id$patient_id <- sprintf("P%02d", seq_len(nrow(icd11_cases)))
  data_with_id <- data_with_id[, c("patient_id", paste0("symptom_", 1:20))]

  result <- create_icd11_diagnosis(data_with_id)
  expect_equal(names(result), c("patient_id", "PTSD_orig", "PTSD_icd11"))
  expect_equal(result$patient_id, data_with_id$patient_id)

  # Diagnostic columns must match the no-ID version
  plain <- create_icd11_diagnosis(icd11_cases)
  expect_equal(result$PTSD_orig, plain$PTSD_orig)
  expect_equal(result$PTSD_icd11, plain$PTSD_icd11)
})

test_that("create_caps5_diagnosis prepends ID columns when present", {
  data_with_id <- icd11_cases
  data_with_id$patient_id <- sprintf("P%02d", seq_len(nrow(icd11_cases)))
  data_with_id <- data_with_id[, c("patient_id", paste0("symptom_", 1:20))]

  result <- create_caps5_diagnosis(data_with_id)
  expect_equal(names(result), c("patient_id", "PTSD_caps5"))
  expect_equal(result$patient_id, data_with_id$patient_id)
})

test_that("compare_diagnostic_systems ignores ID columns in ... inputs", {
  set.seed(41)
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:60),
    matrix(sample(0:4, 20 * 60, replace = TRUE), nrow = 60, ncol = 20),
    stringsAsFactors = FALSE
  )
  sym <- rename_ptsd_columns(raw, id_col = "patient_id")

  combos <- list(c(1, 6, 8, 10, 15, 19), c(2, 7, 9, 11, 16, 20))
  applied <- apply_symptom_combinations(sym, combos, n_required = 4)

  tbl <- compare_diagnostic_systems(sym, applied, icd11 = TRUE)
  # System names should be DSM-5-TR, ICD-11, plus the two combinations -- no patient_id
  expect_false("patient_id" %in% tbl$system)
  expect_true(all(c("DSM-5-TR", "ICD-11") %in% tbl$system))
  # Two combination rows
  expect_equal(sum(grepl("^symptom_", tbl$system)), 2L)
})
