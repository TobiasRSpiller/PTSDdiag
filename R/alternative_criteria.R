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
#' Any carry-through columns present in \code{data} (e.g. an ID column added
#' via \code{\link{rename_ptsd_columns}}) are prepended in original order so
#' results can be joined back to the source dataframe.
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
#' ptsd_data <- rename_ptsd_columns(simulated_ptsd,
#'                                   id_col = c("patient_id", "age", "sex"))
#' icd11_result <- create_icd11_diagnosis(ptsd_data)
#' head(icd11_result)
#'
#' # Feed directly into the metrics pipeline
#' metrics <- summarize_ptsd_changes(icd11_result)
#' create_readable_summary(metrics)
#'
create_icd11_diagnosis <- function(data) {
  .validate_pcl5_data(data, strict_cols = FALSE)

  carry_df <- .extract_carry_df(data)
  ptsd_orig <- create_ptsd_diagnosis_binarized(data)$PTSD_orig

  reexperiencing <- rowSums(data[, paste0("symptom_", c(1, 2, 3))]        >= 2) >= 1
  avoidance      <- rowSums(data[, paste0("symptom_", c(6, 7))]           >= 2) >= 1
  threat         <- rowSums(data[, paste0("symptom_", c(16, 17))]         >= 2) >= 1
  min_total      <- rowSums(data[, paste0("symptom_", c(1,2,3,6,7,16,17))] >= 2) >= 3

  result <- data.frame(
    PTSD_orig  = ptsd_orig,
    PTSD_icd11 = reexperiencing & avoidance & threat & min_total
  )
  .attach_carry_cols(result, carry_df)
}


#' Compute CAPS-5 DSM-5-TR PTSD diagnosis
#'
#' @description
#' Applies the DSM-5-TR PTSD diagnostic algorithm to CAPS-5
#' (Clinician-Administered PTSD Scale for DSM-5) item scores and returns a
#' single-column dataframe indicating diagnostic status. Because CAPS-5 uses the
#' same 20-item structure, 0--4 severity scale, and \eqn{\ge} 2 symptom-presence
#' threshold as the PCL-5, the diagnostic algorithm is identical.
#'
#' @details
#' The DSM-5-TR diagnostic criteria applied are:
#'
#' \itemize{
#'   \item Criterion B (Intrusion): \eqn{\ge} 1 of items 1--5 with severity
#'     \eqn{\ge} 2
#'   \item Criterion C (Avoidance): \eqn{\ge} 1 of items 6--7 with severity
#'     \eqn{\ge} 2
#'   \item Criterion D (Negative cognitions/mood): \eqn{\ge} 2 of items 8--14
#'     with severity \eqn{\ge} 2
#'   \item Criterion E (Arousal/reactivity): \eqn{\ge} 2 of items 15--20 with
#'     severity \eqn{\ge} 2
#' }
#'
#' All four criteria must be met for a positive diagnosis.
#'
#' Unlike \code{\link{create_icd11_diagnosis}}, this function returns only the
#' CAPS-5 diagnosis column (\code{PTSD_caps5}), not a PCL-5 reference column.
#' This is because the CAPS-5 diagnosis is typically used as the gold-standard
#' reference itself, not compared against a PCL-5 baseline.
#'
#' The returned dataframe can be passed to
#' \code{\link{compare_diagnostic_systems}} via its \code{caps5_data} parameter,
#' or used directly for descriptive analyses.
#'
#' @param data A dataframe containing exactly 20 columns of CAPS-5 item severity
#'   scores (output of \code{\link{rename_caps5_columns}}). Columns must be named
#'   \code{symptom_1} through \code{symptom_20}, scored on a 0--4 scale, with no
#'   missing values.
#'
#' @returns A \code{data.frame} with one logical column and one row per
#'   participant:
#'
#' \itemize{
#'   \item \code{PTSD_caps5}: CAPS-5 DSM-5-TR diagnosis
#' }
#'
#' Any carry-through columns present in \code{data} (e.g. an ID column added
#' via \code{\link{rename_caps5_columns}}) are prepended in original order.
#'
#' @seealso
#' \code{\link{rename_caps5_columns}} for standardizing CAPS-5 column names.
#'
#' \code{\link{compare_diagnostic_systems}} for comparing CAPS-5 against PCL-5
#' and optimized symptom combinations in a unified table.
#'
#' \code{\link{create_icd11_diagnosis}} for the ICD-11 alternative criteria.
#'
#' @export
#'
#' @examples
#' # Simulate CAPS-5 data (using same structure as PCL-5)
#' set.seed(42)
#' caps5_raw <- data.frame(matrix(sample(0:4, 400, replace = TRUE), ncol = 20))
#' caps5_data <- rename_caps5_columns(caps5_raw)
#' caps5_dx <- create_caps5_diagnosis(caps5_data)
#' head(caps5_dx)
#' table(caps5_dx$PTSD_caps5)
#'
create_caps5_diagnosis <- function(data) {
  .validate_pcl5_data(data, strict_cols = FALSE)
  carry_df <- .extract_carry_df(data)
  caps5_dx <- create_ptsd_diagnosis_binarized(data)$PTSD_orig
  .attach_carry_cols(data.frame(PTSD_caps5 = caps5_dx), carry_df)
}


