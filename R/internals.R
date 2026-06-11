# Internal helper functions for PTSDdiag
# These are NOT exported. All prefixed with "." and tagged @noRd.

#' Validate PCL-5 / CAPS-5 input data
#'
#' @param data Data frame to validate.
#' @param strict_cols If TRUE (default), require exactly 20 columns.
#'   If FALSE, only require symptom_1:symptom_20 to be present (allows
#'   extra columns like "total").
#' @param warn_total If TRUE (default), warn when a "total" column is present.
#' @param instrument Label for error messages ("PCL-5" or "CAPS-5").
#' @noRd
.validate_pcl5_data <- function(data, strict_cols = TRUE, warn_total = TRUE,
                                instrument = "PCL-5") {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame, not {.cls {class(data)}}.")
  }

  expected_cols <- paste0("symptom_", 1:20)

  if (strict_cols && ncol(data) != 20) {
    cli::cli_abort(c(
      "{.arg data} must contain exactly 20 columns (one for each {instrument} item).",
      "x" = "Got {ncol(data)} column{?s}."
    ))
  }

  if (!all(expected_cols %in% colnames(data))) {
    cli::cli_abort("Data must contain columns named {.val symptom_1} through {.val symptom_20}.")
  }

  if (warn_total && "total" %in% colnames(data)) {
    cli::cli_warn("{.val total} column detected. This function should only be used with raw symptom scores.")
  }

  if (!all(vapply(data[expected_cols], is.numeric, logical(1)))) {
    cli::cli_abort("All symptom columns must contain numeric values.")
  }

  if (any(is.na(data[expected_cols]))) {
    cli::cli_abort("Data contains missing values ({.val NA}).")
  }

  invalid_values <- !all(vapply(data[expected_cols], function(x)
    all(x >= 0 & x <= 4 & x == floor(x)), logical(1)))
  if (invalid_values) {
    cli::cli_abort("All symptom values must be integers between 0 and 4.")
  }

  if (nrow(data) < 1) {
    cli::cli_abort("{.arg data} must contain at least one row.")
  }

  invisible(TRUE)
}

#' Validate user-supplied id_col argument
#'
#' Ensures the id_col argument refers to existing columns and does not collide
#' with reserved names used elsewhere in the workflow.
#'
#' @param data Data frame the id columns must live in.
#' @param id_col Character vector of column names (>=1), or NULL.
#' @noRd
.validate_id_col <- function(data, id_col) {
  if (is.null(id_col)) return(invisible(TRUE))

  if (!is.character(id_col) || length(id_col) < 1 || any(is.na(id_col)) ||
      any(!nzchar(id_col))) {
    cli::cli_abort(
      "{.arg id_col} must be a non-empty character vector of column names."
    )
  }

  if (anyDuplicated(id_col)) {
    cli::cli_abort("{.arg id_col} must not contain duplicate column names.")
  }

  missing <- setdiff(id_col, names(data))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "{.arg id_col} references {cli::qty(length(missing))} column{?s} not present in {.arg data}.",
      "x" = "Missing: {.val {missing}}."
    ))
  }

  reserved_static <- c(paste0("symptom_", 1:20), "total",
                       "PTSD_orig", "PTSD_icd11", "PTSD_caps5", "PTSD_pcl5",
                       ".strata")
  is_reserved_combo <- grepl("^symptom_[0-9]+(_[0-9]+)+$", id_col)
  bad <- id_col[id_col %in% reserved_static | is_reserved_combo]
  if (length(bad) > 0) {
    cli::cli_abort(c(
      "{.arg id_col} contains {cli::qty(length(bad))} reserved name{?s} used by the workflow.",
      "x" = "Reserved: {.val {bad}}.",
      "i" = "Rename the {cli::qty(length(bad))}column{?s} before calling this function."
    ))
  }

  invisible(TRUE)
}

#' Detect carry-through (ID-like) columns in a workflow data frame
#'
#' Returns the names of columns that are neither part of the canonical
#' symptom_1..symptom_20 set, nor any other reserved name produced by the
#' workflow (total, PTSD_orig, PTSD_*, .strata, combination-output columns).
#'
#' @param data A data frame.
#' @return Character vector of carry-through column names (possibly empty).
#' @noRd
.detect_carry_cols <- function(data) {
  reserved_static <- c(paste0("symptom_", 1:20), "total",
                       "PTSD_orig", "PTSD_icd11", "PTSD_caps5", "PTSD_pcl5",
                       ".strata")
  nm <- names(data)
  is_combo <- grepl("^symptom_[0-9]+(_[0-9]+)+$", nm)
  nm[!(nm %in% reserved_static | is_combo)]
}

