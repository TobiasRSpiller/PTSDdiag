# Suppress R CMD check NOTEs for dplyr non-standard evaluation
utils::globalVariables(c(
  "true_positive", "newly_nondiagnosed", "true_negative", "newly_diagnosed",
  "sensitivity", "specificity", "ppv", "npv", "across", "Split",
  "Total Diagnosed", "Total Non-Diagnosed", "Scenario", "combination_id",
  "Total_Diagnosed_N", "Total_Diagnosed_Pct",
  "Total_Non_Diagnosed_N", "Total_Non_Diagnosed_Pct",
  "True Positive", "True Negative", "Newly Diagnosed", "Newly Non-Diagnosed",
  "True Cases", "False Cases",
  "True_Positive", "Newly_Non_Diagnosed", "True_Negative", "Newly_Diagnosed",
  "Splits_Appeared"
))

#' Perform holdout validation for PTSD diagnostic models
#'
#' @description
#' Validates PTSD diagnostic models using a train-test split approach (holdout validation).
#' Trains the model on a portion of the data and evaluates performance on the held-out test set.
#'
#' @details
#' The function:
#' \enumerate{
#'   \item Splits data into training and test sets based on \code{train_ratio}
#'   \item Finds optimal symptom combinations on training data
#'   \item Evaluates these combinations on test data
#'   \item Compares results to original DSM-5 diagnoses
#' }
#'
#' Two models are evaluated:
#' \itemize{
#'   \item Model without cluster representation: Any \code{n_required} of
#'     \code{n_symptoms} symptoms
#'   \item Model with cluster representation: \code{n_required} of
#'     \code{n_symptoms} symptoms with at least one from each cluster
#' }
#'
#' @param data A dataframe containing exactly 20 columns with PCL-5 item scores
#'   (output of rename_ptsd_columns). Each symptom should be scored on a 0-4 scale.
#' @param train_ratio Numeric between 0 and 1 indicating proportion of data for training
#'   (default: 0.7 for 70/30 split)
#' @param score_by Character string specifying optimization criterion:
#'   \itemize{
#'     \item "false_cases": Minimize total misclassifications
#'     \item "newly_nondiagnosed": Minimize false negatives only (default)
#'   }
#' @param seed Integer for random number generation reproducibility (default: 123)
#' @param n_symptoms Integer specifying how many symptoms per combination
#'   (default: 6). Must be between 1 and 20.
#' @param n_required Integer specifying how many symptoms must be present for
#'   diagnosis (default: 4). Must be between 1 and \code{n_symptoms}.
#' @param n_top Integer specifying how many top combinations to return
#'   (default: 3). Must be a positive integer.
#'
#' @param DT Logical. If \code{TRUE}, return summaries as interactive
#'   \code{\link[DT]{datatable}} widgets. If \code{FALSE} (default), return
#'   plain data.frames. The \pkg{DT} package must be installed when
#'   \code{DT = TRUE}.
#'
#' @returns A list containing:
#' \itemize{
#'   \item without_clusters: Results for model without cluster representation
#'     \itemize{
#'       \item best_combinations: The \code{n_top} best symptom combinations
#'         from training
#'       \item test_results: Diagnostic comparison on test data
#'       \item summary: Formatted summary statistics (data.frame or DT widget)
#'     }
#'   \item with_clusters: Results for model with cluster representation
#'     \itemize{
#'       \item best_combinations: The \code{n_top} best symptom combinations
#'         from training
#'       \item test_results: Diagnostic comparison on test data
#'       \item summary: Formatted summary statistics (data.frame or DT widget)
#'     }
#' }
#'
#' @export
#'
#'
#' @examples
#' # Create sample data
#' set.seed(42)
#' sample_data <- data.frame(
#'   matrix(sample(0:4, 20 * 200, replace = TRUE),
#'          nrow = 200,
#'          ncol = 20)
#' )
#' colnames(sample_data) <- paste0("symptom_", 1:20)
#'
#' \donttest{
#' # Perform holdout validation
#' validation_results <- holdout_validation(sample_data, train_ratio = 0.7)
#'
#' # Access results
#' validation_results$without_clusters$summary
#' validation_results$with_clusters$summary
#' }
#'
holdout_validation <- function(data, train_ratio = 0.7,
                               score_by = "newly_nondiagnosed", seed = 123,
                               n_symptoms = 6, n_required = 4, n_top = 3,
                               DT = FALSE) {
  # Input validation
  .validate_pcl5_data(data)
  .validate_score_by(score_by)
  .validate_n_symptoms(n_symptoms)
  .validate_n_required(n_required, n_symptoms)
  .validate_n_top(n_top)

  if (train_ratio <= 0 || train_ratio >= 1) {
    stop("train_ratio must be between 0 and 1")
  }

  # Set seed for reproducibility
  set.seed(seed)

  # Split data
  train_index <- sample(seq_len(nrow(data)), size = train_ratio * nrow(data))
  train_data <- data[train_index, ]
  test_data <- data[-train_index, ]

  cli::cli_alert_info("Training on {nrow(train_data)} observations, testing on {nrow(test_data)}")

  # Default PCL-5 clusters for hierarchical model
  default_clusters <- .get_default_clusters()

  # Model without cluster representation
  train_results_without <- optimize_combinations(
    train_data, n_symptoms = n_symptoms, n_required = n_required,
    n_top = n_top, score_by = score_by
  )
  top_combos_without <- train_results_without$best_symptoms

  # Apply to test data (non-hierarchical)
  comparison_df_without <- apply_symptom_combinations(
    test_data, top_combos_without, n_required = n_required, clusters = NULL
  )

  # Model with cluster representation
  train_results_with <- optimize_combinations_clusters(
    train_data, n_symptoms = n_symptoms, n_required = n_required,
    n_top = n_top, score_by = score_by, clusters = default_clusters
  )
  top_combos_with <- train_results_with$best_symptoms

  # Apply to test data (hierarchical)
  comparison_df_with <- apply_symptom_combinations(
    test_data, top_combos_with, n_required = n_required,
    clusters = default_clusters
  )

  # Create summaries
  summary_without <- .wrap_summary(comparison_df_without, DT = DT)
  summary_with <- .wrap_summary(comparison_df_with, DT = DT)

  cli::cli_alert_success("Holdout validation complete")

  list(
    without_clusters = list(
      best_combinations = top_combos_without,
      test_results = comparison_df_without,
      summary = summary_without
    ),
    with_clusters = list(
      best_combinations = top_combos_with,
      test_results = comparison_df_with,
      summary = summary_with
    )
  )
}


