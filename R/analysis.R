#' Find optimal symptom combinations for diagnosis (non-hierarchical)
#'
#' @description
#' Identifies the best symptom combinations for PTSD diagnosis where a specified
#' number of symptoms must be present, regardless of their cluster membership.
#' This is a generalized version that allows configuring the number of symptoms
#' per combination, the required threshold, and how many top results to return.
#'
#' @details
#' The function:
#'
#' \enumerate{
#'  \item Tests all possible combinations of \code{n_symptoms} symptoms from the
#'    20 PCL-5 items
#'  \item Requires \code{n_required} symptoms to be present (>=2 on original 0-4
#'    scale) for diagnosis
#'  \item Identifies the \code{n_top} combinations that best match the original
#'    DSM-5 diagnosis
#' }
#'
#' Optimization can be based on either:
#'
#' \itemize{
#' \item Minimizing false cases (both false positives and false negatives)
#' \item Minimizing only false negatives (newly non-diagnosed cases)
#'}
#'
#' The symptom clusters in PCL-5 are:
#'
#' \itemize{
#' \item Items 1-5: Intrusion symptoms (Criterion B)
#' \item Items 6-7: Avoidance symptoms (Criterion C)
#' \item Items 8-14: Negative alterations in cognitions and mood (Criterion D)
#' \item Items 15-20: Alterations in arousal and reactivity (Criterion E)
#'}
#'
#' @param data A dataframe containing exactly 20 columns with PCL-5 item scores
#'   (output of \code{\link{rename_ptsd_columns}}). Each symptom should be scored
#'   on a 0-4 scale where:
#'
#' \itemize{
#'   \item 0 = Not at all
#'   \item 1 = A little bit
#'   \item 2 = Moderately
#'   \item 3 = Quite a bit
#'   \item 4 = Extremely
#'}
#'
#' @param n_symptoms Integer specifying how many symptoms per combination
#'   (default: 6). Must be between 1 and 20.
#'
#' @param n_required Integer specifying how many symptoms must be present for
#'   diagnosis (default: 4). Must be between 1 and \code{n_symptoms}.
#'
#' @param n_top Integer specifying how many top combinations to return
#'   (default: 3). Must be a positive integer.
#'
#' @param score_by Character string specifying optimization criterion:
#'
#' \itemize{
#'   \item "false_cases": Minimize total misclassifications
#'   \item "newly_nondiagnosed": Minimize false negatives only
#'}
#'
#' @returns A list containing:
#'
#' \itemize{
#'   \item best_symptoms: List of \code{n_top} vectors, each containing
#'     \code{n_symptoms} symptom numbers representing the best combinations found
#'   \item diagnosis_comparison: Dataframe comparing original DSM-5 diagnosis with
#'     diagnoses based on the best combinations
#'   \item summary: Interactive datatable (DT) showing diagnostic accuracy metrics
#'     for each combination
#'}
#'
#' @export
#'
#' @importFrom utils combn
#'
#' @examples
#' # Create example data
#' ptsd_data <- data.frame(matrix(sample(0:4, 200, replace=TRUE), ncol=20))
#' names(ptsd_data) <- paste0("symptom_", 1:20)
#'
#' \donttest{
#' # Find best 6-symptom combinations requiring 4 present (classic defaults)
#' results <- optimize_combinations(ptsd_data, n_symptoms = 6, n_required = 4,
#'              score_by = "false_cases")
#'
#' # Find best 5-symptom combinations requiring 3 present, return top 5
#' results2 <- optimize_combinations(ptsd_data, n_symptoms = 5, n_required = 3,
#'               n_top = 5, score_by = "false_cases")
#'
#' # Get symptom numbers
#' results$best_symptoms
#'
#' # View summary statistics
#' results$summary
#' }
#'
optimize_combinations <- function(data, n_symptoms = 6, n_required = 4,
                                  n_top = 3, score_by = "false_cases") {
  # Validate inputs
  .validate_pcl5_data(data)
  .validate_score_by(score_by)
  .validate_n_symptoms(n_symptoms)
  .validate_n_required(n_required, n_symptoms)
  .validate_n_top(n_top)

  # Get baseline results and binarize data
  baseline_results <- create_ptsd_diagnosis_binarized(data)$PTSD_orig
  binarized_data <- binarize_data(data)

  # Generate all possible combinations
  all_symptoms <- 1:20
  combinations <- utils::combn(all_symptoms, n_symptoms, simplify = FALSE)

  # Diagnosis function for non-hierarchical mode
  diagnose_fn <- function(bdata, symptoms) {
    .diagnose_combination(bdata, symptoms, n_required, clusters = NULL)
  }

  # Find best combinations
  top_combinations <- .find_top_n(combinations, binarized_data, baseline_results,
                                  score_by, n_top, diagnose_fn)

  # Build output
  comparison_df <- .build_comparison_df(baseline_results, top_combinations, nrow(data))
  summary_table <- .wrap_summary(comparison_df)

  return(list(
    best_symptoms = lapply(
      Filter(function(x) !is.null(x$combination), top_combinations),
      function(x) x$combination
    ),
    diagnosis_comparison = comparison_df,
    summary = summary_table
  ))
}


