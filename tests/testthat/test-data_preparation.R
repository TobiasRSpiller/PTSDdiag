test_that("rename_ptsd_columns works correctly", {
  # Create test data
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 10, replace = TRUE),
           nrow = 10,
           ncol = 20)
  )

  # Tests renaming
  renamed_data <- rename_ptsd_columns(test_data)
  expect_equal(colnames(renamed_data), paste0("symptom_", 1:20))

  # Tests if dimensions are preserved
  expect_equal(dim(renamed_data), dim(test_data))

  # Tests if data values are preserved
  expect_equal(renamed_data[1,1], test_data[1,1])

  # Test with already correctly named columns
  already_named <- test_data
  colnames(already_named) <- paste0("symptom_", 1:20)
  renamed_again <- rename_ptsd_columns(already_named)
  expect_equal(colnames(renamed_again), paste0("symptom_", 1:20))
})

# ---------------------------------------------------------------------------
# rename_caps5_columns()
# ---------------------------------------------------------------------------

test_that("rename_caps5_columns works correctly", {
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 10, replace = TRUE), nrow = 10, ncol = 20)
  )

  renamed <- rename_caps5_columns(test_data)
  expect_equal(colnames(renamed), paste0("symptom_", 1:20))
  expect_equal(dim(renamed), dim(test_data))
  expect_equal(renamed[1, 1], test_data[1, 1])
})

test_that("rename_caps5_columns errors on wrong number of columns", {
  bad <- data.frame(matrix(0L, nrow = 5, ncol = 19))
  expect_error(rename_caps5_columns(bad), "exactly 20")
})

test_that("rename_caps5_columns errors on non-numeric data", {
  bad <- data.frame(matrix("a", nrow = 5, ncol = 20))
  expect_error(rename_caps5_columns(bad), "numeric")
})

test_that("rename_caps5_columns errors on out-of-range values", {
  bad <- data.frame(matrix(5L, nrow = 5, ncol = 20))
  expect_error(rename_caps5_columns(bad), "0 and 4")
})

test_that("rename_caps5_columns errors on NA values", {
  bad <- data.frame(matrix(0L, nrow = 5, ncol = 20))
  bad[1, 1] <- NA
  expect_error(rename_caps5_columns(bad), "missing values")
})

# ---------------------------------------------------------------------------
# id_col carry-through
# ---------------------------------------------------------------------------

test_that("rename_ptsd_columns preserves a single id_col", {
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:10),
    matrix(sample(0:4, 20 * 10, replace = TRUE), nrow = 10, ncol = 20),
    stringsAsFactors = FALSE
  )
  renamed <- rename_ptsd_columns(raw, id_col = "patient_id")
  expect_equal(names(renamed), c("patient_id", paste0("symptom_", 1:20)))
  expect_equal(renamed$patient_id, raw$patient_id)
})

test_that("rename_ptsd_columns preserves multiple id_col entries", {
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:10),
    visit      = rep(1:2, 5),
    matrix(sample(0:4, 20 * 10, replace = TRUE), nrow = 10, ncol = 20),
    stringsAsFactors = FALSE
  )
  renamed <- rename_ptsd_columns(raw, id_col = c("patient_id", "visit"))
  expect_equal(names(renamed)[1:2], c("patient_id", "visit"))
  expect_equal(names(renamed)[-(1:2)], paste0("symptom_", 1:20))
})

test_that("rename_ptsd_columns default is unchanged when id_col is NULL", {
  raw <- data.frame(matrix(sample(0:4, 20 * 10, replace = TRUE),
                           nrow = 10, ncol = 20))
  renamed <- rename_ptsd_columns(raw)
  expect_equal(names(renamed), paste0("symptom_", 1:20))
  expect_equal(nrow(renamed), 10)
})

test_that("rename_ptsd_columns errors when id_col is missing from data", {
  raw <- data.frame(matrix(sample(0:4, 20 * 10, replace = TRUE),
                           nrow = 10, ncol = 20))
  expect_error(
    rename_ptsd_columns(raw, id_col = "patient_id"),
    "not present"
  )
})

test_that("rename_ptsd_columns errors when id_col collides with reserved names", {
  raw <- data.frame(
    total = 1:10,
    matrix(sample(0:4, 20 * 10, replace = TRUE), nrow = 10, ncol = 20)
  )
  expect_error(
    rename_ptsd_columns(raw, id_col = "total"),
    "reserved"
  )
})

