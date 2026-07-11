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
#' @param data A dataframe containing exactly 20 columns of PCL-5 item scores
#'   (plus any columns named in \code{id_col} for carry-through). The scores
#'   should be on a 0-4 scale where:
#'
#' \itemize{
#'   \item 0 = Not at all
#'   \item 1 = A little bit
#'   \item 2 = Moderately
#'   \item 3 = Quite a bit
#'   \item 4 = Extremely
#'}
#'
#' @param id_col Optional character vector naming column(s) in \code{data} to
#'   preserve as identifiers. These columns are kept alongside the renamed
#'   symptom columns and propagate through the rest of the workflow
#'   (\code{\link{optimize_combinations}}, \code{\link{apply_symptom_combinations}},
#'   \code{\link{holdout_validation}}, \code{\link{cross_validation}}). Use
#'   them as a join key to merge per-row diagnoses back to the original
#'   dataframe (e.g. demographics). Defaults to \code{NULL} (no carry-through;
#'   all non-symptom columns are dropped).
#'
#' @returns A dataframe with PCL-5 columns renamed to \code{symptom_1} through
#'   \code{symptom_20}. If \code{id_col} is supplied, the named columns are
#'   prepended (in original order).
#'
#' @seealso \code{\link{check_pcl5_data}} for a pre-flight check that reports
#'   every data problem at once before this step.
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
#' # Carry a participant identifier through the workflow
#' sample_data$patient_id <- sprintf("P%03d", seq_len(nrow(sample_data)))
#' with_id <- rename_ptsd_columns(sample_data, id_col = "patient_id")
#' head(with_id)
#'
rename_ptsd_columns <- function(data, id_col = NULL) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame, not {.cls {class(data)}}.")
  }

  .validate_id_col(data, id_col)

  id_df <- if (is.null(id_col)) NULL else data[, id_col, drop = FALSE]
  symptoms_only <- data[, setdiff(names(data), id_col), drop = FALSE]

  if (ncol(symptoms_only) != 20) {
    cli::cli_abort(c(
      "{.arg data} must contain exactly 20 PCL-5 item columns (excluding {.arg id_col}).",
      "x" = "Got {ncol(symptoms_only)} non-ID column{?s}.",
      "i" = "{.fn rename_ptsd_columns} renames the non-ID columns \\
            {.strong positionally}, not by name. Either drop the unrelated \\
            columns or list them in {.arg id_col} so they ride alongside \\
            without being renamed.",
      "i" = "Example: {.code rename_ptsd_columns(data, id_col = c(\"patient_id\", \"age\", \"sex\"))}."
    ))
  }

  renamed <- symptoms_only
  names(renamed) <- paste0("symptom_", 1:20)
  .validate_pcl5_data(renamed, warn_total = FALSE)

  if (is.null(id_df)) {
    return(renamed)
  }
  cbind(id_df, renamed, stringsAsFactors = FALSE)
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
#' @param data A dataframe containing exactly 20 columns of CAPS-5 item severity
#'   ratings (plus any columns named in \code{id_col} for carry-through). Scores
#'   are on a 0--4 scale where:
#'
#' \itemize{
#'   \item 0 = Absent
#'   \item 1 = Mild / subthreshold
#'   \item 2 = Moderate / threshold (counts toward diagnosis)
#'   \item 3 = Severe / markedly elevated
#'   \item 4 = Extreme / incapacitating
#' }
#'
#' @param id_col Optional character vector naming column(s) in \code{data} to
#'   preserve as identifiers. These columns propagate through the workflow and
#'   can be used to merge per-row diagnoses back to the original dataframe.
#'   Defaults to \code{NULL}.
#'
#' @returns A dataframe with CAPS-5 columns renamed to \code{symptom_1} through
#'   \code{symptom_20}. If \code{id_col} is supplied, the named columns are
#'   prepended (in original order).
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
rename_caps5_columns <- function(data, id_col = NULL) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame, not {.cls {class(data)}}.")
  }

  .validate_id_col(data, id_col)

  id_df <- if (is.null(id_col)) NULL else data[, id_col, drop = FALSE]
  symptoms_only <- data[, setdiff(names(data), id_col), drop = FALSE]

  if (ncol(symptoms_only) != 20) {
    cli::cli_abort(c(
      "{.arg data} must contain exactly 20 CAPS-5 item columns (excluding {.arg id_col}).",
      "x" = "Got {ncol(symptoms_only)} non-ID column{?s}.",
      "i" = "{.fn rename_caps5_columns} renames the non-ID columns \\
            {.strong positionally}, not by name. Either drop the unrelated \\
            columns or list them in {.arg id_col} so they ride alongside \\
            without being renamed."
    ))
  }

  renamed <- symptoms_only
  names(renamed) <- paste0("symptom_", 1:20)
  .validate_pcl5_data(renamed, warn_total = FALSE, instrument = "CAPS-5")

  if (is.null(id_df)) {
    return(renamed)
  }
  cbind(id_df, renamed, stringsAsFactors = FALSE)
}