#' Find optimal symptom combinations for diagnosis (hierarchical/cluster-based)
#'
#' @description
#' Identifies the best symptom combinations for PTSD diagnosis where a specified
#' number of symptoms must be present and must include at least one symptom from
#' each defined cluster. This maintains the hierarchical structure of the
#' diagnostic criteria while allowing configurable parameters.
#'
#' @details
#' The function:
#'
#' \enumerate{
#' \item Generates valid combinations ensuring representation from all clusters
#' \item Requires \code{n_required} symptoms to be present (>=2 on original 0-4
#'   scale) for diagnosis
#' \item Validates that present symptoms include at least one from each cluster
#' \item Identifies the \code{n_top} combinations that best match the original
#'   DSM-5 diagnosis
#'}
#'
#' The \code{clusters} parameter must be a named list specifying the cluster
#' structure. For PCL-5, the standard clusters are:
#'
#' \itemize{
#' \item Cluster B (Intrusion): Items 1-5
#' \item Cluster C (Avoidance): Items 6-7
#' \item Cluster D (Negative alterations in cognitions and mood): Items 8-14
#' \item Cluster E (Alterations in arousal and reactivity): Items 15-20
#'}
#'
#' Optimization can be based on either:
#'
#' \itemize{
#' \item Minimizing false cases (both false positives and false negatives)
#' \item Minimizing only false negatives (newly non-diagnosed cases)
#'}
#'
#' @param data A dataframe containing exactly 20 columns with PCL-5 item scores
#'   (output of \code{\link{rename_ptsd_columns}}). Each symptom should be scored
#'   on a 0-4 scale where:
#'
#' \itemize{
#'   \item 0 = Not at all
#'   \item 1 = A little bit
#'   \item 2 = Moderately
#'   \item 3 = Quite a bit
#'   \item 4 = Extremely
#'}
#'
#' @param n_symptoms Integer specifying how many symptoms per combination
#'   (default: 6). Must be at least as large as the number of clusters.
#'
#' @param n_required Integer specifying how many symptoms must be present for
#'   diagnosis (default: 4). Must be between 1 and \code{n_symptoms}.
#'
#' @param n_top Integer specifying how many top combinations to return
#'   (default: 3). Must be a positive integer.
#'
#' @param score_by Character string specifying optimization criterion:
#'
#' \itemize{
#'   \item "false_cases": Minimize total misclassifications
#'   \item "newly_nondiagnosed": Minimize false negatives only
#'}
#'
#' @param clusters A named list of integer vectors defining the cluster
#'   structure. Each list element represents one cluster, with the integer
#'   vector specifying which symptom indices belong to that cluster. Cluster
#'   elements must not overlap. This parameter is required (no default).
#'
#'   For PCL-5:
#'   \code{list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)}
#'
#' @returns A list containing:
#'
#' \itemize{
#'   \item best_symptoms: List of \code{n_top} vectors, each containing
#'     \code{n_symptoms} symptom numbers representing the best combinations found
#'   \item diagnosis_comparison: Dataframe comparing original DSM-5 diagnosis with
#'     diagnoses based on the best combinations
#'   \item summary: Interactive datatable (DT) showing diagnostic accuracy metrics
#'     for each combination
#'}
#'
#' @export
#'
#' @importFrom utils combn
#'
#' @examples
#' # Create example data
#' ptsd_data <- data.frame(matrix(sample(0:4, 200, replace=TRUE), ncol=20))
#' names(ptsd_data) <- paste0("symptom_", 1:20)
#'
#' \donttest{
#' # Find best hierarchical combinations with PCL-5 clusters
#' pcl5_clusters <- list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)
#' results <- optimize_combinations_clusters(ptsd_data, n_symptoms = 6,
#'              n_required = 4, score_by = "false_cases", clusters = pcl5_clusters)
#'
#' # Get symptom numbers
#' results$best_symptoms
#'
#' # View summary statistics
#' results$summary
#' }
#'
optimize_combinations_clusters <- function(data, n_symptoms = 6, n_required = 4,
                                           n_top = 3, score_by = "false_cases",
                                           clusters) {
  # Validate inputs
  .validate_pcl5_data(data)
  .validate_score_by(score_by)
  .validate_n_symptoms(n_symptoms)
  .validate_n_required(n_required, n_symptoms)
  .validate_n_top(n_top)
  .validate_clusters(clusters)

  n_clusters <- length(clusters)
  if (n_symptoms < n_clusters) {
    stop("n_symptoms (", n_symptoms, ") must be at least as large as the number of clusters (",
         n_clusters, ")")
  }

  # Get baseline results and binarize data
  baseline_results <- create_ptsd_diagnosis_binarized(data)$PTSD_orig
  binarized_data <- as.matrix(binarize_data(data))

  # Generate valid combinations ensuring representation from all clusters
  # Strategy: pick one symptom from each cluster as "base", then fill remaining
  # slots from the remaining symptom pool
  n_remaining <- n_symptoms - n_clusters

  # Generate all "base" combinations (one from each cluster)
  # Use expand.grid to get all combinations of one-from-each-cluster
  cluster_items <- lapply(clusters, function(cl) cl)
  base_grid <- expand.grid(cluster_items, KEEP.OUT.ATTRS = FALSE)

  valid_combinations <- vector("list", nrow(base_grid) * 100)
  combination_count <- 0

  all_items <- 1:20

  for (row_idx in seq_len(nrow(base_grid))) {
    base <- as.integer(base_grid[row_idx, ])
    remaining_pool <- setdiff(all_items, base)

    if (n_remaining == 0) {
      # Exactly one from each cluster, no remaining slots
      combination_count <- combination_count + 1
      if (combination_count > length(valid_combinations)) {
        length(valid_combinations) <- length(valid_combinations) * 2
      }
      valid_combinations[[combination_count]] <- sort(base)
    } else {
      # Choose n_remaining from the remaining pool
      extras <- utils::combn(remaining_pool, n_remaining, simplify = FALSE)
      for (extra in extras) {
        combination_count <- combination_count + 1
        if (combination_count > length(valid_combinations)) {
          length(valid_combinations) <- length(valid_combinations) * 2
        }
        valid_combinations[[combination_count]] <- sort(c(base, extra))
      }
    }
  }

  valid_combinations <- valid_combinations[seq_len(combination_count)]
  valid_combinations <- unique(valid_combinations)

  # Diagnosis function for hierarchical mode
  diagnose_fn <- function(bdata, symptoms) {
    .diagnose_combination(bdata, symptoms, n_required, clusters = clusters)
  }

  # Find best combinations
  top_combinations <- .find_top_n(valid_combinations, binarized_data,
                                  baseline_results, score_by, n_top, diagnose_fn)

  # Build output
  comparison_df <- .build_comparison_df(baseline_results, top_combinations, nrow(data))
  summary_table <- .wrap_summary(comparison_df)

  return(list(
    best_symptoms = lapply(
      Filter(function(x) !is.null(x$combination), top_combinations),
      function(x) x$combination
    ),
    diagnosis_comparison = comparison_df,
    summary = summary_table
  ))
}


