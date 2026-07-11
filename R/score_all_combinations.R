#' Score every candidate symptom combination
#'
#' @description
#' Scores \strong{every} candidate combination of \code{n_symptoms} PCL-5
#' items against the full DSM-5-TR diagnosis and returns the complete ranked
#' table -- not just the best ones. This is the exhaustive companion to
#' \code{\link{optimize_combinations}} /
#' \code{\link{optimize_combinations_clusters}} (which keep only the top
#' \code{n_top}): use it to study how performance decays across the whole
#' candidate set, e.g. to show that many symptom sets are near-interchangeable
#' (a plateau of near-optimal combinations followed by a drop).
#'
#' @details
#' With \code{clusters = NULL}, all \code{choose(20, n_symptoms)} subsets are
#' scored (38,760 for six symptoms). With a cluster structure, only the
#' combinations containing at least one item per cluster are scored (13,685
#' six-symptom sets for the default PCL-5 clusters), and the diagnosis
#' additionally requires the present symptoms to span all clusters -- the same
#' candidate set and rule as \code{\link{optimize_combinations_clusters}}.
#' The hierarchical per-row cluster check makes this mode noticeably slower.
#'
#' Combinations are processed in chunks. If the \pkg{future.apply} package is
#' installed and a \code{future} plan is set (e.g.
#' \code{future::plan(future::multisession)}), chunks are scored in parallel;
#' otherwise they are scored sequentially with a progress bar. Results are
#' identical either way.
#'
#' The returned \code{combination_id} uses the same canonical format as
#' \code{\link{write_combinations}} (sorted item numbers joined by
#' underscores), so the full curve can be joined against exported top-\code{k}
#' combinations.
#'
#' @param data A dataframe with the 20 PCL-5 item columns \code{symptom_1}
#'   through \code{symptom_20} (output of \code{\link{rename_ptsd_columns}}).
#'   Additional carry-through columns are ignored.
#' @param n_symptoms Integer. Number of items per combination (default 6).
#' @param n_required Integer. How many of the items must be present (score
#'   >= 2) for a positive diagnosis (default 4).
#' @param clusters \code{NULL} (default) to score all subsets without a
#'   cluster constraint, or a named list of integer vectors (e.g.
#'   \code{list(B = 1:5, C = 6:7, D = 8:14, E = 15:20)}) for the
#'   cluster-constrained candidate set and diagnosis rule.
#' @param score_by Character. Metric that defines the ranking:
#'   \code{"balanced_accuracy"} (default), \code{"accuracy"}, or
#'   \code{"sensitivity"}. All metrics are returned regardless; this only
#'   sets the sort order.
#' @param chunk_size Integer. Number of combinations scored per chunk
#'   (default 1000). Affects speed and parallel granularity only, never the
#'   result.
#' @param show_progress Logical. If \code{TRUE} (default), display a progress
#'   bar (sequential mode only).
#'
#' @returns A data.frame with one row per candidate combination, sorted
#'   best-to-worst by \code{score_by} (ties broken by \code{combination_id}
#'   for determinism):
#'
#' \itemize{
#'   \item \code{rank}: 1 = best.
#'   \item \code{combination_id}: sorted item numbers joined by underscores
#'     (e.g. \code{"1_6_8_10_15_19"}).
#'   \item \code{tp}, \code{fn}, \code{fp}, \code{tn}: the 2x2 counts against
#'     the full DSM-5-TR diagnosis.
#'   \item \code{sensitivity}, \code{specificity}, \code{ppv}, \code{npv},
#'     \code{accuracy}, \code{balanced_accuracy}: metrics on the 0-1 scale
#'     (\code{NA} where a denominator is zero).
#' }
#'
#'   The attributes \code{n_symptoms}, \code{n_required}, \code{clusters},
#'   \code{score_by}, and \code{n_combinations} record the configuration.
#'
#' @seealso \code{\link{optimize_combinations}},
#'   \code{\link{optimize_combinations_clusters}},
#'   \code{\link{compare_optimizations}}.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # A 4-symptom search on a 250-row subset keeps the example fast
#' ptsd_data <- rename_ptsd_columns(simulated_ptsd[1:250, ],
#'                                  id_col = c("patient_id", "age", "sex"))
#' curve <- score_all_combinations(ptsd_data, n_symptoms = 4, n_required = 3,
#'                                 show_progress = FALSE)
#' nrow(curve)     # choose(20, 4) = 4845 combinations, all ranked
#' head(curve)
#'
#' # The full balanced-accuracy curve, e.g. for a rank plot:
#' # plot(curve$rank, curve$balanced_accuracy, type = "l", log = "x")
#' }
score_all_combinations <- function(data, n_symptoms = 6, n_required = 4,
                                   clusters = NULL,
                                   score_by = "balanced_accuracy",
                                   chunk_size = 1000,
                                   show_progress = TRUE) {
  .validate_pcl5_data(data, strict_cols = FALSE)
  .validate_n_symptoms(n_symptoms)
  .validate_n_required(n_required, n_symptoms)
  .validate_score_by(score_by)
  if (!is.null(clusters)) {
    .validate_clusters(clusters)
  }
  if (!is.numeric(chunk_size) || length(chunk_size) != 1 ||
      chunk_size != floor(chunk_size) || chunk_size < 1) {
    cli::cli_abort("{.arg chunk_size} must be a single positive integer.")
  }
  if (!is.logical(show_progress) || length(show_progress) != 1) {
    cli::cli_abort("{.arg show_progress} must be a single logical.")
  }

  baseline <- create_ptsd_diagnosis_binarized(data)$PTSD_orig
  n_pos <- sum(baseline)
  n_neg <- sum(!baseline)
  if (score_by == "balanced_accuracy" && (n_pos == 0L || n_neg == 0L)) {
    single_class <- if (n_pos == 0L) "non-diagnosed" else "diagnosed"
    cli::cli_abort(c(
      "{.code score_by = \"balanced_accuracy\"} requires both diagnosed and non-diagnosed cases under the reference criterion.",
      "x" = "All cases in the data are {single_class}, so sensitivity or specificity is undefined.",
      "i" = "Use {.code score_by = \"accuracy\"} or {.code score_by = \"sensitivity\"} instead."
    ))
  }

  symptom_data <- binarize_data(data)[, paste0("symptom_", 1:20), drop = FALSE]
  binarized <- as.matrix(symptom_data)

  combos <- .generate_valid_combinations(n_symptoms, clusters)
  n_combos <- length(combos)

  chunk_starts <- seq(1, n_combos, by = chunk_size)
  chunks <- lapply(chunk_starts, function(s) {
    combos[s:min(s + chunk_size - 1, n_combos)]
  })

  score_chunk <- function(chunk) {
    tp <- integer(length(chunk))
    fn <- integer(length(chunk))
    fp <- integer(length(chunk))
    tn <- integer(length(chunk))
    for (j in seq_along(chunk)) {
      pred <- .diagnose_combination(binarized, chunk[[j]], n_required,
                                    clusters = clusters)
      tp[j] <- sum(baseline & pred)
      fn[j] <- sum(baseline & !pred)
      fp[j] <- sum(!baseline & pred)
      tn[j] <- sum(!baseline & !pred)
    }
    list(tp = tp, fn = fn, fp = fp, tn = tn)
  }

  # Score chunks (parallel if future.apply is available)
  if (requireNamespace("future.apply", quietly = TRUE)) {
    chunk_results <- future.apply::future_lapply(chunks, score_chunk,
                                                 future.seed = FALSE)
  } else {
    chunk_results <- vector("list", length(chunks))
    if (show_progress) {
      cli::cli_progress_bar("Scoring combinations", total = length(chunks))
    }
    for (i in seq_along(chunks)) {
      chunk_results[[i]] <- score_chunk(chunks[[i]])
      if (show_progress) cli::cli_progress_update()
    }
    if (show_progress) cli::cli_progress_done()
  }

  tp <- unlist(lapply(chunk_results, `[[`, "tp"))
  fn <- unlist(lapply(chunk_results, `[[`, "fn"))
  fp <- unlist(lapply(chunk_results, `[[`, "fp"))
  tn <- unlist(lapply(chunk_results, `[[`, "tn"))

  combination_id <- vapply(combos, function(x) paste(x, collapse = "_"),
                           character(1))

  sensitivity <- ifelse(tp + fn > 0, tp / (tp + fn), NA_real_)
  specificity <- ifelse(tn + fp > 0, tn / (tn + fp), NA_real_)
  ppv <- ifelse(tp + fp > 0, tp / (tp + fp), NA_real_)
  npv <- ifelse(tn + fn > 0, tn / (tn + fn), NA_real_)
  accuracy <- (tp + tn) / nrow(data)
  balanced_accuracy <- (sensitivity + specificity) / 2

  score_vec <- switch(score_by,
    balanced_accuracy = balanced_accuracy,
    accuracy          = accuracy,
    sensitivity       = sensitivity
  )
  ord <- order(-score_vec, combination_id)

  result <- data.frame(
    rank = seq_len(n_combos),
    combination_id = combination_id[ord],
    tp = tp[ord], fn = fn[ord], fp = fp[ord], tn = tn[ord],
    sensitivity = sensitivity[ord],
    specificity = specificity[ord],
    ppv = ppv[ord],
    npv = npv[ord],
    accuracy = accuracy[ord],
    balanced_accuracy = balanced_accuracy[ord],
    stringsAsFactors = FALSE
  )

  attr(result, "n_symptoms") <- as.integer(n_symptoms)
  attr(result, "n_required") <- as.integer(n_required)
  attr(result, "clusters") <- clusters
  attr(result, "score_by") <- score_by
  attr(result, "n_combinations") <- n_combos

  result
}