#' Extract carry-through (ID-like) columns from a data frame
#'
#' @param data A data frame.
#' @return A data frame of the carry-through columns (zero columns if none).
#'   Row order matches \code{data}.
#' @noRd
.extract_carry_df <- function(data) {
  cols <- .detect_carry_cols(data)
  data[, cols, drop = FALSE]
}

#' Prepend carry-through columns to a row-aligned result data frame
#'
#' @param result_df A data frame whose rows are aligned with the rows the
#'   carry-through columns were extracted from.
#' @param carry_df A data frame of carry-through columns (zero columns ok).
#' @return \code{result_df} with carry-through columns prepended.
#' @noRd
.attach_carry_cols <- function(result_df, carry_df) {
  if (ncol(carry_df) == 0) return(result_df)
  if (nrow(carry_df) != nrow(result_df)) {
    cli::cli_abort(c(
      "Internal error: carry-through column row count does not match result.",
      "i" = "Got {nrow(carry_df)} ID row{?s} and {nrow(result_df)} result row{?s}."
    ))
  }
  cbind(carry_df, result_df, stringsAsFactors = FALSE)
}

#' Validate score_by parameter
#'
#' Accepts the epidemiological argument names introduced in v0.3.1
#' (\code{"accuracy"} and \code{"sensitivity"}) plus \code{"balanced_accuracy"}
#' (v0.3.5). When users pass the old (v <= 0.3.0) values \code{"false_cases"}
#' or \code{"newly_nondiagnosed"}, a migration-hint error is raised.
#' @noRd
.validate_score_by <- function(score_by) {
  valid_scoring <- c("accuracy", "balanced_accuracy", "sensitivity")
  legacy_map    <- c(false_cases = "accuracy",
                     newly_nondiagnosed = "sensitivity")

  if (length(score_by) != 1 || is.na(score_by) || !is.character(score_by)) {
    cli::cli_abort(c(
      "{.arg score_by} must be one of {.or {.val {valid_scoring}}}.",
      "x" = "Got {.cls {class(score_by)}}."
    ))
  }

  if (score_by %in% names(legacy_map)) {
    cli::cli_abort(c(
      "{.arg score_by} must be one of {.or {.val {valid_scoring}}}.",
      "x" = "Got {.val {score_by}}.",
      "i" = "In v0.3.1 these values were renamed for clarity. \\
            Use {.val {legacy_map[[score_by]]}} instead of {.val {score_by}}."
    ))
  }

  if (!score_by %in% valid_scoring) {
    cli::cli_abort(c(
      "{.arg score_by} must be one of {.or {.val {valid_scoring}}}.",
      "x" = "Got {.val {score_by}}."
    ))
  }
  invisible(TRUE)
}

#' Validate n_symptoms parameter
#' @noRd
.validate_n_symptoms <- function(n_symptoms, n_total = 20) {
  if (!is.numeric(n_symptoms) || length(n_symptoms) != 1 ||
      n_symptoms != floor(n_symptoms) || n_symptoms < 1 || n_symptoms > n_total) {
    cli::cli_abort("{.arg n_symptoms} must be a single integer between 1 and {n_total}.")
  }
  invisible(TRUE)
}

#' Validate n_required parameter
#' @noRd
.validate_n_required <- function(n_required, n_symptoms) {
  if (!is.numeric(n_required) || length(n_required) != 1 ||
      n_required != floor(n_required) || n_required < 1 || n_required > n_symptoms) {
    cli::cli_abort("{.arg n_required} must be a single integer between 1 and {.arg n_symptoms} ({n_symptoms}).")
  }
  invisible(TRUE)
}

#' Validate n_top parameter
#' @noRd
.validate_n_top <- function(n_top) {
  if (!is.numeric(n_top) || length(n_top) != 1 ||
      n_top != floor(n_top) || n_top < 1) {
    cli::cli_abort("{.arg n_top} must be a single positive integer.")
  }
  invisible(TRUE)
}

