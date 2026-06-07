#' Run multiple PTSD optimization scenarios in one call
#'
#' @description
#' Runs several optimization scenarios on the same dataset and bundles the
#' results into a single object suitable for tabular and visual comparison.
#' Reproduces the multi-scenario workflow used in the PTSDdiag preprint
#' (4/6 hierarchical, 4/6 non-hierarchical, 3/6 non-hierarchical) in one call,
#' and also supports adding fixed criteria such as ICD-11 to the comparison.
#'
#' @details
#' Each scenario is either:
#'
#' \itemize{
#'   \item \strong{optimize} (default): runs \code{\link{optimize_combinations}}
#'     or \code{\link{optimize_combinations_clusters}} depending on
#'     \code{hierarchical}. Returns the top \code{n_top} combinations.
#'   \item \strong{fixed}: applies a pre-defined diagnostic criterion (such as
#'     ICD-11 PTSD) and treats its fixed symptom set as a single "combination"
#'     for the purpose of the multi-scenario tables and heatmap.
#' }
#'
#' Fixed scenarios let researchers benchmark optimized criteria against
#' published systems in a uniform output.
#'
#' Any non-symptom columns present in \code{data} (e.g. an ID column added via
#' \code{rename_ptsd_columns(..., id_col = "patient_id")}) are carried through
#' to each scenario's per-row \code{diagnosis_comparison}, so per-participant
#' diagnoses can be joined back to demographics.
#'
#' @param data A dataframe containing the 20 PCL-5 item columns
#'   \code{symptom_1} through \code{symptom_20} (output of
#'   \code{\link{rename_ptsd_columns}}). Non-symptom columns (e.g. a
#'   participant identifier) are carried through every scenario's per-row
#'   diagnosis output.
#'
#' @param scenarios Optional named list of scenario configurations. Each
#'   element is a list with:
#'
#'   \itemize{
#'     \item \code{type}: \code{"optimize"} (default if omitted) or
#'       \code{"fixed"}.
#'     \item For \code{type = "optimize"}: \code{n_symptoms} (integer 1-20),
#'       \code{n_required} (integer 1-\code{n_symptoms}), \code{hierarchical}
#'       (single logical), and optional \code{clusters} (named list of integer
#'       vectors; defaults to PCL-5 B/C/D/E when \code{hierarchical = TRUE}).
#'     \item For \code{type = "fixed"}: \code{criterion} -- either a known
#'       string (\code{"icd11"} or \code{"caps5"}) or a logical vector of
#'       length \code{nrow(data)} representing a pre-computed diagnosis. When
#'       supplying a logical vector you must also provide \code{symptoms}, the
#'       integer indices counted as "included" in the heatmap.
#'   }
#'
#'   When \code{NULL} (default), runs the three preprint scenarios: 4/6
#'   hierarchical, 4/6 non-hierarchical, 3/6 non-hierarchical.
#'
#' @param include_icd11 Logical. When \code{TRUE}, appends an \code{"ICD-11"}
#'   fixed-criterion scenario after any user-supplied entries (deduplicated by
#'   label). Default \code{FALSE}.
#'
#' @param n_top Integer. Number of top combinations to retain per optimize
#'   scenario (default 10). Fixed scenarios always contribute exactly one
#'   combination regardless of \code{n_top}.
#'
#' @param score_by Character. Optimization criterion: \code{"accuracy"}
#'   (minimise FP + FN) or \code{"sensitivity"} (minimise FN only). Applied
#'   to optimize scenarios that do not override it. Default
#'   \code{"accuracy"}.
#'
#' @param clusters Optional named list of integer vectors defining the PCL-5
#'   clusters used by hierarchical optimize scenarios that do not specify
#'   their own. Defaults to the DSM-5 B/C/D/E grouping when needed.
#'
#' @param show_progress Logical. Forwarded to each optimize scenario's
#'   progress bar. Default \code{TRUE}.
#'
#' @returns An object of class \code{ptsdiag_comparison}, a list with:
#'
#' \itemize{
#'   \item \code{scenarios}: named list of per-scenario results. Each element
#'     mirrors the shape returned by \code{\link{optimize_combinations}}
#'     (\code{best_symptoms}, \code{diagnosis_comparison}, \code{summary},
#'     \code{n_tied}) and carries a \code{type} attribute.
#'   \item \code{config}: data.frame with one row per scenario summarising the
#'     configuration used.
#'   \item \code{n_rows}: number of input rows.
#'   \item \code{call}: the matched call.
#' }
#'
#' Pass the result to \code{\link{summarize_top_combinations}} for a
#' manuscript-ready performance table, to \code{\link{symptom_frequency}} for
#' the long-format symptom inclusion counts, and to
#' \code{\link{plot_symptom_frequency}} for the heatmap.
#'
#' @seealso
#' \code{\link{optimize_combinations}},
#' \code{\link{optimize_combinations_clusters}},
#' \code{\link{create_icd11_diagnosis}},
#' \code{\link{summarize_top_combinations}},
#' \code{\link{symptom_frequency}},
#' \code{\link{plot_symptom_frequency}}.
#'
#' @export
#'
#' @examples
#' ptsd_data <- rename_ptsd_columns(simulated_ptsd,
#'                                   id_col = c("patient_id", "age", "sex"))
#' \donttest{
#' # Three preprint scenarios + ICD-11 in one call
#' comp <- compare_optimizations(ptsd_data, n_top = 5, include_icd11 = TRUE,
#'                               show_progress = FALSE)
#' print(comp)
#'
#' # Manuscript Table 2
#' summarize_top_combinations(comp, as_percent = TRUE)
#' }
#'
compare_optimizations <- function(data,
                                  scenarios     = NULL,
                                  include_icd11 = FALSE,
                                  n_top         = 10,
                                  score_by      = "accuracy",
                                  clusters      = NULL,
                                  show_progress = TRUE) {
  .validate_pcl5_data(data, strict_cols = FALSE)
  .validate_score_by(score_by)
  .validate_n_top(n_top)
  if (!is.null(clusters)) .validate_clusters(clusters)

  if (is.null(scenarios)) {
    scenarios <- .default_scenarios()
  }

  if (isTRUE(include_icd11) && !"ICD-11" %in% names(scenarios)) {
    scenarios[["ICD-11"]] <- list(type = "fixed", criterion = "icd11")
  }

  .validate_scenarios(scenarios, n_rows = nrow(data))

  registry <- .fixed_criterion_registry()
  default_cl <- if (is.null(clusters)) .get_default_clusters() else clusters

  scenario_outputs <- vector("list", length(scenarios))
  names(scenario_outputs) <- names(scenarios)
  config_rows <- vector("list", length(scenarios))

  for (i in seq_along(scenarios)) {
    label <- names(scenarios)[i]
    sc    <- scenarios[[i]]
    type  <- if (is.null(sc$type)) "optimize" else sc$type

    if (type == "optimize") {
      sc_score   <- if (is.null(sc$score_by))   score_by   else sc$score_by
      sc_clusters <- if (is.null(sc$clusters))   default_cl else sc$clusters

      if (show_progress) {
        cli::cli_alert_info("Scenario {.val {label}}: optimizing ({sc$n_symptoms}/{sc$n_required}, hierarchical = {sc$hierarchical}).")
      }

      if (isTRUE(sc$hierarchical)) {
        res <- optimize_combinations_clusters(
          data,
          n_symptoms   = sc$n_symptoms,
          n_required   = sc$n_required,
          n_top        = n_top,
          score_by     = sc_score,
          clusters     = sc_clusters,
          show_progress = show_progress
        )
      } else {
        res <- optimize_combinations(
          data,
          n_symptoms   = sc$n_symptoms,
          n_required   = sc$n_required,
          n_top        = n_top,
          score_by     = sc_score,
          show_progress = show_progress
        )
      }
      attr(res, "type") <- "optimize"
      scenario_outputs[[i]] <- res

      config_rows[[i]] <- data.frame(
        label        = label,
        type         = "optimize",
        n_symptoms   = sc$n_symptoms,
        n_required   = sc$n_required,
        hierarchical = isTRUE(sc$hierarchical),
        n_top        = n_top,
        score_by     = sc_score,
        n_tied       = res$n_tied %||% NA_integer_,
        stringsAsFactors = FALSE
      )
    } else {
      # type == "fixed"
      crit <- sc$criterion
      if (is.character(crit) && length(crit) == 1) {
        reg <- registry[[crit]]
        dx_column <- reg$column
        dx_vec    <- reg$producer(data)
        symptoms  <- reg$symptoms
      } else {
        dx_column <- if (is.null(sc$column)) paste0("PTSD_", make.names(label)) else sc$column
        dx_vec    <- as.logical(crit)
        symptoms  <- as.integer(sc$symptoms)
      }

      baseline <- create_ptsd_diagnosis_binarized(data)$PTSD_orig
      carry_df <- .extract_carry_df(data)

      comparison_df <- data.frame(PTSD_orig = baseline,
                                  stringsAsFactors = FALSE)
      comparison_df[[dx_column]] <- dx_vec
      comparison_df <- .attach_carry_cols(comparison_df, carry_df)

      summary_table <- .wrap_summary(comparison_df, DT = FALSE)

      res <- list(
        best_symptoms        = list(sort(unique(as.integer(symptoms)))),
        diagnosis_comparison = comparison_df,
        summary              = summary_table,
        n_tied               = NA_integer_
      )
      attr(res, "type") <- "fixed"
      attr(res, "fixed_column") <- dx_column
      scenario_outputs[[i]] <- res

      config_rows[[i]] <- data.frame(
        label        = label,
        type         = "fixed",
        n_symptoms   = NA_integer_,
        n_required   = NA_integer_,
        hierarchical = NA,
        n_top        = 1L,
        score_by     = NA_character_,
        n_tied       = NA_integer_,
        stringsAsFactors = FALSE
      )
    }
  }

  config <- do.call(rbind, config_rows)
  rownames(config) <- NULL

  structure(
    list(
      scenarios = scenario_outputs,
      config    = config,
      n_rows    = nrow(data),
      call      = match.call()
    ),
    class = "ptsdiag_comparison"
  )
}

