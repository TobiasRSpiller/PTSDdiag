# Internal helper functions for PTSDdiag
# These are NOT exported. All prefixed with "." and tagged @noRd.

#' Validate PCL-5 input data
#' @noRd
.validate_pcl5_data <- function(data) {
  if (!is.data.frame(data)) {
    stop("Input must be a dataframe")
  }

  if (ncol(data) != 20) {
    stop("Data must contain exactly 20 columns (one for each PCL-5 item)")
  }

  expected_cols <- paste0("symptom_", 1:20)
  if (!all(expected_cols %in% colnames(data))) {
    stop("Data must contain columns named 'symptom_1' through 'symptom_20'")
  }

  if ("total" %in% colnames(data)) {
    warning("'total' column detected. This function should only be used with raw symptom scores.")
  }

  if (!all(vapply(data[expected_cols], is.numeric, logical(1)))) {
    stop("All symptom columns must contain numeric values")
  }

  if (any(is.na(data[expected_cols]))) {
    stop("Data contains missing values (NA)")
  }

  invalid_values <- !all(vapply(data[expected_cols], function(x)
    all(x >= 0 & x <= 4 & x == floor(x)), logical(1)))
  if (invalid_values) {
    stop("All symptom values must be integers between 0 and 4")
  }

  if (nrow(data) < 1) {
    stop("Data must contain at least one row")
  }

  invisible(TRUE)
}

#' Validate score_by parameter
#' @noRd
.validate_score_by <- function(score_by) {
  valid_scoring <- c("false_cases", "newly_nondiagnosed")
  if (!score_by %in% valid_scoring) {
    stop("score_by must be one of: ", paste(valid_scoring, collapse = ", "))
  }
  invisible(TRUE)
}

#' Validate n_symptoms parameter
#' @noRd
.validate_n_symptoms <- function(n_symptoms, n_total = 20) {
  if (!is.numeric(n_symptoms) || length(n_symptoms) != 1 ||
      n_symptoms != floor(n_symptoms) || n_symptoms < 1 || n_symptoms > n_total) {
    stop("n_symptoms must be a single integer between 1 and ", n_total)
  }
  invisible(TRUE)
}

#' Validate n_required parameter
#' @noRd
.validate_n_required <- function(n_required, n_symptoms) {
  if (!is.numeric(n_required) || length(n_required) != 1 ||
      n_required != floor(n_required) || n_required < 1 || n_required > n_symptoms) {
    stop("n_required must be a single integer between 1 and n_symptoms (", n_symptoms, ")")
  }
  invisible(TRUE)
}

#' Validate n_top parameter
#' @noRd
.validate_n_top <- function(n_top) {
  if (!is.numeric(n_top) || length(n_top) != 1 ||
      n_top != floor(n_top) || n_top < 1) {
    stop("n_top must be a single positive integer")
  }
  invisible(TRUE)
}

#' Validate clusters parameter
#' @noRd
.validate_clusters <- function(clusters, n_total = 20) {
  if (!is.list(clusters) || length(clusters) < 1) {
    stop("clusters must be a non-empty named list of integer vectors")
  }
  if (is.null(names(clusters)) || any(names(clusters) == "")) {
    stop("clusters must be a named list (e.g., list(B = 1:5, C = 6:7, D = 8:14, E = 15:20))")
  }
  all_items <- unlist(clusters)
  if (!is.numeric(all_items) || any(all_items != floor(all_items))) {
    stop("All cluster elements must be integers")
  }
  if (any(all_items < 1) || any(all_items > n_total)) {
    stop("All cluster elements must be between 1 and ", n_total)
  }
  if (length(all_items) != length(unique(all_items))) {
    stop("Cluster elements must not overlap (each item can belong to only one cluster)")
  }
  invisible(TRUE)
}

#' Validate combinations input
#' @noRd
.validate_combinations_input <- function(combinations, n_total = 20) {
  if (!is.list(combinations) || length(combinations) < 1) {
    stop("combinations must be a non-empty list of integer vectors")
  }
  lengths_vec <- lengths(combinations)
  if (length(unique(lengths_vec)) != 1) {
    stop("All combinations must have the same length")
  }
  for (i in seq_along(combinations)) {
    combo <- combinations[[i]]
    if (!is.numeric(combo) || any(combo != floor(combo))) {
      stop("All combination elements must be integers")
    }
    if (any(combo < 1) || any(combo > n_total)) {
      stop("All combination elements must be between 1 and ", n_total)
    }
    if (length(combo) != length(unique(combo))) {
      stop("Combination elements must be unique (no duplicate symptom indices)")
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
    stop("Invalid combinations file: missing required fields: ",
         paste(missing, collapse = ", "))
  }
  if (!is.list(x$parameters) || is.null(x$parameters$n_required)) {
    stop("Invalid combinations file: 'parameters' must contain 'n_required'")
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
#' @param score_by Character: "false_cases" or "newly_nondiagnosed".
#' @param n_top Integer: how many top combinations to track.
#' @param diagnose_fn Function(binarized_data, symptoms) -> logical vector.
#' @return List of n_top elements, each with $combination, $score, $diagnoses.
#' @noRd
.find_top_n <- function(combinations, binarized_data, baseline_results,
                        score_by, n_top, diagnose_fn) {
  top <- replicate(n_top,
    list(combination = NULL, score = -Inf, diagnoses = NULL),
    simplify = FALSE
  )

  for (combination in combinations) {
    current_diagnoses <- diagnose_fn(binarized_data, combination)

    newly_diagnosed <- sum(!baseline_results & current_diagnoses)
    newly_nondiagnosed <- sum(baseline_results & !current_diagnoses)

    score <- if (score_by == "false_cases") {
      -(newly_diagnosed + newly_nondiagnosed)
    } else {
      -newly_nondiagnosed
    }

    # Find insertion position
    for (pos in seq_len(n_top)) {
      if (score > top[[pos]]$score) {
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
  }

  return(top)
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
    stop("No valid combinations found")
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
      stop("Package 'DT' is required when DT = TRUE. Install it with install.packages('DT').")
    }
    summary_table <- DT::datatable(summary_table, options = list(scrollX = TRUE))
  }
  return(summary_table)
}

#' Run a single cross-validation fold
#'
#' @param i Integer fold index.
#' @param cv_splits Object from modelr::crossv_kfold().
#' @param n_symptoms Integer.
#' @param n_required Integer.
#' @param n_top Integer.
#' @param score_by Character.
#' @param default_clusters Named list of cluster definitions.
#' @return List with $without and $with comparison data frames.
#' @noRd
.run_cv_fold <- function(i, cv_splits, n_symptoms, n_required, n_top,
                         score_by, default_clusters) {
  train_data <- as.data.frame(cv_splits$train[[i]])
  test_data <- as.data.frame(cv_splits$test[[i]])

  # Model without cluster representation
  train_results_without <- optimize_combinations(
    train_data, n_symptoms = n_symptoms, n_required = n_required,
    n_top = n_top, score_by = score_by
  )
  top_combos_without <- train_results_without$best_symptoms
  result_without <- apply_symptom_combinations(
    test_data, top_combos_without, n_required = n_required, clusters = NULL
  )

  # Model with cluster representation
  train_results_with <- optimize_combinations_clusters(
    train_data, n_symptoms = n_symptoms, n_required = n_required,
    n_top = n_top, score_by = score_by, clusters = default_clusters
  )
  top_combos_with <- train_results_with$best_symptoms
  result_with <- apply_symptom_combinations(
    test_data, top_combos_with, n_required = n_required,
    clusters = default_clusters
  )

  list(without = result_without, with = result_with)
}