#' Compare multiple diagnostic systems against a reference standard
#'
#' @description
#' Produces a single unified summary table comparing the diagnostic performance
#' of multiple criteria against a chosen reference standard. Suitable for use as
#' a manuscript table comparing optimized symptom combinations, ICD-11, CAPS-5,
#' and DSM-5-TR in one \code{\link[knitr]{kable}}-ready output.
#'
#' @details
#' The function:
#'
#' \enumerate{
#'   \item Computes the PCL-5 DSM-5-TR diagnosis from \code{data}
#'   \item If \code{caps5_data} is provided, computes the CAPS-5 DSM-5-TR
#'     diagnosis
#'   \item Sets the reference standard based on \code{reference}: either the
#'     PCL-5 or CAPS-5 DSM-5-TR diagnosis. The reference row always appears
#'     first with sensitivity = specificity = 1.
#'   \item Optionally computes ICD-11 diagnosis from \code{data} when
#'     \code{icd11 = TRUE}
#'   \item Collects all non-\code{PTSD_orig} columns from the \code{...}
#'     comparison dataframes (e.g. output of
#'     \code{\link{apply_symptom_combinations}})
#'   \item Calls \code{\link{summarize_ptsd_changes}} internally and reshapes
#'     the result into a presentation-ready table
#' }
#'
#' When \code{caps5_data} is \code{NULL} (default), labels follow the original
#' convention: \code{"DSM-5-TR"} and \code{"ICD-11"}. When \code{caps5_data}
#' is provided, labels are disambiguated with the instrument name:
#' \code{"DSM-5-TR (PCL-5)"}, \code{"DSM-5-TR (CAPS-5)"},
#' \code{"ICD-11 (PCL-5)"}.
#'
#' When \code{caps5_data} is provided, the strict \code{PTSD_orig} validation
#' on \code{...} inputs is relaxed to a row-count check only, because
#' comparison dataframes may have been derived from either the PCL-5 or CAPS-5
#' data (which produce different \code{PTSD_orig} vectors).
#'
#' @param data A dataframe containing exactly 20 columns of PCL-5 item scores
#'   (output of \code{\link{rename_ptsd_columns}}). Always required. Used to
#'   compute the PCL-5 DSM-5-TR diagnosis and, when \code{icd11 = TRUE}, the
#'   ICD-11 diagnosis.
#'
#' @param ... Zero or more comparison dataframes, each containing a
#'   \code{PTSD_orig} column and at least one additional logical column
#'   representing a diagnostic system (e.g. output of
#'   \code{\link{apply_symptom_combinations}}). When \code{caps5_data} is
#'   \code{NULL}, all \code{PTSD_orig} columns must be identical to the one
#'   computed from \code{data}. When \code{caps5_data} is provided, only
#'   row counts are validated.
#'
#' @param icd11 Logical. If \code{TRUE} (default), compute the ICD-11 PTSD
#'   diagnosis from \code{data} and include it as a row in the output.
#'
#' @param caps5_data Optional dataframe containing exactly 20 columns of CAPS-5
#'   item severity scores (output of \code{\link{rename_caps5_columns}}). Must
#'   have the same number of rows as \code{data} (paired participants). When
#'   provided, the CAPS-5 DSM-5-TR diagnosis is computed internally and
#'   included in the comparison.
#'
#' @param reference Character. Which DSM-5-TR diagnosis serves as the reference
#'   standard: \code{"pcl5"} (default) or \code{"caps5"}. The reference row
#'   always has sensitivity = specificity = 1 and zero misclassifications.
#'   Setting \code{reference = "caps5"} requires \code{caps5_data} to be
#'   provided.
#'
#' @param labels Optional character vector of display names for the systems
#'   coming from \code{...}, in the order the columns appear across all
#'   \code{...} inputs (excluding \code{PTSD_orig} columns). Does not apply to
#'   built-in rows (DSM-5-TR, ICD-11, CAPS-5), which are always labelled
#'   automatically. If \code{NULL} (default), column names are used. A warning
#'   is issued if the length does not match.
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
#'   \item \code{n_false_negative}: Cases missed vs. reference
#'   \item \code{pct_false_negative}: Percentage of total sample, 2 dp
#'   \item \code{n_false_positive}: Cases over-diagnosed vs. reference
#'   \item \code{pct_false_positive}: Percentage of total sample, 2 dp
#'   \item \code{n_misclassified}: Total misclassified cases
#' }
#'
#' @seealso
#' \code{\link{create_icd11_diagnosis}} for the ICD-11 comparison dataframe.
#'
#' \code{\link{create_caps5_diagnosis}} for standalone CAPS-5 diagnosis.
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
#' ptsd_data <- rename_ptsd_columns(simulated_ptsd,
#'                                   id_col = c("patient_id", "age", "sex"))
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
#'
#' # With CAPS-5 as gold standard reference
#' caps5_raw <- data.frame(matrix(sample(0:4, 20 * nrow(simulated_ptsd),
#'                                       replace = TRUE), ncol = 20))
#' caps5_data <- rename_caps5_columns(caps5_raw)
#' tbl3 <- compare_diagnostic_systems(
#'   ptsd_data, combos,
#'   icd11      = TRUE,
#'   caps5_data = caps5_data,
#'   reference  = "caps5"
#' )
#' knitr::kable(tbl3)
#' }
#'
compare_diagnostic_systems <- function(data, ..., icd11 = TRUE,
                                        caps5_data = NULL,
                                        reference = c("pcl5", "caps5"),
                                        labels = NULL) {
  reference <- match.arg(reference)

  # --- Validate primary PCL-5 data ---
  .validate_pcl5_data(data, strict_cols = FALSE)
  pcl5_orig <- create_ptsd_diagnosis_binarized(data)$PTSD_orig

  # --- Validate CAPS-5 data if provided ---
  caps5_orig <- NULL
  has_caps5  <- !is.null(caps5_data)

  if (has_caps5) {
    .validate_pcl5_data(caps5_data, strict_cols = FALSE)
    if (nrow(caps5_data) != nrow(data)) {
      cli::cli_abort(
        "{.arg caps5_data} has {nrow(caps5_data)} rows but {.arg data} has \\
        {nrow(data)} rows. Both must have the same number of participants."
      )
    }
    caps5_orig <- create_ptsd_diagnosis_binarized(caps5_data)$PTSD_orig
  }

  if (reference == "caps5" && !has_caps5) {
    cli::cli_abort(
      "{.arg caps5_data} is required when {.arg reference} is {.val caps5}."
    )
  }

  # --- Determine the reference vector ---
  if (reference == "pcl5") {
    ref_orig <- pcl5_orig
  } else {
    ref_orig <- caps5_orig
  }

  # --- Validate ... inputs ---
  dfs <- list(...)

  for (i in seq_along(dfs)) {
    if (!is.data.frame(dfs[[i]])) {
      cli::cli_abort("Argument {i + 1} is not a data.frame.")
    }
    if (!"PTSD_orig" %in% names(dfs[[i]])) {
      cli::cli_abort("Argument {i + 1} does not contain a 'PTSD_orig' column.")
    }
    if (has_caps5) {
      # Relaxed validation: only check row count matches
      if (nrow(dfs[[i]]) != length(ref_orig)) {
        cli::cli_abort(
          "Argument {i + 1} has {nrow(dfs[[i]])} rows but {.arg data} has \\
          {length(ref_orig)} rows."
        )
      }
    } else {
      # Strict validation: PTSD_orig must be identical
      if (!identical(ref_orig, dfs[[i]]$PTSD_orig)) {
        cli::cli_abort(
          "PTSD_orig in argument {i + 1} does not match the PTSD_orig \\
          computed from {.arg data}. Ensure all comparison dataframes were \\
          derived from the same dataset."
        )
      }
    }
  }

  # --- Collect extra (diagnostic) columns from ..., excluding carry-throughs
  # (ID-like non-symptom columns) which are not diagnostic systems.
  extra_cols <- unlist(lapply(dfs, function(df) {
    setdiff(names(df), c("PTSD_orig", .detect_carry_cols(df)))
  }))

  if (anyDuplicated(extra_cols)) {
    dup_names <- unique(extra_cols[duplicated(extra_cols)])
    cli::cli_abort(
      "Duplicate column names found across {.arg ...} inputs: \\
      {.val {dup_names}}. Rename columns before passing to \\
      {.fn compare_diagnostic_systems}."
    )
  }

  # --- Check that there is something to compare ---
  n_builtin <- as.integer(isTRUE(icd11)) + as.integer(has_caps5)
  if (n_builtin == 0 && length(extra_cols) == 0) {
    cli::cli_abort(
      "No diagnostic systems to compare. \\
      Pass at least one comparison dataframe via {.arg ...}, set \\
      {.arg icd11 = TRUE}, or provide {.arg caps5_data}."
    )
  }

  # --- Validate labels ---
  if (!is.null(labels) && length(labels) != length(extra_cols)) {
    cli::cli_warn(
      "{.arg labels} length ({length(labels)}) does not match the number of \\
      systems ({length(extra_cols)}). Using column names as fallback."
    )
    labels <- NULL
  }

  # --- Build combined data.frame ---
  combined <- data.frame(PTSD_orig = ref_orig)

  # Add the "other" instrument's DSM-5 diagnosis as a comparison column
  if (has_caps5) {
    if (reference == "pcl5") {
      combined$PTSD_caps5 <- caps5_orig
    } else {
      combined$PTSD_pcl5 <- pcl5_orig
    }
  }

  # Add ICD-11 (always from PCL-5 data)
  if (isTRUE(icd11)) {
    combined$PTSD_icd11 <- create_icd11_diagnosis(data)$PTSD_icd11
  }

  # Add columns from ... inputs (excluding carry-through ID columns)
  for (df in dfs) {
    df_carry <- .detect_carry_cols(df)
    for (col in setdiff(names(df), c("PTSD_orig", df_carry))) {
      combined[[col]] <- df[[col]]
    }
  }

  # --- Compute metrics ---
  raw     <- summarize_ptsd_changes(combined)
  n_total <- nrow(combined)

  # --- Build labels ---
  if (has_caps5) {
    builtin <- c(
      "PTSD_orig"  = if (reference == "pcl5") "DSM-5-TR (PCL-5)" else "DSM-5-TR (CAPS-5)",
      "PTSD_caps5" = "DSM-5-TR (CAPS-5)",
      "PTSD_pcl5"  = "DSM-5-TR (PCL-5)",
      "PTSD_icd11" = "ICD-11 (PCL-5)"
    )
  } else {
    builtin <- c("PTSD_orig" = "DSM-5-TR", "PTSD_icd11" = "ICD-11")
  }

  sys_labels <- raw$column
  for (nm in names(builtin)) {
    sys_labels[sys_labels == nm] <- builtin[[nm]]
  }
  if (!is.null(labels)) {
    non_builtin <- !raw$column %in% names(builtin)
    sys_labels[non_builtin] <- labels
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
