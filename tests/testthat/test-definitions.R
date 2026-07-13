# Building the default-scenario comparison is the expensive part of this
# file, so each variant is built once and reused (all tests are read-only).
.comp_cache <- new.env(parent = emptyenv())
make_comp <- function(n = 200, seed = 7) {
  key <- paste(n, seed, sep = "_")
  if (is.null(.comp_cache[[key]])) {
    set.seed(seed)
    df <- as.data.frame(matrix(sample(0:4, 20 * n, replace = TRUE), nrow = n,
                               ncol = 20))
    names(df) <- paste0("symptom_", 1:20)
    .comp_cache[[key]] <- compare_optimizations(df, n_top = 8,
                                                show_progress = FALSE)
  }
  .comp_cache[[key]]
}

# ---------------------------------------------------------------------------
# extract_definitions()
# ---------------------------------------------------------------------------

test_that("extract_definitions returns one entry per optimize scenario with rules from config", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
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
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  comp <- make_comp()
  defs <- extract_definitions(comp, n = 50)  # more than n_top
  expect_true(all(vapply(defs, function(d) length(d$symptoms), integer(1)) == 8))

  expect_error(extract_definitions(comp, n = 0), "positive integer")
  expect_error(extract_definitions(list(), n = 5), "ptsdiag_comparison")
})

test_that("extract_definitions skips fixed scenarios", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
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
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  comp <- make_comp()
  defs <- extract_definitions(comp, n = 2)

  set.seed(21)
  newdata <- as.data.frame(matrix(sample(0:4, 20 * 150, replace = TRUE),
                                  nrow = 150, ncol = 20))
  names(newdata) <- paste0("symptom_", 1:20)

  tbl <- evaluate_definitions(newdata, defs, include_icd11 = TRUE)
  expect_true("Accuracy" %in% names(tbl))
  expect_true("Balanced Accuracy" %in% names(tbl))
  expect_true("Scenario" %in% names(tbl))
  # reference + 2 defs x 3 rules + ICD-11 = 1 + 6 + 1 = 8 rows
  expect_equal(nrow(tbl), 8)
  expect_true(any(tbl$Scenario == "ICD-11"))
  expect_true(any(tbl$Scenario == "PTSD_orig"))
})

