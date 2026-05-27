#' Build a tidy comparison table of top combinations across scenarios
#'
#' @description
#' Produces a manuscript-ready table summarising the diagnostic performance of
#' each top combination (or fixed criterion) in a
#' \code{\link{compare_optimizations}} result. The output matches the layout
#' of the PTSDdiag preprint's Table 2: one row per combination, with
#' Approach / Rank / Combination / TP / FN / FP / TN / Sensitivity /
#' Specificity / PPV / NPV.
#'
#' @details
#' For each scenario, the per-row \code{diagnosis_comparison} dataframe is
#' summarised via \code{\link{summarize_ptsd_changes}}. The self-comparison
#' \code{PTSD_orig} row is dropped, the remaining rows are renamed, and the
#' scenario label is prepended.
#'
#' Sensitivity, specificity, PPV and NPV are returned on the 0-1 fraction
#' scale by default (matching \code{\link{compare_diagnostic_systems}});
#' set \code{as_percent = TRUE} to convert to 0-100 for manuscript display.
#'
#' @param comparison A \code{ptsdiag_comparison} object.
#' @param top_n Optional integer. Per-scenario limit on combinations to
#'   include. Fixed scenarios always contribute exactly one row. Default
#'   \code{NULL} returns all stored combinations.
#' @param as_percent Logical. If \code{TRUE}, Sensitivity/Specificity/PPV/NPV
#'   are returned as percentages (0-100); otherwise as fractions (0-1).
#'   Default \code{FALSE}.
#'
#' @returns A data.frame with columns: \code{Approach}, \code{Rank},
#'   \code{Combination}, \code{TP}, \code{FN}, \code{FP}, \code{TN},
#'   \code{Sensitivity}, \code{Specificity}, \code{PPV}, \code{NPV}.
#'
#' @seealso \code{\link{compare_optimizations}},
#'   \code{\link{symptom_frequency}},
#'   \code{\link{plot_symptom_frequency}}.
#'
#' @export
#'
#' @examples
#' \donttest{
#' ptsd_data <- rename_ptsd_columns(simulated_ptsd)
#' comp <- compare_optimizations(ptsd_data, n_top = 5, show_progress = FALSE)
#' summarize_top_combinations(comp, as_percent = TRUE)
#' }
summarize_top_combinations <- function(comparison, top_n = NULL,
                                       as_percent = FALSE) {
  if (!inherits(comparison, "ptsdiag_comparison")) {
    cli::cli_abort(
      "{.arg comparison} must be a {.cls ptsdiag_comparison} object \\
       (from {.fn compare_optimizations})."
    )
  }
  if (!is.null(top_n)) {
    if (!is.numeric(top_n) || length(top_n) != 1 || top_n != floor(top_n) ||
        top_n < 1) {
      cli::cli_abort("{.arg top_n} must be a single positive integer or {.code NULL}.")
    }
    top_n <- as.integer(top_n)
  }
  if (!is.logical(as_percent) || length(as_percent) != 1) {
    cli::cli_abort("{.arg as_percent} must be a single logical.")
  }

  rows <- list()

  for (label in names(comparison$scenarios)) {
    res  <- comparison$scenarios[[label]]
    type <- attr(res, "type")
    cmp  <- res$diagnosis_comparison

    # Keep only logical columns -- summarize_ptsd_changes filters them too, but
    # we need to know which output columns correspond to combinations.
    logical_cols <- vapply(cmp, is.logical, logical(1))
    cmp_logical  <- cmp[, logical_cols, drop = FALSE]

    stats <- summarize_ptsd_changes(cmp_logical)
    stats <- stats[stats$column != "PTSD_orig", , drop = FALSE]

    # Preserve column order (= rank order of combinations).
    combo_order <- setdiff(names(cmp_logical), "PTSD_orig")
    stats <- stats[match(combo_order, stats$column), , drop = FALSE]

    if (!is.null(top_n) && identical(type, "optimize")) {
      stats <- utils::head(stats, top_n)
    }

    n <- nrow(stats)
    if (n == 0) next

    out <- data.frame(
      Approach    = label,
      Rank        = seq_len(n),
      Combination = stats$column,
      TP          = stats$true_positive,
      FN          = stats$newly_nondiagnosed,
      FP          = stats$newly_diagnosed,
      TN          = stats$true_negative,
      Sensitivity = stats$sensitivity,
      Specificity = stats$specificity,
      PPV         = stats$ppv,
      NPV         = stats$npv,
      stringsAsFactors = FALSE
    )
    if (isTRUE(as_percent)) {
      out$Sensitivity <- out$Sensitivity * 100
      out$Specificity <- out$Specificity * 100
      out$PPV         <- out$PPV         * 100
      out$NPV         <- out$NPV         * 100
    }
    rows[[label]] <- out
  }

  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}