test_that("rename_ptsd_columns errors when remaining columns are not 20", {
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:10),
    matrix(sample(0:4, 19 * 10, replace = TRUE), nrow = 10, ncol = 19)
  )
  expect_error(
    rename_ptsd_columns(raw, id_col = "patient_id"),
    "20"
  )
})

test_that("rename_ptsd_columns errors loudly on 50-column input (no silent renaming)", {
  # Demographics + 20 PCL-5 + 27 columns from a depression inventory = 50 cols.
  # The function must error, never silently rename the first 20 non-ID columns.
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:10),
    age        = sample(20:60, 10, replace = TRUE),
    sex        = sample(c("F", "M"), 10, replace = TRUE),
    matrix(sample(0:4, 47 * 10, replace = TRUE), nrow = 10, ncol = 47),
    stringsAsFactors = FALSE
  )
  expect_error(
    rename_ptsd_columns(raw, id_col = c("patient_id", "age", "sex")),
    "exactly 20"
  )
  # The hint about listing unrelated columns in id_col must be present
  expect_error(
    rename_ptsd_columns(raw, id_col = c("patient_id", "age", "sex")),
    "id_col"
  )
})

test_that("rename_caps5_columns preserves id_col", {
  raw <- data.frame(
    patient_id = sprintf("P%03d", 1:10),
    matrix(sample(0:4, 20 * 10, replace = TRUE), nrow = 10, ncol = 20),
    stringsAsFactors = FALSE
  )
  renamed <- rename_caps5_columns(raw, id_col = "patient_id")
  expect_equal(names(renamed), c("patient_id", paste0("symptom_", 1:20)))
  expect_equal(renamed$patient_id, raw$patient_id)
})

# ---------------------------------------------------------------------------
# check_pcl5_data()
# ---------------------------------------------------------------------------

test_that("check_pcl5_data passes clean data and returns invisible TRUE", {
  clean <- data.frame(matrix(sample(0:4, 20 * 10, replace = TRUE),
                             nrow = 10, ncol = 20))
  expect_message(res <- check_pcl5_data(clean), "All checks passed")
  expect_true(res)
})

test_that("check_pcl5_data reports all problems in one error", {
  set.seed(9)
  bad <- data.frame(matrix(sample(0:4, 20 * 10, replace = TRUE),
                           nrow = 10, ncol = 20))
  bad$extra <- 1              # a 21st item column
  bad[3, 2]  <- NA            # a missing value
  bad[5, 4]  <- 9             # out of the 0-4 range

  # one abort carries all three problems
  expect_error(check_pcl5_data(bad), "got 21")
  expect_error(check_pcl5_data(bad), "missing value")
  expect_error(check_pcl5_data(bad), "0-4 range")
})

test_that("check_pcl5_data reports non-numeric item columns", {
  bad <- data.frame(matrix(sample(0:4, 19 * 6, replace = TRUE),
                           nrow = 6, ncol = 19))
  bad$text_col <- "yes"
  expect_error(check_pcl5_data(bad), "Non-numeric")
})

test_that("check_pcl5_data respects id_col and the renamed-data path", {
  raw <- data.frame(
    patient_id = sprintf("P%02d", 1:10),
    matrix(sample(0:4, 20 * 10, replace = TRUE), nrow = 10, ncol = 20),
    stringsAsFactors = FALSE
  )
  expect_true(suppressMessages(check_pcl5_data(raw, id_col = "patient_id")))

  # already-renamed data with extra workflow columns is checked by name
  renamed <- rename_ptsd_columns(raw, id_col = "patient_id")
  renamed$total <- rowSums(renamed[, paste0("symptom_", 1:20)])
  expect_true(suppressMessages(check_pcl5_data(renamed)))
})

test_that("check_pcl5_data notes all-zero rows without failing", {
  clean <- data.frame(matrix(sample(1:4, 20 * 5, replace = TRUE),
                             nrow = 5, ncol = 20))
  clean[2, ] <- 0
  expect_message(res <- check_pcl5_data(clean), "all items = 0")
  expect_true(res)
})

test_that("check_pcl5_data errors on zero rows and non-data-frame input", {
  empty <- data.frame(matrix(numeric(0), nrow = 0, ncol = 20))
  expect_error(check_pcl5_data(empty), "at least one row")
  expect_error(check_pcl5_data("not a data frame"), "data frame")
})