test_that("evaluate_definitions can omit ICD-11", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
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
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
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

# ---------------------------------------------------------------------------
# Shared helpers for the as_definitions() / evaluate_definitions() tests
# ---------------------------------------------------------------------------

make_spec_file <- function(combos, n_required, clusters = NULL, label = NULL) {
  tmp <- tempfile(fileext = ".json")
  suppressMessages(write_combinations(combos, tmp, n_required = n_required,
                                      clusters = clusters, label = label))
  tmp
}

make_newdata <- function(n, seed) {
  set.seed(seed)
  df <- as.data.frame(matrix(sample(0:4, 20 * n, replace = TRUE),
                             nrow = n, ncol = 20))
  names(df) <- paste0("symptom_", 1:20)
  df
}

# Hand-built definitions (no optimizer search) so the evaluate_definitions()
# feature tests stay cheap enough to run on CRAN.
make_defs <- function() {
  list(
    "4/6 Non-hierarchical" = list(
      symptoms = list(c(1, 6, 8, 10, 15, 19), c(2, 7, 9, 11, 16, 20)),
      n_required = 4, hierarchical = FALSE
    ),
    "4/6 Hierarchical" = list(
      symptoms = list(c(1, 6, 8, 15, 17, 19), c(2, 7, 10, 14, 16, 20)),
      n_required = 4, hierarchical = TRUE
    )
  )
}

# ---------------------------------------------------------------------------
# as_definitions()
# ---------------------------------------------------------------------------

test_that("as_definitions derives rule labels from the specification", {
  f_nonhier <- make_spec_file(list(c(1, 6, 8, 10, 15, 19)), 4)
  on.exit(unlink(f_nonhier), add = TRUE)
  defs <- as_definitions(read_combinations(f_nonhier))
  expect_equal(names(defs), "4/6 Non-hierarchical")
  expect_false(defs[[1]]$hierarchical)
  expect_null(defs[[1]]$clusters)

  f_hier <- make_spec_file(list(c(1, 6, 8, 10, 15, 19)), 4,
                           clusters = list(B = 1:5, C = 6:7,
                                           D = 8:14, E = 15:20))
  on.exit(unlink(f_hier), add = TRUE)
  defs_h <- as_definitions(read_combinations(f_hier))
  expect_equal(names(defs_h), "4/6 Hierarchical")
  expect_true(defs_h[[1]]$hierarchical)
  expect_equal(defs_h[[1]]$clusters,
               list(B = 1:5, C = 6:7, D = 8:14, E = 15:20))
})

test_that("as_definitions label precedence: list name > stored label > derived", {
  f <- make_spec_file(list(c(1, 6, 8, 10, 15, 19)), 4, label = "My Rule")
  on.exit(unlink(f))
  spec <- read_combinations(f)
  expect_equal(names(as_definitions(spec)), "My Rule")
  expect_equal(names(as_definitions(list("Renamed" = spec))), "Renamed")
})

test_that("as_definitions aborts on duplicate labels", {
  f1 <- make_spec_file(list(c(1, 6, 8, 10, 15, 19)), 4)
  f2 <- make_spec_file(list(c(2, 7, 9, 11, 16, 20)), 4)
  on.exit(unlink(c(f1, f2)))
  specs <- lapply(c(f1, f2), read_combinations)
  expect_error(as_definitions(specs), "unique labels")
  # naming the elements resolves it
  named <- as_definitions(list("Rule A" = specs[[1]], "Rule B" = specs[[2]]))
  expect_equal(names(named), c("Rule A", "Rule B"))
})

test_that("as_definitions applies and caps n_top", {
  f <- make_spec_file(list(c(1, 6, 8, 10, 15, 19), c(2, 7, 9, 11, 16, 20),
                           c(3, 6, 10, 12, 17, 18)), 4)
  on.exit(unlink(f))
  spec <- read_combinations(f)
  expect_length(as_definitions(spec)[[1]]$symptoms, 3)
  expect_length(as_definitions(spec, n_top = 2)[[1]]$symptoms, 2)
  expect_length(as_definitions(spec, n_top = 99)[[1]]$symptoms, 3)
  expect_error(as_definitions(spec, n_top = 0), "positive integer")
})

test_that("as_definitions matches the hand-built definitions construction", {
  combos <- list(c(1, 6, 8, 10, 15, 19), c(2, 7, 9, 11, 16, 20),
                 c(3, 6, 10, 12, 17, 18))
  f <- make_spec_file(combos, 4)
  on.exit(unlink(f))
  spec <- read_combinations(f)

  # The construction every validation Rmd used to hand-roll
  k <- min(2, length(spec$combinations))
  manual <- list(symptoms     = spec$combinations[seq_len(k)],
                 n_required   = spec$n_required,
                 hierarchical = !is.null(spec$clusters))

  auto <- as_definitions(spec, n_top = 2)[[1]]
  expect_equal(auto$symptoms, manual$symptoms)
  expect_equal(auto$n_required, manual$n_required)
  expect_equal(auto$hierarchical, manual$hierarchical)
})

test_that("as_definitions rejects non-spec input", {
  expect_error(as_definitions(list(a = 1)), "combination specification")
  expect_error(as_definitions(42), "combination specification")
})

test_that("evaluate_definitions accepts specs directly (auto-coercion)", {
  f1 <- make_spec_file(list(c(1, 6, 8, 10, 15, 19)), 4)
  f2 <- make_spec_file(list(c(2, 7, 9, 11, 16, 20)), 3,
                       clusters = list(B = 1:5, C = 6:7, D = 8:14, E = 15:20))
  on.exit(unlink(c(f1, f2)))
  specs <- lapply(c(f1, f2), read_combinations)
  newdata <- make_newdata(120, 41)

  via_specs <- evaluate_definitions(newdata, specs, include_icd11 = FALSE)
  via_defs  <- evaluate_definitions(newdata, as_definitions(specs),
                                    include_icd11 = FALSE)
  expect_identical(via_specs, via_defs)

  # a single spec works too
  single <- evaluate_definitions(newdata, specs[[1]], include_icd11 = FALSE)
  expect_s3_class(single, "data.frame")
})

test_that("custom clusters stored in a spec are used in evaluation", {
  custom <- list(G1 = 1:10, G2 = 11:20)
  f <- make_spec_file(list(c(1, 2, 3, 4, 15, 16)), 2, clusters = custom)
  on.exit(unlink(f))
  spec <- read_combinations(f)
  newdata <- make_newdata(150, 42)

  with_custom <- evaluate_definitions(newdata, spec, include_icd11 = FALSE,
                                      tidy = TRUE)

  # Strip the stored structure -> falls back to the default B/C/D/E clusters,
  # under which this combination can never span all four clusters
  defs_default <- as_definitions(spec)
  defs_default[[1]]$clusters <- NULL
  with_default <- evaluate_definitions(newdata, defs_default,
                                       include_icd11 = FALSE, tidy = TRUE)

  expect_gt(with_custom$TP + with_custom$FP, 0)   # custom clusters: diagnosable
  expect_equal(with_default$TP + with_default$FP, 0)  # default: never spans B-E
})

# ---------------------------------------------------------------------------
# evaluate_definitions(): v0.3.5 regression pin
# ---------------------------------------------------------------------------

test_that("evaluate_definitions default output matches the v0.3.5 algorithm", {
  defs <- make_defs()
  newdata <- make_newdata(150, 51)

  # The pre-0.4.0 implementation, replicated verbatim
  clusters <- list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)
  comparison <- data.frame(
    PTSD_orig = create_ptsd_diagnosis_binarized(newdata)$PTSD_orig,
    check.names = FALSE
  )
  for (rule in names(defs)) {
    d  <- defs[[rule]]
    cl <- if (isTRUE(d$hierarchical)) clusters else NULL
    applied <- apply_symptom_combinations(newdata, d$symptoms,
                                          n_required = d$n_required,
                                          clusters = cl)
    combo_cols <- grep("^symptom_[0-9]+(_[0-9]+)+$", names(applied),
                       value = TRUE)
    for (cc in combo_cols) {
      label <- paste0(rule, " (", gsub("_", ", ", sub("^symptom_", "", cc)), ")")
      comparison[[label]] <- applied[[cc]]
    }
  }
  comparison[["ICD-11"]] <- create_icd11_diagnosis(newdata)$PTSD_icd11
  expected <- create_readable_summary(summarize_ptsd_changes(comparison))

  expect_identical(evaluate_definitions(newdata, defs, include_icd11 = TRUE),
                   expected)
})