#' Validate clusters parameter
#' @noRd
.validate_clusters <- function(clusters, n_total = 20) {
  if (!is.list(clusters) || length(clusters) < 1) {
    cli::cli_abort("{.arg clusters} must be a non-empty named list of integer vectors.")
  }
  if (is.null(names(clusters)) || any(names(clusters) == "")) {
    cli::cli_abort(c(
      "{.arg clusters} must be a named list.",
      "i" = "Example: {.code list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)}"
    ))
  }
  all_items <- unlist(clusters)
  if (!is.numeric(all_items) || any(all_items != floor(all_items))) {
    cli::cli_abort("All cluster elements must be integers.")
  }
  if (any(all_items < 1) || any(all_items > n_total)) {
    cli::cli_abort("All cluster elements must be between 1 and {n_total}.")
  }
  if (length(all_items) != length(unique(all_items))) {
    cli::cli_abort("Cluster elements must not overlap (each item can belong to only one cluster).")
  }
  invisible(TRUE)
}

#' Validate combinations input
#' @noRd
.validate_combinations_input <- function(combinations, n_total = 20) {
  if (!is.list(combinations) || length(combinations) < 1) {
    cli::cli_abort("{.arg combinations} must be a non-empty list of integer vectors.")
  }
  lengths_vec <- lengths(combinations)
  if (length(unique(lengths_vec)) != 1) {
    cli::cli_abort("All combinations must have the same length.")
  }
  for (i in seq_along(combinations)) {
    combo <- combinations[[i]]
    if (!is.numeric(combo) || any(combo != floor(combo))) {
      cli::cli_abort("All combination elements must be integers (problem in combination {i}).")
    }
    if (any(combo < 1) || any(combo > n_total)) {
      cli::cli_abort("All combination elements must be between 1 and {n_total} (problem in combination {i}).")
    }
    if (length(combo) != length(unique(combo))) {
      cli::cli_abort("Combination elements must be unique (duplicate found in combination {i}).")
    }
  }
  invisible(TRUE)
}

#' Validate imported JSON structure for combinations file
#' @noRd
.validate_json_structure <- function(x) {
  required_keys <- c("combinations", "parameters")
  missing <- setdiff(required_keys, names(x))
  if (length(missing) > 0) {
    cli::cli_abort("Invalid combinations file: missing required field{?s}: {.val {missing}}.")
  }
  if (!is.list(x$parameters) || is.null(x$parameters$n_required)) {
    cli::cli_abort("Invalid combinations file: {.field parameters} must contain {.field n_required}.")
  }
  invisible(TRUE)
}

#' Get default PCL-5 cluster definitions
#' @noRd
.get_default_clusters <- function() {
  list(
    B = 1:5,
    C = 6:7,
    D = 8:14,
    E = 15:20
  )
}

#' Diagnose based on a single symptom combination
#'
#' Applies a symptom combination to binarized data and returns a logical
#' diagnosis vector. For non-hierarchical mode (clusters = NULL), diagnosis
#' requires rowSums >= n_required. For hierarchical mode, additionally checks
#' that present symptoms span all clusters.
#'
#' @param binarized_data Matrix or data.frame of binarized (0/1) symptom data.
#'   Column names should be "symptom_1" through "symptom_20" or the data should
#'   be indexed by column position matching the symptom indices.
#' @param symptoms Integer vector of symptom indices in the combination.
#' @param n_required Integer. Minimum number of symptoms that must be present.
#' @param clusters NULL for non-hierarchical, or a named list of integer vectors.
#' @return Logical vector of length nrow(binarized_data).
#' @noRd
.diagnose_combination <- function(binarized_data, symptoms, n_required, clusters = NULL) {
  # Use column names for data.frame, indices for matrix
  if (is.data.frame(binarized_data)) {
    subset_data <- binarized_data[, paste0("symptom_", symptoms), drop = FALSE]
    subset_matrix <- as.matrix(subset_data)
  } else {
    # Assume matrix with columns corresponding to symptom_1..symptom_20
    subset_matrix <- binarized_data[, symptoms, drop = FALSE]
  }

  symptom_counts <- rowSums(subset_matrix)

  if (is.null(clusters)) {
    # Non-hierarchical: simple threshold
    return(symptom_counts >= n_required)
  }

  # Hierarchical: threshold + cluster representation check
  n_rows <- nrow(subset_matrix)
  result <- logical(n_rows)
  sufficient_rows <- which(symptom_counts >= n_required)

  if (length(sufficient_rows) > 0) {
    # Build cluster lookup
    cluster_lookup <- integer(max(unlist(clusters)))
    for (i in seq_along(clusters)) {
      cluster_lookup[clusters[[i]]] <- i
    }
    n_clusters <- length(clusters)

    for (row_idx in sufficient_rows) {
      present_symptoms <- symptoms[subset_matrix[row_idx, ] == 1]
      if (length(present_symptoms) >= n_required) {
        # Check that present symptoms span all clusters
        clusters_represented <- length(unique(cluster_lookup[present_symptoms]))
        result[row_idx] <- (clusters_represented == n_clusters)
      }
    }
  }

  return(result)
}