#' Check PCL-5 item data before starting the workflow
#'
#' @description
#' Pre-flight check for a data frame of PCL-5 item scores. Unlike the
#' fail-fast validation inside the workflow functions, this check runs
#' \strong{all} checks and reports every problem at once -- column count,
#' numeric type, the integer 0-4 scoring range, and missing values -- so a
#' data file can be fixed in one pass instead of one error at a time. Run it
#' on your item columns before \code{\link{rename_ptsd_columns}}.
#'
#' @details
#' Two input shapes are supported. If \code{data} already contains the renamed
#' columns \code{symptom_1} through \code{symptom_20}, those are checked by
#' name (extra columns such as \code{total} are ignored). Otherwise all
#' non-\code{id_col} columns are treated as the item columns in positional
#' DSM-5 order, exactly as \code{\link{rename_ptsd_columns}} will interpret
#' them -- the check then also requires that there are exactly 20 of them.
#'
#' Rows in which every item is 0 are reported as an informational note, not an
#' error: whether symptom-free records are kept (e.g. to contribute true
#' negatives in a validation sample) or excluded is an analytic choice.
#'
#' @param data A data frame containing the PCL-5 item columns (plus any
#'   columns named in \code{id_col}).
#' @param id_col Optional character vector naming identifier column(s) to
#'   exclude from the check, mirroring \code{\link{rename_ptsd_columns}}.
#'
#' @returns \code{invisible(TRUE)} when every check passes; otherwise the
#'   function aborts with a report listing all failed checks.
#'
#' @seealso \code{\link{rename_ptsd_columns}}, which this check prepares for.
#'
#' @export
#'
#' @examples
#' # Clean data passes and reports each check
#' ptsd_items <- simulated_ptsd[1:100, paste0("S", 1:20)]
#' check_pcl5_data(ptsd_items)
#'
#' # A data frame with several problems reports them all in one error
#' bad <- ptsd_items
#' bad$extra_column <- 1          # 21 item columns
#' bad$S3[5] <- NA                # a missing value
#' bad$S7[2] <- 9                 # out of the 0-4 range
#' try(check_pcl5_data(bad))
check_pcl5_data <- function(data, id_col = NULL) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame, not {.cls {class(data)}}.")
  }
  .validate_id_col(data, id_col)

  expected_cols <- paste0("symptom_", 1:20)
  by_name <- all(expected_cols %in% names(data))

  report <- character(0)

  if (by_name) {
    items <- data[, expected_cols, drop = FALSE]
    report <- c(report, "v" = "Found the 20 renamed item columns \\
                ({.code symptom_1} to {.code symptom_20}); checking them by name.")
  } else {
    items <- data[, setdiff(names(data), id_col), drop = FALSE]
    n_items <- ncol(items)
    if (n_items == 20) {
      report <- c(report, "v" = "Found exactly 20 non-ID columns; checking \\
                  them positionally (DSM-5 item order assumed).")
    } else {
      report <- c(report, "x" = "Expected exactly 20 item columns after \\
                  excluding {.arg id_col}; got {n_items}.")
    }
  }

  n_rows <- nrow(data)
  if (n_rows == 0) {
    report <- c(report, "x" = "{.arg data} must contain at least one row.")
  } else {
    report <- c(report, "v" = "{n_rows} row{?s}.")
  }

  non_numeric_cols <- names(items)[!vapply(items, is.numeric, logical(1))]
  if (length(non_numeric_cols) == 0) {
    report <- c(report, "v" = "All item columns are numeric.")
  } else {
    report <- c(report, "x" = "{cli::qty(length(non_numeric_cols))}\\
                Non-numeric item column{?s}: {.val {non_numeric_cols}}.")
  }

  num_items <- items[, setdiff(names(items), non_numeric_cols), drop = FALSE]

  if (ncol(num_items) > 0 && n_rows > 0) {
    na_by_col <- vapply(num_items, function(x) sum(is.na(x)), integer(1))
    if (sum(na_by_col) == 0) {
      report <- c(report, "v" = "No missing values.")
    } else {
      na_total <- sum(na_by_col)
      na_cols  <- names(na_by_col)[na_by_col > 0]
      na_rows  <- utils::head(which(rowSums(is.na(num_items)) > 0), 5)
      report <- c(report, "x" = "{na_total} missing value{?s} in \\
                  {.val {na_cols}} (first affected \\
                  {cli::qty(length(na_rows))}row{?s}: {na_rows}).")
    }

    is_bad_value <- function(x) !is.na(x) & (x < 0 | x > 4 | x != floor(x))
    bad_value_cols <- names(num_items)[vapply(num_items, function(x)
      any(is_bad_value(x)), logical(1))]
    if (length(bad_value_cols) == 0) {
      report <- c(report, "v" = "All scores are integers between 0 and 4.")
    } else {
      bad_value_examples <- utils::head(
        sort(unique(unlist(lapply(num_items[bad_value_cols], function(x)
          x[is_bad_value(x)])))), 5)
      report <- c(report, "x" = "{cli::qty(length(bad_value_cols))}Column{?s} \\
                  {.val {bad_value_cols}} {cli::qty(length(bad_value_cols))}\\
                  {?contains/contain} values outside the integer 0-4 range \\
                  (e.g. {bad_value_examples}).")
    }

    if (length(non_numeric_cols) == 0 && ncol(num_items) == 20 &&
        sum(na_by_col) == 0) {
      n_all_zero <- sum(rowSums(num_items != 0) == 0)
      if (n_all_zero > 0) {
        report <- c(report, "i" = "{n_all_zero} row{?s} have all items = 0. \\
                    Some analyses exclude symptom-free records; this is an \\
                    analytic choice, not an error.")
      }
    }
  }

  if (any(names(report) == "x")) {
    cli::cli_abort(c(
      "{.arg data} is not ready for the PTSDdiag workflow.",
      report
    ))
  }

  cli::cli_bullets(report)
  cli::cli_alert_success("All checks passed -- data ready for the PTSDdiag workflow.")
  invisible(TRUE)
}