# ---------------------------------------------------------------------------
# evaluate_definitions(): external reference standard
# ---------------------------------------------------------------------------

test_that("evaluate_definitions scores against an external reference", {
  defs <- make_defs()
  newdata <- make_newdata(160, 52)
  set.seed(53)
  ref <- sample(c(TRUE, FALSE), 160, replace = TRUE)
  ref[c(3, 10, 50)] <- NA

  # column name and vector give identical results; NA rows are reported
  withcol <- newdata
  withcol$my_ref <- ref
  expect_message(
    via_col <- evaluate_definitions(withcol, defs, reference = "my_ref"),
    "missing for 3 of 160"
  )
  via_vec <- suppressMessages(
    evaluate_definitions(newdata, defs, reference = ref)
  )
  expect_identical(via_col, via_vec)

  # equals the manual construction on the manually subset data (the
  # evaluate_definitions_against() helper the paper Rmds used to hand-roll)
  keep <- !is.na(ref)
  sub  <- newdata[keep, , drop = FALSE]
  comparison <- data.frame(PTSD_orig = ref[keep], check.names = FALSE)
  for (rule in names(defs)) {
    d <- defs[[rule]]
    cl <- if (isTRUE(d$hierarchical)) {
      list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)
    } else {
      NULL
    }
    applied <- apply_symptom_combinations(sub, d$symptoms,
                                          n_required = d$n_required,
                                          clusters = cl)
    combo_cols <- grep("^symptom_[0-9]+(_[0-9]+)+$", names(applied),
                       value = TRUE)
    for (cc in combo_cols) {
      label <- paste0(rule, " (", gsub("_", ", ", sub("^symptom_", "", cc)), ")")
      comparison[[label]] <- applied[[cc]]
    }
  }
  comparison[["Full 20-item PCL-5"]] <-
    create_ptsd_diagnosis_binarized(sub)$PTSD_orig
  comparison[["ICD-11"]] <- create_icd11_diagnosis(sub)$PTSD_icd11
  expected <- create_readable_summary(summarize_ptsd_changes(comparison))
  expect_identical(via_vec, expected)

  # tidy counts sum to the number of rows with a reference value
  tidy <- suppressMessages(
    evaluate_definitions(newdata, defs, reference = ref, tidy = TRUE)
  )
  expect_true(all(tidy$TP + tidy$FN + tidy$FP + tidy$TN == sum(keep)))
  expect_true("Full 20-item PCL-5" %in% tidy$Approach)
  expect_true(is.na(tidy$Combination[tidy$Approach == "Full 20-item PCL-5"]))
})

test_that("evaluate_definitions validates the reference argument", {
  defs <- make_defs()
  newdata <- make_newdata(50, 54)

  # 0/1 numeric coerces to logical
  set.seed(55)
  ref01 <- sample(c(0, 1), 50, replace = TRUE)
  expect_identical(
    evaluate_definitions(newdata, defs, reference = ref01),
    evaluate_definitions(newdata, defs, reference = as.logical(ref01))
  )

  expect_error(evaluate_definitions(newdata, defs, reference = rep(2, 50)),
               "logical")
  expect_error(evaluate_definitions(newdata, defs,
                                    reference = c(TRUE, FALSE)),
               "one value per row")
  expect_error(evaluate_definitions(newdata, defs, reference = "no_such"),
               "not found")
  expect_error(evaluate_definitions(newdata, defs,
                                    reference = rep(NA, 50)),
               "only missing values")
  expect_error(evaluate_definitions(newdata, defs, reference = "symptom_1"),
               "item columns")
})