#' Find top N combinations by diagnostic accuracy
#'
#' Generalized version of the top-3 tracker. Uses insertion sort on a
#' length-n_top list.
#'
#' @param combinations List of integer vectors (symptom index combinations).
#' @param binarized_data Binarized symptom data (matrix or data.frame).
#' @param baseline_results Logical vector of baseline DSM-5 diagnoses.
#' @param score_by Character: "accuracy" (minimise FP + FN, equivalent to
#'   pre-0.3.1 "false_cases"), "balanced_accuracy" (minimise FN/P + FP/N,
#'   i.e. maximise the mean of sensitivity and specificity), or "sensitivity"
#'   (minimise FN, equivalent to pre-0.3.1 "newly_nondiagnosed").
#' @param n_top Integer: how many top combinations to track.
#' @param diagnose_fn Function(binarized_data, symptoms) -> logical vector.
#' @return Named list with $top (list of n_top elements, each with
#'   $combination, $score, $diagnoses) and $n_tied (integer count of
#'   combinations that scored identically to the best).
#' @noRd
.find_top_n <- function(combinations, binarized_data, baseline_results,
                        score_by, n_top, diagnose_fn, show_progress = TRUE) {
  top <- replicate(n_top,
    list(combination = NULL, score = -Inf, diagnoses = NULL),
    simplify = FALSE
  )
  n_tied_with_best <- 0L

  n_pos <- sum(baseline_results)
  n_neg <- sum(!baseline_results)
  if (score_by == "balanced_accuracy" && (n_pos == 0L || n_neg == 0L)) {
    single_class <- if (n_pos == 0L) "non-diagnosed" else "diagnosed"
    cli::cli_abort(c(
      "{.code score_by = \"balanced_accuracy\"} requires both diagnosed and non-diagnosed cases under the reference criterion.",
      "x" = "All cases in the data are {single_class}, so sensitivity or specificity is undefined.",
      "i" = "Use {.code score_by = \"accuracy\"} or {.code score_by = \"sensitivity\"} instead."
    ))
  }

  if (show_progress) {
    cli::cli_progress_bar("Evaluating combinations", total = length(combinations))
  }

  for (combination in combinations) {
    current_diagnoses <- diagnose_fn(binarized_data, combination)

    newly_diagnosed <- sum(!baseline_results & current_diagnoses)
    newly_nondiagnosed <- sum(baseline_results & !current_diagnoses)

    score <- if (score_by == "accuracy") {
      -(newly_diagnosed + newly_nondiagnosed)
    } else if (score_by == "balanced_accuracy") {
      # Maximising balanced accuracy == minimising FN/P + FP/N
      -(newly_nondiagnosed / n_pos + newly_diagnosed / n_neg)
    } else {
      # "sensitivity"
      -newly_nondiagnosed
    }

    # Track ties with the best score (once we have a real best)
    if (!is.null(top[[1]]$combination) && score == top[[1]]$score) {
      n_tied_with_best <- n_tied_with_best + 1L
    }

    # Find insertion position (strict > means first-encountered wins ties)
    for (pos in seq_len(n_top)) {
      if (score > top[[pos]]$score) {
        if (pos == 1L) n_tied_with_best <- 0L
        # Shift everything from pos onward down by one
        if (n_top > pos) {
          for (j in n_top:(pos + 1)) {
            top[[j]] <- top[[j - 1]]
          }
        }
        top[[pos]] <- list(
          combination = combination,
          score = score,
          diagnoses = current_diagnoses
        )
        break
      }
    }

    if (show_progress) cli::cli_progress_update()
  }

  if (show_progress) cli::cli_progress_done()

  return(list(top = top, n_tied = n_tied_with_best))
}