#' Find optimal non-hierarchical six-symptom combinations for PTSD diagnosis
#'
#' @description
#' Convenience wrapper around \code{\link{optimize_combinations}} with the
#' original PCL-5 defaults: 6 symptoms, 4 required, top 3 returned.
#'
#' Identifies the three best six-symptom combinations for PTSD diagnosis
#' where any four symptoms must be present, regardless of their cluster membership.
#'
#' @details
#' The function:
#'
#' \enumerate{
#'  \item Tests all possible combinations of 6 symptoms from the 20 PCL-5 items
#'  \item Requires 4 symptoms to be present (>=2 on original 0-4 scale) for diagnosis
#'  \item Identifies the three combinations that best match the original DSM-5 diagnosis
#' }
#'
#' Optimization can be based on either:
#'
#' \itemize{
#' \item Minimizing false cases (both false positives and false negatives)
#' \item Minimizing only false negatives (newly non-diagnosed cases)
#'}
#'
#' The symptom clusters in PCL-5 are:
#'
#' \itemize{
#' \item Items 1-5: Intrusion symptoms (Criterion B)
#' \item Items 6-7: Avoidance symptoms (Criterion C)
#' \item Items 8-14: Negative alterations in cognitions and mood (Criterion D)
#' \item Items 15-20: Alterations in arousal and reactivity (Criterion E)
#'}
#'
#' @param data A dataframe containing exactly 20 columns with PCL-5 item scores
#'   (output of rename_ptsd_columns). Each symptom should be scored on a 0-4
#'   scale where:
#'
#' \itemize{
#'   \item 0 = Not at all
#'   \item 1 = A little bit
#'   \item 2 = Moderately
#'   \item 3 = Quite a bit
#'   \item 4 = Extremely
#'}
#'
#' @param score_by Character string specifying optimization criterion:
#'
#' \itemize{
#'   \item "false_cases": Minimize total misclassifications
#'   \item "newly_nondiagnosed": Minimize false negatives only
#'}
#'
#' @returns A list containing:
#'
#' \itemize{
#'   \item best_symptoms: List of three vectors, each containing six symptom numbers
#'     representing the best combinations found
#'   \item diagnosis_comparison: Dataframe comparing original DSM-5 diagnosis with
#'     diagnoses based on the three best combinations
#'   \item summary: Interactive datatable (DT) showing diagnostic accuracy metrics
#'     for each combination
#'}
#'
#' @seealso \code{\link{optimize_combinations}} for the generalized version with
#'   configurable parameters.
#'
#' @export
#'
#' @importFrom utils combn
#'
#' @examples
#' # Create example data
#' ptsd_data <- data.frame(matrix(sample(0:4, 200, replace=TRUE), ncol=20))
#' names(ptsd_data) <- paste0("symptom_", 1:20)
#'
#' \donttest{
#' # Find best combinations minimizing false cases
#' results <- analyze_best_six_symptoms_four_required(ptsd_data, score_by = "false_cases")
#'
#' # Get symptom numbers
#' results$best_symptoms
#'
#' # View raw comparison data
#' results$diagnosis_comparison
#'
#' # View summary statistics
#' results$summary
#' }
#'
analyze_best_six_symptoms_four_required <- function(data, score_by = "false_cases") {
  optimize_combinations(data, n_symptoms = 6, n_required = 4,
                        n_top = 3, score_by = score_by)
}