#' Perform k-fold cross-validation for PTSD diagnostic models
#'
#' @description
#' Validates PTSD diagnostic models using k-fold cross-validation to assess
#' generalization performance and identify stable symptom combinations.
#'
#' @details
#' The function:
#' \enumerate{
#'   \item Splits data into k folds
#'   \item For each fold, trains on k-1 folds and tests on the held-out fold
#'   \item Identifies symptom combinations that appear across multiple folds
#'   \item Calculates average performance metrics for repeated combinations
#' }
#'
#' Two models are evaluated:
#' \itemize{
#'   \item Model without cluster representation: Any \code{n_required} of
#'     \code{n_symptoms} symptoms
#'   \item Model with cluster representation: \code{n_required} of
#'     \code{n_symptoms} symptoms with at least one from each cluster
#' }
#'
#' If the \pkg{future.apply} package is installed and a
#' \code{\link[future]{plan}} has been set (e.g.,
#' \code{future::plan(future::multisession)}), folds are processed in
#' parallel via \code{\link[future.apply]{future_lapply}}. On macOS
#' (including Apple Silicon), use \code{future::multisession} rather than
#' \code{future::multicore}, especially inside RStudio.
#'
#' @param data A dataframe containing exactly 20 columns with PCL-5 item scores
#'   (output of rename_ptsd_columns). Each symptom should be scored on a 0-4 scale.
#' @param k Number of folds for cross-validation (default: 5)
#' @param score_by Character string specifying optimization criterion:
#'   \itemize{
#'     \item "false_cases": Minimize total misclassifications
#'     \item "newly_nondiagnosed": Minimize false negatives only (default)
#'   }
#' @param seed Integer for random number generation reproducibility (default: 123)
#' @param n_symptoms Integer specifying how many symptoms per combination
#'   (default: 6). Must be between 1 and 20.
#' @param n_required Integer specifying how many symptoms must be present for
#'   diagnosis (default: 4). Must be between 1 and \code{n_symptoms}.
#' @param n_top Integer specifying how many top combinations to return
#'   (default: 3). Must be a positive integer.
#'
#' @param DT Logical. If \code{TRUE}, return summaries as interactive
#'   \code{\link[DT]{datatable}} widgets. If \code{FALSE} (default), return
#'   plain data.frames. The \pkg{DT} package must be installed when
#'   \code{DT = TRUE}.
#'
#' @returns A list containing:
#' \itemize{
#'   \item without_clusters: Results for model without cluster representation
#'     \itemize{
#'       \item fold_results: List of diagnostic comparisons for each fold
#'       \item summary_by_fold: Detailed results for each fold (data.frame or DT
#'         widget)
#'       \item combinations_summary: Average performance for combinations appearing
#'         in multiple folds (data.frame, DT widget, or NULL if no combinations
#'         repeat)
#'     }
#'   \item with_clusters: Results for model with cluster representation
#'     \itemize{
#'       \item fold_results: List of diagnostic comparisons for each fold
#'       \item summary_by_fold: Detailed results for each fold (data.frame or DT
#'         widget)
#'       \item combinations_summary: Average performance for combinations appearing
#'         in multiple folds (data.frame, DT widget, or NULL if no combinations
#'         repeat)
#'     }
#' }
#'
#' @export
#'
#' @importFrom modelr crossv_kfold
#' @importFrom dplyr bind_rows group_by summarise mutate select everything across filter n
#'
#' @examples
#' # Create sample data
#' set.seed(42)
#' sample_data <- data.frame(
#'   matrix(sample(0:4, 20 * 200, replace = TRUE),
#'          nrow = 200,
#'          ncol = 20)
#' )
#' colnames(sample_data) <- paste0("symptom_", 1:20)
#'
#' \donttest{
#' # Perform 5-fold cross-validation
#' cv_results <- cross_validation(sample_data, k = 5)
#'
#' # View summary for each fold
#' cv_results$without_clusters$summary_by_fold
#'
#' # View combinations that appeared multiple times
#' cv_results$without_clusters$combinations_summary
#' }
#'
cross_validation <- function(data, k = 5, score_by = "newly_nondiagnosed",
                             seed = 123, n_symptoms = 6, n_required = 4,
                             n_top = 3, DT = FALSE) {
  # Input validation
  .validate_pcl5_data(data)
  .validate_score_by(score_by)
  .validate_n_symptoms(n_symptoms)
  .validate_n_required(n_required, n_symptoms)
  .validate_n_top(n_top)

  if (k < 2 || k > nrow(data)) {
    stop("k must be between 2 and the number of rows in the data")
  }

  # Set seed for reproducibility
  set.seed(seed)

  # Create cross-validation folds
  cv_splits <- modelr::crossv_kfold(data, k = k)

  # Default PCL-5 clusters for hierarchical model
  default_clusters <- .get_default_clusters()

  # Helper function to summarize CV splits
  summarize_cv_splits <- function(cv_list) {
    summaries <- lapply(seq_along(cv_list), function(i) {
      fold_data <- cv_list[[i]]
      summary_stats <- summarize_ptsd_changes(fold_data)

      # Compute diagnostic metrics and avoid division by zero
      summary_stats <- summary_stats %>%
        dplyr::mutate(
          Sensitivity = ifelse((true_positive + newly_nondiagnosed) == 0, NA,
                               round(true_positive / (true_positive + newly_nondiagnosed), 4)),
          Specificity = ifelse((true_negative + newly_diagnosed) == 0, NA,
                               round(true_negative / (true_negative + newly_diagnosed), 4)),
          PPV         = ifelse((true_positive + newly_diagnosed) == 0, NA,
                               round(true_positive / (true_positive + newly_diagnosed), 4)),
          NPV         = ifelse((true_negative + newly_nondiagnosed) == 0, NA,
                               round(true_negative / (true_negative + newly_nondiagnosed), 4))
        ) %>%

        # Replace NA values with 0 to prevent errors in summary display
        dplyr::mutate(
          across(c(sensitivity, specificity, ppv, npv),
                 ~ ifelse(is.na(.), 0, .))
        )

      # Convert to a readable summary table
      readable <- create_readable_summary(summary_stats)

      # Add combination_id and rank
      readable$combination_id <- vapply(readable$Scenario, function(s) {
        if (s == "PTSD_orig") return(NA_character_)
        sub("^symptom_", "", s)
      }, character(1), USE.NAMES = FALSE)
      non_orig <- readable$Scenario != "PTSD_orig"
      readable$rank <- NA_integer_
      readable$rank[non_orig] <- seq_len(sum(non_orig))

      readable$Split <- paste0("Split ", i)
      return(readable)
    })

    # Combine all splits into a single dataframe
    final_summary <- dplyr::bind_rows(summaries)
    final_summary <- dplyr::select(final_summary, Split, dplyr::everything())

    return(final_summary)
  }

  # Helper function to summarize average performance for repeated symptom combinations across splits
  summarize_combinations_across_splits <- function(cv_summary) {
    combo_summary <- cv_summary %>%
      dplyr::mutate(
        Total_Diagnosed_N = as.numeric(gsub(" \\(.*\\)", "", `Total Diagnosed`)),
        Total_Diagnosed_Pct = as.numeric(gsub(".*\\((.*)%\\)", "\\1", `Total Diagnosed`)),
        Total_Non_Diagnosed_N = as.numeric(gsub(" \\(.*\\)", "", `Total Non-Diagnosed`)),
        Total_Non_Diagnosed_Pct = as.numeric(gsub(".*\\((.*)%\\)", "\\1", `Total Non-Diagnosed`))
      ) %>%
      dplyr::group_by(Scenario, combination_id) %>%
      dplyr::summarise(
        Splits_Appeared = dplyr::n(),
        Total_Diagnosed = paste0(
          round(mean(Total_Diagnosed_N), 2),
          " (", round(mean(Total_Diagnosed_Pct), 2), "%)"
        ),
        Total_Non_Diagnosed = paste0(
          round(mean(Total_Non_Diagnosed_N), 2),
          " (", round(mean(Total_Non_Diagnosed_Pct), 2), "%)"
        ),
        True_Positive = round(mean(`True Positive`), 2),
        True_Negative = round(mean(`True Negative`), 2),
        Newly_Diagnosed = round(mean(`Newly Diagnosed`), 2),
        Newly_Non_Diagnosed = round(mean(`Newly Non-Diagnosed`), 2),
        True_Cases = round(mean(`True Cases`), 2),
        False_Cases = round(mean(`False Cases`), 2),
        .groups = "drop"
      ) %>%
      dplyr::mutate(
        Sensitivity = round(True_Positive / (True_Positive + Newly_Non_Diagnosed), 4),
        Specificity = round(True_Negative / (True_Negative + Newly_Diagnosed), 4),
        PPV = round(True_Positive / (True_Positive + Newly_Diagnosed), 4),
        NPV = round(True_Negative / (True_Negative + Newly_Non_Diagnosed), 4)
      )

    multiple_appearance <- combo_summary %>% dplyr::filter(Splits_Appeared > 1)

    if (nrow(multiple_appearance) == 0) {
      return(NULL)
    } else {
      return(multiple_appearance)
    }
  }

  # Run cross-validation folds (parallel if future.apply is available)
  if (requireNamespace("future.apply", quietly = TRUE)) {
    fold_results <- future.apply::future_lapply(
      seq_len(k),
      .run_cv_fold,
      cv_splits = cv_splits,
      n_symptoms = n_symptoms, n_required = n_required,
      n_top = n_top, score_by = score_by,
      default_clusters = default_clusters,
      future.seed = TRUE
    )
  } else {
    fold_results <- vector("list", k)
    cli::cli_progress_bar("Processing folds", total = k)
    for (i in seq_len(k)) {
      fold_results[[i]] <- .run_cv_fold(
        i, cv_splits, n_symptoms, n_required, n_top, score_by, default_clusters
      )
      cli::cli_progress_update()
    }
    cli::cli_progress_done()
  }

  cv_results_without <- lapply(fold_results, `[[`, "without")
  cv_results_with <- lapply(fold_results, `[[`, "with")

  # Apply summary functions
  cv_summary_without <- summarize_cv_splits(cv_results_without)
  cv_summary_with <- summarize_cv_splits(cv_results_with)

  # Apply combination summary functions
  combo_summary_without <- summarize_combinations_across_splits(cv_summary_without)
  combo_summary_with <- summarize_combinations_across_splits(cv_summary_with)

  # Format results (optionally wrap with DT)
  wrap_output <- function(x) {
    if (!is.null(x) && isTRUE(DT)) {
      if (!requireNamespace("DT", quietly = TRUE)) {
        stop("Package 'DT' is required when DT = TRUE. Install it with install.packages('DT').")
      }
      DT::datatable(x, options = list(scrollX = TRUE))
    } else {
      x
    }
  }

  list(
    without_clusters = list(
      fold_results = cv_results_without,
      summary_by_fold = wrap_output(cv_summary_without),
      combinations_summary = wrap_output(combo_summary_without)
    ),
    with_clusters = list(
      fold_results = cv_results_with,
      summary_by_fold = wrap_output(cv_summary_with),
      combinations_summary = wrap_output(combo_summary_with)
    )
  )
}