#' Build comparison dataframe from top combinations
#'
#' @param baseline_results Logical vector of baseline diagnoses (PTSD_orig).
#' @param top_combinations List from .find_top_n().
#' @param n_rows Integer: number of rows in the data.
#' @return Data.frame with PTSD_orig and one column per combination.
#' @noRd
.build_comparison_df <- function(baseline_results, top_combinations, n_rows) {
  # Filter out NULL combinations (in case n_top > actual combinations found)
  valid <- vapply(top_combinations, function(x) !is.null(x$combination), logical(1))
  top_combinations <- top_combinations[valid]
  n_valid <- length(top_combinations)

  if (n_valid == 0) {
    cli::cli_abort("No valid combinations found.")
  }

  comparison_df <- data.frame(
    PTSD_orig = baseline_results
  )

  for (i in seq_len(n_valid)) {
    col_name <- paste0("symptom_", paste(top_combinations[[i]]$combination, collapse = "_"))
    comparison_df[[col_name]] <- top_combinations[[i]]$diagnoses
  }

  return(comparison_df)
}

#' Wrap summary with optional DT
#'
#' @param comparison_df Data.frame with PTSD_orig + diagnosis columns.
#' @param DT Logical. If TRUE, return a DT datatable widget. If FALSE
#'   (default), return a plain data.frame.
#' @return Formatted summary (DT datatable if DT = TRUE, otherwise data.frame).
#'   Includes combination_id and rank columns.
#' @noRd
.wrap_summary <- function(comparison_df, DT = FALSE) {
  summary_table <- create_readable_summary(summarize_ptsd_changes(comparison_df))

  # Add combination_id: strip "symptom_" prefix; NA for PTSD_orig
  summary_table$combination_id <- vapply(summary_table$Scenario, function(s) {
    if (s == "PTSD_orig") return(NA_character_)
    sub("^symptom_", "", s)
  }, character(1), USE.NAMES = FALSE)

  # Add rank: sequential for non-PTSD_orig rows (position = rank)
  non_orig <- summary_table$Scenario != "PTSD_orig"
  summary_table$rank <- NA_integer_
  summary_table$rank[non_orig] <- seq_len(sum(non_orig))

  # Reorder columns: Scenario, combination_id, rank, then the rest
  other_cols <- setdiff(names(summary_table), c("Scenario", "combination_id", "rank"))
  summary_table <- summary_table[, c("Scenario", "combination_id", "rank", other_cols)]

  if (isTRUE(DT)) {
    if (!requireNamespace("DT", quietly = TRUE)) {
      cli::cli_abort("Package {.pkg DT} is required when {.code DT = TRUE}. Install it with {.run install.packages(\"DT\")}.")
    }
    summary_table <- DT::datatable(summary_table, options = list(scrollX = TRUE))
  }
  return(summary_table)
}

#' Run a single cross-validation fold
#'
#' @param i Integer fold index.
#' @param cv_splits Object from rsample::vfold_cv().
#' @param n_symptoms Integer.
#' @param n_required Integer.
#' @param n_top Integer.
#' @param score_by Character.
#' @param default_clusters Named list of cluster definitions.
#' @return List with $without and $with comparison data frames.
#' @noRd
.run_cv_fold <- function(i, cv_splits, n_symptoms, n_required, n_top,
                         score_by, default_clusters) {
  split_obj <- cv_splits$splits[[i]]
  train_data <- rsample::analysis(split_obj)
  test_data <- rsample::assessment(split_obj)

  # Drop the stratification column added by cross_validation()
  train_data$.strata <- NULL
  test_data$.strata <- NULL

  # Model without cluster representation
  train_results_without <- optimize_combinations(
    train_data, n_symptoms = n_symptoms, n_required = n_required,
    n_top = n_top, score_by = score_by, show_progress = FALSE
  )
  top_combos_without <- train_results_without$best_symptoms
  result_without <- apply_symptom_combinations(
    test_data, top_combos_without, n_required = n_required, clusters = NULL
  )

  # Model with cluster representation
  train_results_with <- optimize_combinations_clusters(
    train_data, n_symptoms = n_symptoms, n_required = n_required,
    n_top = n_top, score_by = score_by, clusters = default_clusters,
    show_progress = FALSE
  )
  top_combos_with <- train_results_with$best_symptoms
  result_with <- apply_symptom_combinations(
    test_data, top_combos_with, n_required = n_required,
    clusters = default_clusters
  )

  list(without = result_without, with = result_with)
}


