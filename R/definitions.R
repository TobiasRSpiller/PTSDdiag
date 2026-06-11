#' Extract portable symptom definitions from a comparison
#'
#' @description
#' Pulls the top symptom combinations of each optimized scenario out of a
#' \code{\link{compare_optimizations}} result and returns them as a compact,
#' shareable object. Each definition is described only by its symptom indices
#' and the rule needed to apply it (how many must be present, and whether
#' cluster representation is required), so the object contains no
#' participant-level data and can be shared across sites.
#'
#' @details
#' For each \code{type = "optimize"} scenario in the comparison, the rule
#' (\code{n_required}, \code{hierarchical}) is read from
#' \code{comparison$config}, so the only thing the user supplies is how many
#' combinations to carry per scenario. Fixed scenarios (e.g. ICD-11) are
#' skipped, because their symptom set is published rather than derived.
#'
#' The result pairs with \code{\link{evaluate_definitions}}: extract the
#' definitions from one sample, then evaluate them in any sample.
#'
#' @param comparison A \code{ptsdiag_comparison} object from
#'   \code{\link{compare_optimizations}}.
#' @param n Integer. Number of top combinations to keep per optimized
#'   scenario (default 5). Capped at the number available.
#'
#' @returns A named list (one element per optimized scenario). Each element is
#'   a list with:
#'   \itemize{
#'     \item \code{symptoms}: list of integer vectors (the top-\code{n}
#'       combinations).
#'     \item \code{n_required}: integer threshold for that scenario.
#'     \item \code{hierarchical}: logical, whether cluster representation is
#'       required.
#'   }
#'
#' @seealso \code{\link{evaluate_definitions}},
#'   \code{\link{compare_optimizations}}.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Use a 250-row subset and a small 4-symptom search to keep the example
#' # fast; omit `scenarios` to run the three default rules
#' ptsd <- rename_ptsd_columns(simulated_ptsd[1:250, ],
#'                             id_col = c("patient_id", "age", "sex"))
#' comp <- compare_optimizations(
#'   ptsd,
#'   scenarios = list(
#'     "3/4 Non-hierarchical" = list(n_symptoms = 4, n_required = 3,
#'                                   hierarchical = FALSE)
#'   ),
#'   n_top = 10, show_progress = FALSE
#' )
#' definitions <- extract_definitions(comp, n = 5)
#' lapply(definitions, function(d) d$symptoms)
#' }
extract_definitions <- function(comparison, n = 5) {
  if (!inherits(comparison, "ptsdiag_comparison")) {
    cli::cli_abort(
      "{.arg comparison} must be a {.cls ptsdiag_comparison} object \\
       (from {.fn compare_optimizations})."
    )
  }
  if (!is.numeric(n) || length(n) != 1 || n != floor(n) || n < 1) {
    cli::cli_abort("{.arg n} must be a single positive integer.")
  }
  n <- as.integer(n)

  cfg      <- comparison$config
  optimize <- cfg$label[cfg$type == "optimize"]
  if (length(optimize) == 0) {
    cli::cli_abort(c(
      "{.arg comparison} contains no optimize scenarios to extract.",
      "i" = "Fixed criteria (e.g. ICD-11) are not extracted as definitions."
    ))
  }

  defs <- lapply(optimize, function(label) {
    row    <- cfg[cfg$label == label, ]
    combos <- comparison$scenarios[[label]]$best_symptoms
    list(
      symptoms     = combos[seq_len(min(n, length(combos)))],
      n_required   = row$n_required,
      hierarchical = isTRUE(row$hierarchical)
    )
  })
  stats::setNames(defs, optimize)
}


