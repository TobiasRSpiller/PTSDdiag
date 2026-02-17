# --- Helper: create sample combinations ---
make_test_combos <- function() {
  list(
    c(1, 6, 8, 10, 15, 19),
    c(2, 7, 9, 11, 16, 20),
    c(3, 6, 10, 12, 17, 18)
  )
}

make_test_clusters <- function() {
  list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)
}

# ============================================================
# write_combinations() tests
# ============================================================

test_that("write_combinations creates a valid JSON file", {
  combos <- make_test_combos()
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  result <- write_combinations(combos, tmp, n_required = 4,
                               score_by = "false_cases",
                               description = "Test export")

  expect_true(file.exists(tmp))
  expect_equal(result, tmp)

  # Check JSON content is human-readable
  raw_text <- paste(readLines(tmp), collapse = "\n")
  expect_true(grepl("combinations", raw_text))
  expect_true(grepl("parameters", raw_text))
  expect_true(grepl("n_required", raw_text))
  expect_true(grepl("ptsddiag_version", raw_text))
  expect_true(grepl("Test export", raw_text))
})

test_that("write_combinations auto-detects optimization result objects", {
  combos <- make_test_combos()
  # Simulate the structure returned by optimize_combinations()
  fake_result <- list(
    best_symptoms = combos,
    diagnosis_comparison = data.frame(PTSD_orig = c(TRUE, FALSE)),
    summary = data.frame(metric = "test")
  )

  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  expect_message(
    write_combinations(fake_result, tmp, n_required = 4),
    "Combinations written to"
  )

  spec <- read_combinations(tmp)
  expect_equal(length(spec$combinations), 3)
  expect_equal(length(spec$combinations[[1]]), 6)
})

test_that("write_combinations stores clusters correctly", {
  combos <- make_test_combos()
  clusters <- make_test_clusters()
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  write_combinations(combos, tmp, n_required = 4, clusters = clusters)

  raw_text <- paste(readLines(tmp), collapse = "\n")
  expect_true(grepl('"B"', raw_text))
  expect_true(grepl('"C"', raw_text))
  expect_true(grepl('"D"', raw_text))
  expect_true(grepl('"E"', raw_text))
})

test_that("write_combinations infers n_symptoms from combinations", {
  combos <- make_test_combos()
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  write_combinations(combos, tmp, n_required = 4)

  spec <- read_combinations(tmp)
  expect_equal(spec$parameters$n_symptoms, 6)
})

test_that("write_combinations validates inputs", {
  tmp <- tempfile(fileext = ".json")

  # Invalid combinations: unequal lengths
  expect_error(
    write_combinations(list(c(1, 2, 3), c(1, 2)), tmp),
    "same length"
  )

  # Invalid n_required: too large
  expect_error(
    write_combinations(list(c(1, 2, 3)), tmp, n_required = 5),
    "n_required"
  )

  # Invalid file path
  expect_error(
    write_combinations(list(c(1, 2, 3)), 123, n_required = 2),
    "file"
  )

  # Invalid score_by
  expect_error(
    write_combinations(list(c(1, 2, 3)), tmp, n_required = 2,
                       score_by = "invalid"),
    "score_by"
  )

  # Invalid description
  expect_error(
    write_combinations(list(c(1, 2, 3)), tmp, n_required = 2,
                       description = 42),
    "description"
  )
})

# ============================================================
# read_combinations() tests
# ============================================================

test_that("read_combinations round-trips non-hierarchical combinations", {
  combos <- make_test_combos()
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  write_combinations(combos, tmp, n_required = 4,
                     score_by = "false_cases",
                     description = "Round-trip test")

  spec <- read_combinations(tmp)

  expect_type(spec, "list")
  expect_equal(length(spec$combinations), 3)

  # Check values match (compare as numeric since JSON may deserialize as double)
  for (i in seq_along(combos)) {
    expect_equal(spec$combinations[[i]], combos[[i]])
  }

  expect_equal(spec$n_required, 4)
  expect_null(spec$clusters)
  expect_equal(spec$parameters$n_symptoms, 6)
  expect_equal(spec$parameters$score_by, "false_cases")
  expect_equal(spec$description, "Round-trip test")
  expect_true(!is.na(spec$ptsddiag_version))
  expect_true(!is.na(spec$created_at))
})