# ---------------------------------------------------------------------------
# Multi-scenario comparison helpers
# ---------------------------------------------------------------------------

#' Default scenarios for compare_optimizations()
#'
#' Mirrors the three optimization approaches compared in the PTSDdiag preprint
#' (4/6 hierarchical, 4/6 non-hierarchical, 3/6 non-hierarchical).
#' @noRd
.default_scenarios <- function() {
  list(
    "4/6 Hierarchical"     = list(type = "optimize", n_symptoms = 6,
                                  n_required = 4, hierarchical = TRUE),
    "4/6 Non-hierarchical" = list(type = "optimize", n_symptoms = 6,
                                  n_required = 4, hierarchical = FALSE),
    "3/6 Non-hierarchical" = list(type = "optimize", n_symptoms = 6,
                                  n_required = 3, hierarchical = FALSE)
  )
}

#' Known fixed criteria for compare_optimizations()
#'
#' Returns a named list mapping criterion identifiers to their fixed symptom
#' index vectors and a producer function returning a logical vector of
#' diagnoses for the supplied data frame.
#' @noRd
.fixed_criterion_registry <- function() {
  list(
    icd11 = list(
      label    = "ICD-11",
      column   = "PTSD_icd11",
      symptoms = c(1, 2, 3, 6, 7, 17, 18),
      producer = function(data) create_icd11_diagnosis(data)$PTSD_icd11
    ),
    caps5 = list(
      label    = "CAPS-5",
      column   = "PTSD_caps5",
      symptoms = 1:20,
      producer = function(data) create_caps5_diagnosis(data)$PTSD_caps5
    )
  )
}

#' Validate a definitions list passed to evaluate_definitions()
#'
#' @param definitions A named list; each element must have `symptoms` (a list
#'   of integer vectors), `n_required`, and `hierarchical`.
#' @param n_total Number of symptoms (default 20), for index range checks.
#' @noRd
.validate_definitions <- function(definitions, n_rows = NULL, n_total = 20) {
  if (!is.list(definitions) || length(definitions) < 1) {
    cli::cli_abort("{.arg definitions} must be a non-empty named list.")
  }
  if (is.null(names(definitions)) || any(!nzchar(names(definitions)))) {
    cli::cli_abort("Every entry in {.arg definitions} must be named.")
  }
  for (label in names(definitions)) {
    d <- definitions[[label]]
    if (!is.list(d) || is.null(d$symptoms) || is.null(d$n_required) ||
        is.null(d$hierarchical)) {
      cli::cli_abort(c(
        "Definition {.val {label}} must contain {.field symptoms}, \\
        {.field n_required}, and {.field hierarchical}.",
        "i" = "Build it with {.fn extract_definitions}."
      ))
    }
    if (!is.list(d$symptoms) || length(d$symptoms) < 1) {
      cli::cli_abort("Definition {.val {label}}: {.field symptoms} must be a non-empty list of integer vectors.")
    }
    .validate_combinations_input(d$symptoms, n_total = n_total)
    .validate_n_required(d$n_required, length(d$symptoms[[1]]))
    if (!is.logical(d$hierarchical) || length(d$hierarchical) != 1) {
      cli::cli_abort("Definition {.val {label}}: {.field hierarchical} must be a single logical.")
    }
  }
  invisible(TRUE)
}

