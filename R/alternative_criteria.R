#' Apply ICD-11 PTSD diagnostic criteria to PCL-5 data
#'
#' @description
#' Applies ICD-11 PTSD diagnostic criteria to PCL-5 item scores and returns a
#' comparison dataframe against the full DSM-5-TR criteria. The output is
#' directly compatible with \code{\link{summarize_ptsd_changes}} so that ICD-11
#' diagnostic accuracy can be computed on the same footing as optimized
#' symptom combinations.
#'
#' @details
#' ICD-11 PTSD requires ALL THREE of the following clusters to be met (symptom
#' present = score \eqn{\ge} 2 on original 0–4 scale):
#'
#' \enumerate{
#'   \item \strong{Re-experiencing} (in the present): \eqn{\ge} 1 of PCL-5
#'     items 1, 2, 3 (intrusive memories, nightmares, flashbacks)
#'   \item \strong{Avoidance}: \eqn{\ge} 1 of PCL-5 items 6, 7
#'   \item \strong{Sense of current threat}: \eqn{\ge} 1 of PCL-5 items 16, 17
#'     (hypervigilance, exaggerated startle)
#' }
#'
#' A minimum of 3 symptoms total across all ICD-11 items (1, 2, 3, 6, 7, 16,
#' 17) must be present. This is automatically satisfied when all three cluster
#' requirements are met but is enforced explicitly for clarity.
#'
#' DSM-5-TR diagnosis (\code{PTSD_orig}) is computed using the same binarization
#' logic as the rest of the package (\code{\link{create_ptsd_diagnosis_binarized}}).
#'
#' @param data A dataframe containing exactly 20 columns of PCL-5 item scores
#'   (output of \code{\link{rename_ptsd_columns}}). Columns must be named
#'   \code{symptom_1} through \code{symptom_20}, scored on a 0–4 scale, with
#'   no missing values.
#'
#' @returns A \code{data.frame} with two logical columns and one row per
#'   participant:
#'
#' \itemize{
#'   \item \code{PTSD_orig}: DSM-5-TR diagnosis (reference standard)
#'   \item \code{PTSD_icd11}: ICD-11 diagnosis
#' }
#'
#' This dataframe can be passed directly to \code{\link{summarize_ptsd_changes}}
#' or used as an input to \code{\link{compare_diagnostic_systems}}.
#'
#' @seealso
#' \code{\link{compare_diagnostic_systems}} for a unified cross-system
#' comparison table.
#'
#' \code{\link{summarize_ptsd_changes}} and \code{\link{create_readable_summary}}
#' for computing and formatting diagnostic metrics.
#'
#' @export
#'
#' @examples
#' # Apply ICD-11 criteria to the built-in simulated dataset
#' ptsd_data <- rename_ptsd_columns(simulated_ptsd)
#' icd11_result <- create_icd11_diagnosis(ptsd_data)
#' head(icd11_result)
#'
#' # Feed directly into the metrics pipeline
#' metrics <- summarize_ptsd_changes(icd11_result)
#' create_readable_summary(metrics)
#'
create_icd11_diagnosis <- function(data) {
  .validate_pcl5_data(data)

  ptsd_orig <- create_ptsd_diagnosis_binarized(data)$PTSD_orig

  reexperiencing <- rowSums(data[, paste0("symptom_", c(1, 2, 3))]        >= 2) >= 1
  avoidance      <- rowSums(data[, paste0("symptom_", c(6, 7))]           >= 2) >= 1
  threat         <- rowSums(data[, paste0("symptom_", c(16, 17))]         >= 2) >= 1
  min_total      <- rowSums(data[, paste0("symptom_", c(1,2,3,6,7,16,17))] >= 2) >= 3

  data.frame(
    PTSD_orig  = ptsd_orig,
    PTSD_icd11 = reexperiencing & avoidance & threat & min_total
  )
}