test_that("read_combinations round-trips hierarchical combinations", {
  combos <- make_test_combos()
  clusters <- make_test_clusters()
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  write_combinations(combos, tmp, n_required = 4, clusters = clusters,
                     score_by = "false_cases")

  spec <- read_combinations(tmp)

  expect_type(spec$clusters, "list")
  expect_equal(names(spec$clusters), c("B", "C", "D", "E"))
  expect_equal(spec$clusters$B, 1:5)
  expect_equal(spec$clusters$C, 6:7)
  expect_equal(spec$clusters$D, 8:14)
  expect_equal(spec$clusters$E, 15:20)
})

test_that("read_combinations errors on nonexistent file", {
  expect_error(
    read_combinations("nonexistent_file_12345.json"),
    "File not found"
  )
})

test_that("read_combinations errors on malformed JSON", {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  # Missing required fields
  writeLines('{"foo": "bar"}', tmp)
  expect_error(
    read_combinations(tmp),
    "missing required fields"
  )
})

test_that("read_combinations errors on missing n_required", {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  # Has parameters but no n_required
  writeLines('{"combinations": [[1,2,3]], "parameters": {"n_symptoms": 3}}', tmp)
  expect_error(
    read_combinations(tmp),
    "n_required"
  )
})

test_that("read_combinations emits message on version mismatch", {
  combos <- make_test_combos()
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  write_combinations(combos, tmp, n_required = 4)

  # Manually edit the version in the file
  raw_text <- readLines(tmp)
  raw_text <- gsub(as.character(utils::packageVersion("PTSDdiag")),
                   "99.99.99", raw_text)
  writeLines(raw_text, tmp)

  expect_message(
    read_combinations(tmp),
    "99.99.99"
  )
})

test_that("read_combinations validates invalid combinations in file", {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  # Combinations with values out of range
  bad_json <- '{"combinations": [[1, 2, 99]], "parameters": {"n_required": 2}}'
  writeLines(bad_json, tmp)

  expect_error(
    read_combinations(tmp),
    "between 1 and"
  )
})

test_that("read_combinations validates file argument", {
  expect_error(
    read_combinations(123),
    "file"
  )

  expect_error(
    read_combinations(c("a.json", "b.json")),
    "file"
  )
})

# ============================================================
# End-to-end integration test
# ============================================================

test_that("write/read round-trip works with apply_symptom_combinations", {
  # Create test data
  set.seed(42)
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE), nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  combos <- list(
    c(1, 6, 8, 10, 15, 19),
    c(2, 7, 9, 11, 16, 20)
  )

  # Write
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))
  write_combinations(combos, tmp, n_required = 4)

  # Read
  spec <- read_combinations(tmp)

  # Apply to data — this should work without error
  comparison <- apply_symptom_combinations(
    test_data,
    combinations = spec$combinations,
    n_required = spec$n_required,
    clusters = spec$clusters
  )

  expect_true("PTSD_orig" %in% names(comparison))
  expect_equal(nrow(comparison), 50)
  # Should have PTSD_orig + 2 combination columns
  expect_equal(ncol(comparison), 3)
})

test_that("write/read round-trip works with hierarchical apply", {
  # Create test data
  set.seed(42)
  test_data <- data.frame(
    matrix(sample(0:4, 20 * 50, replace = TRUE), nrow = 50, ncol = 20)
  )
  colnames(test_data) <- paste0("symptom_", 1:20)

  combos <- list(
    c(1, 6, 8, 10, 15, 19),
    c(2, 7, 9, 11, 16, 20)
  )
  clusters <- make_test_clusters()

  # Write with clusters
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))
  write_combinations(combos, tmp, n_required = 4, clusters = clusters)

  # Read
  spec <- read_combinations(tmp)

  # Apply hierarchically
  comparison <- apply_symptom_combinations(
    test_data,
    combinations = spec$combinations,
    n_required = spec$n_required,
    clusters = spec$clusters
  )

  expect_true("PTSD_orig" %in% names(comparison))
  expect_equal(nrow(comparison), 50)
  expect_equal(ncol(comparison), 3)
})

test_that("write_combinations handles NULL score_by gracefully", {
  combos <- make_test_combos()
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  # Default: score_by = NULL
  write_combinations(combos, tmp, n_required = 4)

  spec <- read_combinations(tmp)
  expect_null(spec$parameters$score_by)
})

test_that("write_combinations handles empty description", {
  combos <- make_test_combos()
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))

  write_combinations(combos, tmp, n_required = 4)

  spec <- read_combinations(tmp)
  expect_equal(spec$description, "")
})