#' Validate the scenarios list passed to compare_optimizations()
#'
#' Each entry must be a list with a known \code{type} (\code{"optimize"} or
#' \code{"fixed"}). \code{"optimize"} entries are checked via the existing
#' parameter validators. \code{"fixed"} entries must carry \code{criterion}.
#'
#' @param scenarios A named list of scenario configurations.
#' @param n_rows Number of rows in the input data (used to validate
#'   user-supplied diagnosis vectors).
#' @noRd
.validate_scenarios <- function(scenarios, n_rows) {
  if (!is.list(scenarios) || length(scenarios) < 1) {
    cli::cli_abort(c(
      "{.arg scenarios} must be a non-empty named list.",
      "i" = "Example: {.code list(\"4/6 Hier\" = list(n_symptoms = 6, n_required = 4, hierarchical = TRUE))}."
    ))
  }
  if (is.null(names(scenarios)) || any(!nzchar(names(scenarios)))) {
    cli::cli_abort("Every scenario in {.arg scenarios} must be named.")
  }
  if (anyDuplicated(names(scenarios))) {
    dups <- unique(names(scenarios)[duplicated(names(scenarios))])
    cli::cli_abort("Duplicate scenario name{?s}: {.val {dups}}.")
  }

  registry <- .fixed_criterion_registry()

  for (label in names(scenarios)) {
    sc <- scenarios[[label]]
    if (!is.list(sc)) {
      cli::cli_abort("Scenario {.val {label}} must be a list.")
    }
    type <- if (is.null(sc$type)) "optimize" else sc$type
    if (!type %in% c("optimize", "fixed")) {
      cli::cli_abort(c(
        "Scenario {.val {label}} has unknown {.field type}: {.val {type}}.",
        "i" = "Use {.val optimize} or {.val fixed}."
      ))
    }

    if (type == "optimize") {
      for (field in c("n_symptoms", "n_required", "hierarchical")) {
        if (is.null(sc[[field]])) {
          cli::cli_abort(
            "Optimize scenario {.val {label}} is missing {.field {field}}."
          )
        }
      }
      .validate_n_symptoms(sc$n_symptoms)
      .validate_n_required(sc$n_required, sc$n_symptoms)
      if (!is.logical(sc$hierarchical) || length(sc$hierarchical) != 1) {
        cli::cli_abort(
          "Scenario {.val {label}}: {.field hierarchical} must be a single logical."
        )
      }
      if (isTRUE(sc$hierarchical)) {
        cl <- if (is.null(sc$clusters)) .get_default_clusters() else sc$clusters
        .validate_clusters(cl)
        if (sc$n_symptoms < length(cl)) {
          cli::cli_abort(c(
            "Scenario {.val {label}}: {.field n_symptoms} ({sc$n_symptoms}) must \\
            be at least the number of clusters ({length(cl)}).",
            "i" = "Hierarchical optimization requires >= 1 symptom per cluster."
          ))
        }
      }
    } else {
      # type == "fixed"
      if (is.null(sc$criterion)) {
        cli::cli_abort(
          "Fixed scenario {.val {label}} is missing {.field criterion}."
        )
      }
      crit <- sc$criterion
      if (is.character(crit) && length(crit) == 1) {
        if (!crit %in% names(registry)) {
          cli::cli_abort(c(
            "Scenario {.val {label}}: unknown {.field criterion} {.val {crit}}.",
            "i" = "Known criteria: {.or {.val {names(registry)}}}."
          ))
        }
      } else if (is.logical(crit)) {
        if (length(crit) != n_rows) {
          cli::cli_abort(c(
            "Scenario {.val {label}}: logical {.field criterion} has length \\
            {length(crit)} but {.arg data} has {n_rows} row{?s}.",
            "x" = "Lengths must match."
          ))
        }
        if (anyNA(crit)) {
          cli::cli_abort(
            "Scenario {.val {label}}: {.field criterion} contains {.val NA}."
          )
        }
        if (is.null(sc$symptoms)) {
          cli::cli_abort(c(
            "Scenario {.val {label}}: when {.field criterion} is a vector you \\
            must also supply {.field symptoms} = the integer indices of items \\
            counted as 'included' for the heatmap.",
            "i" = "Example: {.code list(type = \"fixed\", criterion = my_dx, symptoms = c(1, 6, 8, 15))}."
          ))
        }
        if (!is.numeric(sc$symptoms) || any(sc$symptoms != floor(sc$symptoms)) ||
            any(sc$symptoms < 1 | sc$symptoms > 20) ||
            anyDuplicated(sc$symptoms)) {
          cli::cli_abort(
            "Scenario {.val {label}}: {.field symptoms} must be unique integers \\
            between 1 and 20."
          )
        }
      } else {
        cli::cli_abort(c(
          "Scenario {.val {label}}: {.field criterion} must be a character \\
          string (one of {.or {.val {names(registry)}}}) or a logical vector.",
          "x" = "Got {.cls {class(crit)}}."
        ))
      }
    }
  }

  invisible(TRUE)
}