test_that("include_full_pcl5 defaults track the reference and can be overridden", {
  defs <- make_defs()
  newdata <- make_newdata(80, 56)
  set.seed(57)
  ref <- sample(c(TRUE, FALSE), 80, replace = TRUE)

  # internal reference: no ceiling row by default, present on request
  t0 <- evaluate_definitions(newdata, defs, tidy = TRUE)
  expect_false("Full 20-item PCL-5" %in% t0$Approach)
  t1 <- evaluate_definitions(newdata, defs, tidy = TRUE,
                             include_full_pcl5 = TRUE)
  expect_true("Full 20-item PCL-5" %in% t1$Approach)

  # external reference: present by default, absent on request
  t2 <- evaluate_definitions(newdata, defs, reference = ref, tidy = TRUE)
  expect_true("Full 20-item PCL-5" %in% t2$Approach)
  t3 <- evaluate_definitions(newdata, defs, reference = ref, tidy = TRUE,
                             include_full_pcl5 = FALSE)
  expect_false("Full 20-item PCL-5" %in% t3$Approach)
})

# ---------------------------------------------------------------------------
# evaluate_definitions(): tidy output
# ---------------------------------------------------------------------------

test_that("tidy output matches the summarize_top_combinations layout", {
  skip_on_cran()   # search-heavy; runs on CI (full suite), not on CRAN
  comp <- make_comp()
  defs <- extract_definitions(comp, n = 2)
  newdata <- make_newdata(150, 58)

  tidy <- evaluate_definitions(newdata, defs, tidy = TRUE)
  expect_equal(names(tidy), names(summarize_top_combinations(comp)))

  # Rank restarts at 1 within each approach
  for (a in unique(tidy$Approach)) {
    expect_equal(tidy$Rank[tidy$Approach == a],
                 seq_len(sum(tidy$Approach == a)))
  }

  # ICD-11 carries its fixed symptom set; no reference self-row is present
  expect_equal(tidy$Combination[tidy$Approach == "ICD-11"],
               "2, 3, 6, 7, 17, 18")
  expect_false("PTSD_orig" %in% tidy$Approach)
})

test_that("tidy output agrees numerically with the formatted table", {
  defs <- make_defs()
  newdata <- make_newdata(150, 59)

  tidy <- evaluate_definitions(newdata, defs, tidy = TRUE)
  fmt  <- evaluate_definitions(newdata, defs, tidy = FALSE)

  lbl <- paste0(tidy$Approach, " (", tidy$Combination, ")")
  lbl[tidy$Approach == "ICD-11"] <- "ICD-11"
  m <- match(lbl, fmt$Scenario)
  expect_false(anyNA(m))
  expect_equal(tidy$TP, fmt$`True Positive`[m])
  expect_equal(tidy$FN, fmt$`Newly Non-Diagnosed`[m])
  expect_equal(tidy$FP, fmt$`Newly Diagnosed`[m])
  expect_equal(tidy$TN, fmt$`True Negative`[m])
  expect_equal(round(tidy$Sensitivity, 4), fmt$Sensitivity[m])
  expect_equal(round(tidy$`Balanced Accuracy`, 4), fmt$`Balanced Accuracy`[m])
})

test_that("as_percent scales the tidy metrics and requires tidy = TRUE", {
  defs <- make_defs()
  newdata <- make_newdata(100, 60)

  tidy <- evaluate_definitions(newdata, defs, tidy = TRUE)
  pct  <- evaluate_definitions(newdata, defs, tidy = TRUE, as_percent = TRUE)
  expect_equal(pct$Sensitivity, tidy$Sensitivity * 100)
  expect_equal(pct$`Balanced Accuracy`, tidy$`Balanced Accuracy` * 100)
  expect_equal(pct$TP, tidy$TP)  # counts are never scaled

  expect_error(evaluate_definitions(newdata, defs, as_percent = TRUE),
               "tidy = TRUE")
})

test_that("tidy output has the documented columns (CRAN-cheap)", {
  # Literal-name twin of the summarize_top_combinations cross-consistency
  # test above (which needs a real comparison object and is CI-only).
  defs <- make_defs()
  newdata <- make_newdata(80, 61)

  tidy <- evaluate_definitions(newdata, defs, tidy = TRUE)
  expect_equal(names(tidy),
               c("Approach", "Rank", "Combination", "TP", "FN", "FP", "TN",
                 "Sensitivity", "Specificity", "PPV", "NPV", "Accuracy",
                 "Balanced Accuracy"))
  for (a in unique(tidy$Approach)) {
    expect_equal(tidy$Rank[tidy$Approach == a],
                 seq_len(sum(tidy$Approach == a)))
  }
  expect_equal(tidy$Combination[tidy$Approach == "ICD-11"],
               "2, 3, 6, 7, 17, 18")
})
