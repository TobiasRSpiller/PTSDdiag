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
  expect_error(rename_caps5_columns(bad), "20 columns")
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