#' Find optimal hierarchical six-symptom combinations for PTSD diagnosis
#'
#' @description
#' Convenience wrapper around \code{\link{optimize_combinations_clusters}} with
#' the original PCL-5 defaults: 6 symptoms, 4 required, top 3 returned, and
#' standard DSM-5 cluster structure.
#'
#' Identifies the three best six-symptom combinations for PTSD diagnosis
#' where four symptoms must be present and must include at least one symptom from
#' each DSM-5 criterion cluster.
#'
#' @details
#' The function:
#'
#' \enumerate{
#' \item Generates valid combinations ensuring representation from all clusters
#' \item Requires 4 symptoms to be present (>=2 on original 0-4 scale) for diagnosis
#' \item Validates that present symptoms include at least one from each cluster
#' \item Identifies the three combinations that best match the original DSM-5 diagnosis
#'}
#'
#' DSM-5 PTSD symptom clusters:
#'
#' \itemize{
#' \item Cluster 1 (B) - Intrusion: Items 1-5
#' \item Cluster 2 (C) - Avoidance: Items 6-7
#' \item Cluster 3 (D) - Negative alterations in cognitions and mood: Items 8-14
#' \item Cluster 4 (E) - Alterations in arousal and reactivity: Items 15-20
#'}
#'
#' Optimization can be based on either:
#'
#' \itemize{
#' \item Minimizing false cases (both false positives and false negatives)
#' \item Minimizing only false negatives (newly non-diagnosed cases)
#'}
#'
#' @param data A dataframe containing exactly 20 columns with PCL-5 item scores
#'   (output of rename_ptsd_columns). Each symptom should be scored on a 0-4
#'   scale where:
#'
#' \itemize{
#'   \item 0 = Not at all
#'   \item 1 = A little bit
#'   \item 2 = Moderately
#'   \item 3 = Quite a bit
#'   \item 4 = Extremely
#'}
#'
#' @param score_by Character string specifying optimization criterion:
#'
#' \itemize{
#'   \item "false_cases": Minimize total misclassifications
#'   \item "newly_nondiagnosed": Minimize false negatives only
#'}
#'
#' @returns A list containing:
#'
#' \itemize{
#'   \item best_symptoms: List of three vectors, each containing six symptom numbers
#'     representing the best combinations found
#'   \item diagnosis_comparison: Dataframe comparing original DSM-5 diagnosis with
#'     diagnoses based on the three best combinations
#'   \item summary: Interactive datatable (DT) showing diagnostic accuracy metrics
#'     for each combination
#'}
#'
#' @seealso \code{\link{optimize_combinations_clusters}} for the generalized
#'   version with configurable parameters and custom cluster definitions.
#'
#' @export
#'
#' @importFrom utils combn
#'
#' @examples
#' # Create example data
#' ptsd_data <- data.frame(matrix(sample(0:4, 200, replace=TRUE), ncol=20))
#' names(ptsd_data) <- paste0("symptom_", 1:20)
#'
#' \donttest{
#' # Find best hierarchical combinations minimizing false cases
#' results <- analyze_best_six_symptoms_four_required_clusters(ptsd_data, score_by = "false_cases")
#'
#' # Get symptom numbers
#' results$best_symptoms
#'
#' # View raw comparison data
#' results$diagnosis_comparison
#'
#' # View summary statistics
#' results$summary
#' }
#'
analyze_best_six_symptoms_four_required_clusters <- function(data, score_by = "false_cases") {
  optimize_combinations_clusters(data, n_symptoms = 6, n_required = 4,
                                 n_top = 3, score_by = score_by,
                                 clusters = .get_default_clusters())
}