#' Per-symptom inclusion counts across optimization scenarios
#'
#' @description
#' Returns a long-format data frame giving how often each of the 20 PCL-5
#' symptoms appears in the top combinations of each scenario in a
#' \code{\link{compare_optimizations}} result. This is the data source for
#' \code{\link{plot_symptom_frequency}} and matches the structure of the
#' preprint's Supplementary Table S4.
#'
#' @details
#' For optimize scenarios, \code{Count} ranges from 0 to \code{n_top} (the
#' number of stored combinations). For fixed scenarios such as ICD-11, the
#' fixed symptom set contributes exactly one combination so \code{Count} is
#' either 0 or 1. \code{RelFreq} normalises \code{Count} by the number of
#' combinations stored in that scenario.
#'
#' The optional \code{OVERALL} row pools counts across scenarios. By default
#' fixed scenarios are excluded from the OVERALL pool so that OVERALL
#' continues to reflect data-driven symptom selection. Set
#' \code{overall_includes_fixed = TRUE} to weight every combination equally.
#'
#' @param comparison A \code{ptsdiag_comparison} object.
#' @param include_overall Logical. If \code{TRUE} (default), an \code{OVERALL}
#'   row is appended that pools across scenarios.
#' @param overall_includes_fixed Logical. If \code{TRUE}, fixed criteria
#'   contribute to the OVERALL row. Default \code{FALSE}.
#'
#' @returns A data.frame with columns \code{Symptom} (integer 1-20),
#'   \code{Approach} (factor with levels in scenario order, optionally ending
#'   in \code{"OVERALL"}), \code{Count} (integer), \code{RelFreq} (numeric in
#'   \[0, 1\]).
#'
#' @seealso \code{\link{compare_optimizations}},
#'   \code{\link{plot_symptom_frequency}},
#'   \code{\link{summarize_top_combinations}}.
#'
#' @export
#'
#' @examples
#' \donttest{
#' ptsd_data <- rename_ptsd_columns(simulated_ptsd)
#' comp <- compare_optimizations(ptsd_data, n_top = 5, show_progress = FALSE)
#' freq <- symptom_frequency(comp)
#' head(freq)
#' }
symptom_frequency <- function(comparison,
                              include_overall       = TRUE,
                              overall_includes_fixed = FALSE) {
  if (!inherits(comparison, "ptsdiag_comparison")) {
    cli::cli_abort(
      "{.arg comparison} must be a {.cls ptsdiag_comparison} object \\
       (from {.fn compare_optimizations})."
    )
  }
  if (!is.logical(include_overall) || length(include_overall) != 1) {
    cli::cli_abort("{.arg include_overall} must be a single logical.")
  }
  if (!is.logical(overall_includes_fixed) || length(overall_includes_fixed) != 1) {
    cli::cli_abort("{.arg overall_includes_fixed} must be a single logical.")
  }

  scenarios <- comparison$scenarios
  labels    <- names(scenarios)
  symptoms  <- 1:20

  per_scen <- vector("list", length(scenarios))
  totals   <- integer(20)
  total_n  <- 0L

  for (i in seq_along(scenarios)) {
    res   <- scenarios[[i]]
    type  <- attr(res, "type")
    combos <- res$best_symptoms
    n_combos <- length(combos)
    counts <- integer(20)
    for (combo in combos) {
      counts[combo] <- counts[combo] + 1L
    }
    rel <- if (n_combos == 0) rep(0, 20) else counts / n_combos
    per_scen[[i]] <- data.frame(
      Symptom  = symptoms,
      Approach = labels[i],
      Count    = counts,
      RelFreq  = rel,
      stringsAsFactors = FALSE
    )

    if (identical(type, "optimize") || isTRUE(overall_includes_fixed)) {
      totals  <- totals + counts
      total_n <- total_n + n_combos
    }
  }

  combined <- do.call(rbind, per_scen)
  level_order <- labels

  if (isTRUE(include_overall)) {
    overall_rel <- if (total_n == 0) rep(0, 20) else totals / total_n
    overall <- data.frame(
      Symptom  = symptoms,
      Approach = "OVERALL",
      Count    = totals,
      RelFreq  = overall_rel,
      stringsAsFactors = FALSE
    )
    combined <- rbind(combined, overall)
    level_order <- c(labels, "OVERALL")
  }

  combined$Approach <- factor(combined$Approach, levels = level_order)
  rownames(combined) <- NULL
  combined
}