#' Compare multiple diagnostic systems against DSM-5-TR
#'
#' @description
#' Produces a single unified summary table comparing the diagnostic performance
#' of multiple criteria against DSM-5-TR as the reference standard. Suitable
#' for use as a manuscript table (e.g., Table 2) comparing optimized symptom
#' combinations, ICD-11, and DSM-5-TR in one \code{\link[knitr]{kable}}-ready
#' output.
#'
#' @details
#' The function:
#'
#' \enumerate{
#'   \item Computes the DSM-5-TR reference diagnosis (\code{PTSD_orig}) from
#'     \code{data} — this always appears as the first row in the output
#'   \item Optionally computes ICD-11 diagnosis from \code{data} when
#'     \code{icd11 = TRUE}
#'   \item Collects all non-\code{PTSD_orig} columns from the \code{...}
#'     comparison dataframes (e.g. output of
#'     \code{\link{apply_symptom_combinations}})
#'   \item Validates that every \code{PTSD_orig} column in \code{...} is
#'     identical to the reference computed from \code{data}
#'   \item Calls \code{\link{summarize_ptsd_changes}} internally and reshapes
#'     the result into a presentation-ready table
#' }
#'
#' Built-in display labels: \code{PTSD_orig} → \code{"DSM-5-TR"},
#' \code{PTSD_icd11} → \code{"ICD-11"}. These are applied automatically.
#' Use the \code{labels} argument to rename the remaining systems.
#'
#' @param data A dataframe containing exactly 20 columns of PCL-5 item scores
#'   (output of \code{\link{rename_ptsd_columns}}). Used to compute both the
#'   DSM-5-TR reference diagnosis and, when \code{icd11 = TRUE}, the ICD-11
#'   diagnosis.
#'
#' @param ... Zero or more comparison dataframes, each containing a
#'   \code{PTSD_orig} column and at least one additional logical column
#'   representing a diagnostic system (e.g. output of
#'   \code{\link{apply_symptom_combinations}}). All \code{PTSD_orig} columns
#'   must be identical to the one computed from \code{data}.
#'
#' @param icd11 Logical. If \code{TRUE} (default), compute the ICD-11 PTSD
#'   diagnosis from \code{data} and include it as a row in the output, labelled
#'   \code{"ICD-11"}. Set to \code{FALSE} to omit ICD-11.
#'
#' @param labels Optional character vector of display names for the systems
#'   coming from \code{...}, in the order the columns appear across all
#'   \code{...} inputs (excluding \code{PTSD_orig} columns). Does not apply to
#'   the \code{"DSM-5-TR"} or \code{"ICD-11"} rows, which are always labelled
#'   automatically. If \code{NULL} (default), column names are used. A warning
#'   is issued if the length of \code{labels} does not match the number of
#'   systems and column names are used as a fallback.
#'
#' @returns A \code{data.frame} with one row per diagnostic system and the
#'   following columns:
#'
#' \itemize{
#'   \item \code{system}: Display name of the diagnostic criterion
#'   \item \code{n_diagnosed}: Number of cases meeting the criterion
#'   \item \code{pct_diagnosed}: Percentage of total sample diagnosed (2 dp)
#'   \item \code{sensitivity}: 4 dp
#'   \item \code{specificity}: 4 dp
#'   \item \code{ppv}: Positive predictive value, 4 dp
#'   \item \code{npv}: Negative predictive value, 4 dp
#'   \item \code{n_false_negative}: Cases missed vs. DSM-5-TR
#'   \item \code{pct_false_negative}: Percentage of total sample, 2 dp
#'   \item \code{n_false_positive}: Cases over-diagnosed vs. DSM-5-TR
#'   \item \code{pct_false_positive}: Percentage of total sample, 2 dp
#'   \item \code{n_misclassified}: Total misclassified cases
#' }
#'
#' The DSM-5-TR reference row has sensitivity = specificity = 1.0000 and all
#' misclassification counts = 0 by definition.
#'
#' @seealso
#' \code{\link{create_icd11_diagnosis}} for the ICD-11 comparison dataframe.
#'
#' \code{\link{apply_symptom_combinations}} for generating comparison dataframes
#' from optimized symptom combinations.
#'
#' \code{\link{optimize_combinations}} and
#' \code{\link{optimize_combinations_clusters}} for deriving optimal combinations.
#'
#' @export
#'
#' @examples
#' ptsd_data <- rename_ptsd_columns(simulated_ptsd)
#'
#' # ICD-11 vs DSM-5-TR only (no optimized combinations)
#' tbl <- compare_diagnostic_systems(ptsd_data, icd11 = TRUE)
#' tbl
#'
#' \donttest{
#' # Add two pre-specified combinations
#' combos <- apply_symptom_combinations(
#'   ptsd_data,
#'   combinations = list(c(1, 6, 8, 10, 15, 19), c(2, 7, 9, 11, 16, 20)),
#'   n_required = 4
#' )
#' tbl2 <- compare_diagnostic_systems(
#'   ptsd_data, combos,
#'   icd11  = TRUE,
#'   labels = c("Combo A", "Combo B")
#' )
#' knitr::kable(tbl2)
#' }
#'
compare_diagnostic_systems <- function(data, ..., icd11 = TRUE, labels = NULL) {
  .validate_pcl5_data(data)
  ref_orig <- create_ptsd_diagnosis_binarized(data)$PTSD_orig

  dfs <- list(...)

  for (i in seq_along(dfs)) {
    if (!is.data.frame(dfs[[i]])) {
      cli::cli_abort("Argument {i + 1} is not a data.frame.")
    }
    if (!"PTSD_orig" %in% names(dfs[[i]])) {
      cli::cli_abort("Argument {i + 1} does not contain a 'PTSD_orig' column.")
    }
    if (!identical(ref_orig, dfs[[i]]$PTSD_orig)) {
      cli::cli_abort(
        "PTSD_orig in argument {i + 1} does not match the PTSD_orig \\
        computed from {.arg data}. Ensure all comparison dataframes were \\
        derived from the same dataset."
      )
    }
  }

  extra_cols <- unlist(lapply(dfs, function(df) setdiff(names(df), "PTSD_orig")))

  if (!isTRUE(icd11) && length(extra_cols) == 0) {
    cli::cli_abort(
      "No diagnostic systems to compare. \\
      Pass at least one comparison dataframe via {.arg ...} or set {.arg icd11 = TRUE}."
    )
  }

  if (!is.null(labels) && length(labels) != length(extra_cols)) {
    cli::cli_warn(
      "{.arg labels} length ({length(labels)}) does not match the number of \\
      systems ({length(extra_cols)}). Using column names as fallback."
    )
    labels <- NULL
  }

  combined <- data.frame(PTSD_orig = ref_orig)
  if (isTRUE(icd11)) {
    combined$PTSD_icd11 <- create_icd11_diagnosis(data)$PTSD_icd11
  }
  for (df in dfs) {
    for (col in setdiff(names(df), "PTSD_orig")) {
      combined[[col]] <- df[[col]]
    }
  }

  raw     <- summarize_ptsd_changes(combined)
  n_total <- nrow(combined)

  builtin    <- c("PTSD_orig" = "DSM-5-TR", "PTSD_icd11" = "ICD-11")
  sys_labels <- raw$column
  for (nm in names(builtin)) {
    sys_labels[sys_labels == nm] <- builtin[[nm]]
  }
  if (!is.null(labels)) {
    sys_labels[!raw$column %in% c("PTSD_orig", "PTSD_icd11")] <- labels
  }

  data.frame(
    system             = sys_labels,
    n_diagnosed        = raw$diagnosed,
    pct_diagnosed      = raw$diagnosed_percent,
    sensitivity        = round(raw$sensitivity,                          4),
    specificity        = round(raw$specificity,                          4),
    ppv                = round(raw$ppv,                                  4),
    npv                = round(raw$npv,                                  4),
    n_false_negative   = raw$newly_nondiagnosed,
    pct_false_negative = round(raw$newly_nondiagnosed / n_total * 100,   2),
    n_false_positive   = raw$newly_diagnosed,
    pct_false_positive = round(raw$newly_diagnosed    / n_total * 100,   2),
    n_misclassified    = raw$false_cases,
    stringsAsFactors   = FALSE
  )
}