# Internal helper for "%||%"-style fallback without taking a hard dep.
`%||%` <- function(x, y) if (is.null(x)) y else x


#' Print method for ptsdiag_comparison objects
#'
#' @param x A \code{ptsdiag_comparison} object.
#' @param ... Unused.
#' @returns The input object invisibly.
#' @export
print.ptsdiag_comparison <- function(x, ...) {
  cli::cli_h1("PTSDdiag multi-scenario comparison")
  cli::cli_text("Input rows: {.val {x$n_rows}}.")
  cli::cli_text("Scenarios: {.val {nrow(x$config)}}.")
  cli::cli_text("")

  for (i in seq_along(x$scenarios)) {
    label <- names(x$scenarios)[i]
    res   <- x$scenarios[[i]]
    type  <- attr(res, "type")
    top   <- res$best_symptoms[[1]]
    tied  <- res$n_tied
    tied_msg <- if (is.na(tied) || tied == 0) "" else paste0(" (", tied, " tied)")
    if (identical(type, "fixed")) {
      cli::cli_li("{.strong {label}} [fixed]: symptoms {paste(top, collapse = ', ')}")
    } else {
      cli::cli_li("{.strong {label}} [optimize]: best = {paste(top, collapse = ', ')}{tied_msg}")
    }
  }
  invisible(x)
}