#' Evaluate symptom definitions against a sample
#'
#' @description
#' Applies a set of pre-derived symptom definitions to a dataset and returns a
#' performance table scoring each one against that sample's full DSM-5-TR
#' diagnosis. Because it needs only the definitions (symptom indices and rules)
#' and a data frame, the same call can be run at a site that never saw the data
#' the definitions were derived from.
#'
#' @details
#' Each definition is applied with its own rule via
#' \code{\link{apply_symptom_combinations}} (using the default PCL-5 clusters
#' when \code{hierarchical = TRUE}). When \code{include_icd11 = TRUE}, the
#' ICD-11 criterion (\code{\link{create_icd11_diagnosis}}) is added as a fixed
#' benchmark, computed locally on the supplied data. Every definition is then
#' scored against the full DSM-5-TR diagnosis with
#' \code{\link{summarize_ptsd_changes}} and \code{\link{create_readable_summary}}.
#'
#' @param data A dataframe with the 20 PCL-5 item columns \code{symptom_1}
#'   through \code{symptom_20} (output of \code{\link{rename_ptsd_columns}}).
#'   Additional carry-through columns are ignored.
#' @param definitions A named list of definitions, as returned by
#'   \code{\link{extract_definitions}}. Each element must contain
#'   \code{symptoms} (a list of integer vectors), \code{n_required}, and
#'   \code{hierarchical}.
#' @param include_icd11 Logical. If \code{TRUE} (default), append the ICD-11
#'   criterion as a benchmark row.
#'
#' @returns A formatted performance table (see
#'   \code{\link{create_readable_summary}}): one row for the full DSM-5-TR
#'   reference, one per definition (labelled by rule and symptom set), and one
#'   for ICD-11 when included. Includes Sensitivity, Specificity, PPV, NPV,
#'   Accuracy, and Balanced Accuracy.
#'
#' @seealso \code{\link{extract_definitions}},
#'   \code{\link{compare_optimizations}}.
#'
#' @export
#'
#' @importFrom magrittr %>%
#'
#' @examples
#' \donttest{
#' # Use a 250-row subset and a small 4-symptom search to keep the example
#' # fast; omit `scenarios` to run the three default rules
#' ptsd <- rename_ptsd_columns(simulated_ptsd[1:250, ],
#'                             id_col = c("patient_id", "age", "sex"))
#' comp <- compare_optimizations(
#'   ptsd,
#'   scenarios = list(
#'     "3/4 Non-hierarchical" = list(n_symptoms = 4, n_required = 3,
#'                                   hierarchical = FALSE)
#'   ),
#'   n_top = 10, show_progress = FALSE
#' )
#' definitions <- extract_definitions(comp, n = 3)
#' evaluate_definitions(ptsd, definitions)
#' }
evaluate_definitions <- function(data, definitions, include_icd11 = TRUE) {
  .validate_pcl5_data(data, strict_cols = FALSE)
  .validate_definitions(definitions, nrow(data))
  if (!is.logical(include_icd11) || length(include_icd11) != 1) {
    cli::cli_abort("{.arg include_icd11} must be a single logical.")
  }

  clusters <- .get_default_clusters()

  comparison <- data.frame(
    PTSD_orig = create_ptsd_diagnosis_binarized(data)$PTSD_orig,
    check.names = FALSE
  )

  for (rule in names(definitions)) {
    d  <- definitions[[rule]]
    cl <- if (isTRUE(d$hierarchical)) clusters else NULL
    applied <- apply_symptom_combinations(
      data, d$symptoms, n_required = d$n_required, clusters = cl
    )
    combo_cols <- grep("^symptom_[0-9]+(_[0-9]+)+$", names(applied), value = TRUE)
    for (cc in combo_cols) {
      label <- paste0(rule, " (", gsub("_", ", ", sub("^symptom_", "", cc)), ")")
      comparison[[label]] <- applied[[cc]]
    }
  }

  if (isTRUE(include_icd11)) {
    comparison[["ICD-11"]] <- create_icd11_diagnosis(data)$PTSD_icd11
  }

  comparison %>%
    summarize_ptsd_changes() %>%
    create_readable_summary()
}
