#' Rename PTSD symptom (= PCL-5 item) columns
#'
#' @description
#' Standardizes column names in PCL-5 (PTSD Checklist for DSM-5) data by renaming
#' them to a consistent format (symptom_1 through symptom_20). This standardization
#' is essential for subsequent analyses using other functions in the package.
#'
#' @details
#' The function assumes the input data contains exactly 20 columns corresponding to
#' the 20 items of the PCL-5. The columns are renamed sequentially from symptom_1
#' to symptom_20, maintaining their original order. The PCL-5 items correspond to
#' different symptom clusters:
#'
#' \itemize{
#' \item symptom_1 to symptom_5: Intrusion symptoms (Criterion B)
#' \item symptom_6 to symptom_7: Avoidance symptoms (Criterion C)
#' \item symptom_8 to symptom_14: Negative alterations in cognitions and mood (Criterion D)
#' \item symptom_15 to symptom_20: Alterations in arousal and reactivity (Criterion E)
#'}
#'
#' @param data A dataframe containing exactly 20 columns, where each column
#'   represents a PCL-5 item score. The scores should be on a 0-4 scale where:
#'
#' \itemize{
#'   \item 0 = Not at all
#'   \item 1 = A little bit
#'   \item 2 = Moderately
#'   \item 3 = Quite a bit
#'   \item 4 = Extremely
#'}
#'
#' @returns A dataframe with the same data but renamed columns following the pattern
#'   'symptom_1' through 'symptom_20'
#'
#' @export
#'
#' @importFrom dplyr rename_with
#' @importFrom magrittr %>%
#'
#' @examples
#' # Example with a sample PCL-5 dataset
#' sample_data <- data.frame(
#'   matrix(sample(0:4, 20 * 10, replace = TRUE),
#'          nrow = 10,
#'          ncol = 20)
#' )
#' renamed_data <- rename_ptsd_columns(sample_data)
#' colnames(renamed_data)  # Shows new column names
#'
rename_ptsd_columns <- function(data) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame, not {.cls {class(data)}}.")
  }
  if (ncol(data) != 20) {
    cli::cli_abort(c(
      "{.arg data} must contain exactly 20 columns (one for each PCL-5 item).",
      "x" = "Got {ncol(data)} column{?s}."
    ))
  }

  renamed <- data
  names(renamed) <- paste0("symptom_", 1:20)
  .validate_pcl5_data(renamed, warn_total = FALSE)

  data %>%
      rename_with(~ paste0("symptom_", 1:20))
}


#' Rename CAPS-5 symptom columns
#'
#' @description
#' Standardizes column names in CAPS-5 (Clinician-Administered PTSD Scale for
#' DSM-5) data by renaming them to a consistent format (\code{symptom_1} through
#' \code{symptom_20}). This standardization allows CAPS-5 data to be used with
#' the same downstream functions as PCL-5 data (e.g.,
#' \code{\link{create_caps5_diagnosis}}, \code{\link{apply_symptom_combinations}}).
#'
#' @details
#' The function assumes the input data contains exactly 20 columns corresponding
#' to the 20 CAPS-5 items. Each item is a single severity rating (0--4) assigned
#' by the clinician, who combines information about frequency and intensity into
#' that score. The columns are renamed sequentially from \code{symptom_1} to
#' \code{symptom_20}, maintaining their original order.
#'
#' The CAPS-5 items map to the same DSM-5 PTSD symptom clusters as the PCL-5:
#'
#' \itemize{
#'   \item symptom_1 to symptom_5: Intrusion symptoms (Criterion B)
#'   \item symptom_6 to symptom_7: Avoidance symptoms (Criterion C)
#'   \item symptom_8 to symptom_14: Negative alterations in cognitions and mood
#'     (Criterion D)
#'   \item symptom_15 to symptom_20: Alterations in arousal and reactivity
#'     (Criterion E)
#' }
#'
#' The output naming (\code{symptom_1:symptom_20}) is intentionally identical to
#' the PCL-5 convention so that downstream functions such as
#' \code{\link{apply_symptom_combinations}} and
#' \code{\link{compare_diagnostic_systems}} work transparently on CAPS-5 data.
#'
#' @param data A dataframe containing exactly 20 columns, where each column
#'   represents a CAPS-5 item severity rating. Scores are on a 0--4 scale where:
#'
#' \itemize{
#'   \item 0 = Absent
#'   \item 1 = Mild / subthreshold
#'   \item 2 = Moderate / threshold (counts toward diagnosis)
#'   \item 3 = Severe / markedly elevated
#'   \item 4 = Extreme / incapacitating
#' }
#'
#' @returns A dataframe with the same data but renamed columns following the
#'   pattern \code{symptom_1} through \code{symptom_20}.
#'
#' @seealso
#' \code{\link{rename_ptsd_columns}} for the PCL-5 equivalent.
#'
#' \code{\link{create_caps5_diagnosis}} for computing a CAPS-5 DSM-5 diagnosis
#' from the renamed data.
#'
#' @export
#'
#' @importFrom dplyr rename_with
#' @importFrom magrittr %>%
#'
#' @examples
#' # Example with simulated CAPS-5 data
#' caps5_data <- data.frame(
#'   matrix(sample(0:4, 20 * 10, replace = TRUE),
#'          nrow = 10,
#'          ncol = 20)
#' )
#' renamed_caps5 <- rename_caps5_columns(caps5_data)
#' colnames(renamed_caps5)  # symptom_1 through symptom_20
#'
rename_caps5_columns <- function(data) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame, not {.cls {class(data)}}.")
  }
  if (ncol(data) != 20) {
    cli::cli_abort(c(
      "{.arg data} must contain exactly 20 columns (one for each CAPS-5 item).",
      "x" = "Got {ncol(data)} column{?s}."
    ))
  }

  renamed <- data
  names(renamed) <- paste0("symptom_", 1:20)
  .validate_pcl5_data(renamed, warn_total = FALSE, instrument = "CAPS-5")

  data %>%
    rename_with(~ paste0("symptom_", 1:20))
}
