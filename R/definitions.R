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
#'   \code{\link{as_definitions}} for building the same object from
#'   combinations imported with \code{\link{read_combinations}},
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


#' Convert imported combination specifications into definitions
#'
#' @description
#' Converts one or more combination specifications -- as returned by
#' \code{\link{read_combinations}} -- into the definitions list that
#' \code{\link{evaluate_definitions}} expects. This is the validation-site
#' counterpart of \code{\link{extract_definitions}}: the derivation site
#' exports each rule as a JSON file, and the validation site turns the
#' imported files into evaluable definitions in one call.
#'
#' @details
#' Each definition is labelled by, in order of precedence: the name given to
#' the list element in \code{specs}; the \code{label} stored in the file by
#' \code{\link{write_combinations}}; or an automatic label of the form
#' \code{"4/6 Hierarchical"} derived from the rule (\code{n_required} /
#' number of symptoms, hierarchical when the specification carries a cluster
#' structure). Duplicate labels are an error -- name the list elements to
#' disambiguate.
#'
#' A cluster structure stored in the specification is preserved in the
#' definition, so hierarchical rules exported with non-default clusters are
#' evaluated with exactly those clusters.
#'
#' @param specs A single combination specification (the list returned by
#'   \code{\link{read_combinations}}, or any list with \code{combinations} and
#'   \code{n_required} elements), or a list of such specifications -- e.g.
#'   \code{lapply(files, read_combinations)}. List names, when supplied,
#'   become the definition labels.
#' @param n_top Integer or \code{NULL} (default). When supplied, only the
#'   first \code{n_top} combinations of each specification (their stored rank
#'   order) are kept; capped at the number available.
#'
#' @returns A named list in the shape returned by
#'   \code{\link{extract_definitions}}: one element per specification, each a
#'   list with \code{symptoms} (list of integer vectors), \code{n_required},
#'   \code{hierarchical}, and \code{clusters} (\code{NULL} unless the
#'   specification stored a cluster structure). Pass it to
#'   \code{\link{evaluate_definitions}}.
#'
#' @seealso \code{\link{read_combinations}},
#'   \code{\link{evaluate_definitions}}, \code{\link{extract_definitions}}.
#'
#' @export
#'
#' @examples
#' # A derivation site exports a rule ...
#' tmp <- tempfile(fileext = ".json")
#' write_combinations(list(c(1, 6, 8, 10, 15, 19), c(2, 7, 9, 11, 16, 20)),
#'                    tmp, n_required = 4, label = "4/6 Non-hierarchical")
#'
#' # ... and the validation site turns the imported file into definitions
#' spec <- read_combinations(tmp)
#' definitions <- as_definitions(spec, n_top = 2)
#' str(definitions)
#'
#' unlink(tmp)
as_definitions <- function(specs, n_top = NULL) {
  if (!is.null(n_top)) {
    .validate_n_top(n_top)
  }

  if (.is_combination_spec(specs)) {
    spec_list <- list(specs)
    names(spec_list) <- ""
  } else if (is.list(specs) && !is.data.frame(specs) && length(specs) > 0 &&
             all(vapply(specs, .is_combination_spec, logical(1)))) {
    spec_list <- specs
    if (is.null(names(spec_list))) {
      names(spec_list) <- rep("", length(spec_list))
    }
  } else {
    cli::cli_abort(c(
      "{.arg specs} must be a combination specification (from \\
      {.fn read_combinations}) or a list of them.",
      "i" = "Each specification must contain {.field combinations} and \\
            {.field n_required}."
    ))
  }

  defs   <- vector("list", length(spec_list))
  labels <- character(length(spec_list))

  for (i in seq_along(spec_list)) {
    spec <- spec_list[[i]]

    .validate_combinations_input(spec$combinations)
    combo_length <- length(spec$combinations[[1]])
    .validate_n_required(spec$n_required, combo_length)
    if (!is.null(spec$clusters)) {
      .validate_clusters(spec$clusters)
    }

    hierarchical <- !is.null(spec$clusters)
    n_symptoms   <- spec$parameters$n_symptoms %||% combo_length

    supplied <- names(spec_list)[i]
    stored   <- spec$label
    labels[i] <- if (nzchar(supplied)) {
      supplied
    } else if (!is.null(stored) && length(stored) == 1 && !is.na(stored) &&
               nzchar(stored)) {
      as.character(stored)
    } else {
      paste0(spec$n_required, "/", n_symptoms, " ",
             if (hierarchical) "Hierarchical" else "Non-hierarchical")
    }

    k <- if (is.null(n_top)) {
      length(spec$combinations)
    } else {
      min(n_top, length(spec$combinations))
    }

    defs[[i]] <- list(
      symptoms     = spec$combinations[seq_len(k)],
      n_required   = spec$n_required,
      hierarchical = hierarchical,
      clusters     = spec$clusters
    )
  }

  if (anyDuplicated(labels)) {
    dups <- unique(labels[duplicated(labels)])
    cli::cli_abort(c(
      "Definitions must have unique labels.",
      "x" = "Duplicate label{?s}: {.val {dups}}.",
      "i" = "Name the list elements to disambiguate, e.g. \\
            {.code as_definitions(list(\"Rule A\" = spec1, \"Rule B\" = spec2))}."
    ))
  }

  stats::setNames(defs, labels)
}


#' Evaluate symptom definitions against a sample
#'
#' @description
#' Applies a set of pre-derived symptom definitions to a dataset and returns a
#' performance table scoring each one against a reference standard. By default
#' the reference is the sample's own full DSM-5-TR diagnosis; supply
#' \code{reference} to score against an external standard instead (e.g. a
#' clinician CAPS diagnosis). Because it needs only the definitions (symptom
#' indices and rules) and a data frame, the same call can be run at a site
#' that never saw the data the definitions were derived from.
#'
#' @details
#' Each definition is applied with its own rule via
#' \code{\link{apply_symptom_combinations}} (using the definition's own
#' cluster structure when present, otherwise the default PCL-5 clusters, when
#' \code{hierarchical = TRUE}). When \code{include_icd11 = TRUE}, the ICD-11
#' criterion (\code{\link{create_icd11_diagnosis}}) is added as a fixed
#' benchmark, computed locally on the supplied data.
#'
#' With an external \code{reference}, rows with a missing reference value are
#' excluded from the evaluation (with a message reporting how many), and a
#' \code{"Full 20-item PCL-5"} ceiling row is added by default: the full
#' DSM-5-TR PCL-5 diagnosis scored against the same reference. This row
#' separates the cost of using a reduced symptom set from the intrinsic
#' disagreement between the PCL-5 and the external standard -- no reduced rule
#' can be expected to exceed it.
#'
#' @param data A dataframe with the 20 PCL-5 item columns \code{symptom_1}
#'   through \code{symptom_20} (output of \code{\link{rename_ptsd_columns}}).
#'   Additional carry-through columns are ignored (but may be named by
#'   \code{reference}).
#' @param definitions A named list of definitions, as returned by
#'   \code{\link{extract_definitions}} or \code{\link{as_definitions}}. Each
#'   element must contain \code{symptoms} (a list of integer vectors),
#'   \code{n_required}, and \code{hierarchical} (plus an optional
#'   \code{clusters} structure). A specification from
#'   \code{\link{read_combinations}} -- or a list of them -- is converted
#'   automatically via \code{\link{as_definitions}}.
#' @param include_icd11 Logical. If \code{TRUE} (default), append the ICD-11
#'   criterion as a benchmark row.
#' @param reference \code{NULL} (default) to score against the full DSM-5-TR
#'   PCL-5 diagnosis computed from \code{data}. Otherwise an external
#'   reference standard: a logical vector with one value per row, a 0/1-coded
#'   numeric vector, or a single string naming such a column in \code{data}.
#'   Missing values mark rows without a reference assessment; those rows are
#'   excluded (with a message).
#' @param include_full_pcl5 Logical or \code{NULL} (default). Whether to add a
#'   \code{"Full 20-item PCL-5"} ceiling row. \code{NULL} resolves to
#'   \code{TRUE} exactly when \code{reference} is external (where the row is
#'   informative) and \code{FALSE} otherwise (where it would be a
#'   self-comparison).
#' @param tidy Logical. If \code{FALSE} (default), return the formatted
#'   display table (see \code{\link{create_readable_summary}}). If
#'   \code{TRUE}, return a plain analysis table matching
#'   \code{\link{summarize_top_combinations}}: one row per evaluated rule with
#'   \code{Approach}, \code{Rank}, \code{Combination}, the 2x2 counts, and
#'   numeric metrics -- ready to filter, bind, or export without parsing
#'   labels.
#' @param as_percent Logical. Only with \code{tidy = TRUE}: if \code{TRUE},
#'   Sensitivity/Specificity/PPV/NPV/Accuracy/Balanced Accuracy are returned
#'   as percentages (0-100) instead of fractions (0-1). Default \code{FALSE}.
#'
#' @returns With \code{tidy = FALSE}, a formatted performance table (see
#'   \code{\link{create_readable_summary}}): one row for the reference
#'   standard (labelled \code{PTSD_orig}), one per definition (labelled by
#'   rule and symptom set), plus the optional \code{"Full 20-item PCL-5"} and
#'   \code{"ICD-11"} rows.
#'
#'   With \code{tidy = TRUE}, a data.frame with columns \code{Approach},
#'   \code{Rank} (the combination's rank within its definition),
#'   \code{Combination} (comma-separated PCL-5 item numbers; \code{NA} for the
#'   full-PCL-5 ceiling row), \code{TP}, \code{FN}, \code{FP}, \code{TN},
#'   \code{Sensitivity}, \code{Specificity}, \code{PPV}, \code{NPV},
#'   \code{Accuracy}, \code{Balanced Accuracy}. The reference self-comparison
#'   row is omitted. The layout matches
#'   \code{\link{summarize_top_combinations}}, so derivation and validation
#'   results can be combined with \code{rbind()}.
#'
#' @seealso \code{\link{extract_definitions}}, \code{\link{as_definitions}},
#'   \code{\link{compare_optimizations}},
#'   \code{\link{summarize_top_combinations}}.
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
#' definitions <- extract_definitions(comp, n = 3)
#'
#' # Default: formatted table against the full DSM-5-TR PCL-5 diagnosis
#' evaluate_definitions(ptsd, definitions)
#'
#' # Tidy analysis table (same layout as summarize_top_combinations())
#' evaluate_definitions(ptsd, definitions, tidy = TRUE)
#'
#' # Against an external reference: the bundled general-population sample
#' # carries paired CAPS-5 items, standing in for a clinician diagnosis
#' gp   <- simulated_ptsd_genpop[1:400, ]
#' caps <- create_caps5_diagnosis(
#'   rename_caps5_columns(gp[, paste0("C", 1:20)])
#' )$PTSD_caps5
#' ptsd_gp <- rename_ptsd_columns(gp[, c("patient_id", paste0("S", 1:20))],
#'                                id_col = "patient_id")
#' ptsd_gp$caps <- caps
#' evaluate_definitions(ptsd_gp, definitions, reference = "caps", tidy = TRUE)
#' }
evaluate_definitions <- function(data, definitions, include_icd11 = TRUE,
                                 reference = NULL, include_full_pcl5 = NULL,
                                 tidy = FALSE, as_percent = FALSE) {
  .validate_pcl5_data(data, strict_cols = FALSE)

  # Specifications from read_combinations() are converted automatically
  if (inherits(definitions, "ptsdiag_spec") ||
      .is_combination_spec(definitions) ||
      (is.list(definitions) && !is.data.frame(definitions) &&
       length(definitions) > 0 &&
       all(vapply(definitions, .is_combination_spec, logical(1))))) {
    definitions <- as_definitions(definitions)
  }

  .validate_definitions(definitions, nrow(data))
  if (!is.logical(include_icd11) || length(include_icd11) != 1) {
    cli::cli_abort("{.arg include_icd11} must be a single logical.")
  }
  if (!is.logical(tidy) || length(tidy) != 1 || is.na(tidy)) {
    cli::cli_abort("{.arg tidy} must be a single logical.")
  }
  if (!is.logical(as_percent) || length(as_percent) != 1 || is.na(as_percent)) {
    cli::cli_abort("{.arg as_percent} must be a single logical.")
  }
  if (isTRUE(as_percent) && !isTRUE(tidy)) {
    cli::cli_abort(c(
      "{.arg as_percent} only applies to the tidy output.",
      "i" = "Set {.code tidy = TRUE} to use {.arg as_percent}."
    ))
  }
  if (!is.null(include_full_pcl5) &&
      (!is.logical(include_full_pcl5) || length(include_full_pcl5) != 1 ||
       is.na(include_full_pcl5))) {
    cli::cli_abort(
      "{.arg include_full_pcl5} must be a single logical or {.code NULL}."
    )
  }

  external_reference <- !is.null(reference)
  if (is.null(include_full_pcl5)) {
    include_full_pcl5 <- external_reference
  }

  if (external_reference) {
    ref   <- .resolve_reference(data, reference)
    n_all <- nrow(data)
    keep  <- !is.na(ref)
    n_dropped <- n_all - sum(keep)
    if (n_dropped > 0) {
      n_kept <- sum(keep)
      cli::cli_inform(c(
        "i" = "{.arg reference} is missing for {n_dropped} of {n_all} \\
              row{?s}; the evaluation uses the {n_kept} row{?s} with a \\
              reference value."
      ))
      data <- data[keep, , drop = FALSE]
      ref  <- ref[keep]
    }
    baseline <- ref
  } else {
    baseline <- create_ptsd_diagnosis_binarized(data)$PTSD_orig
  }

  default_clusters <- .get_default_clusters()

  comparison <- data.frame(PTSD_orig = baseline, check.names = FALSE)
  meta <- list()

  for (rule in names(definitions)) {
    d  <- definitions[[rule]]
    cl <- if (isTRUE(d$hierarchical)) d$clusters %||% default_clusters else NULL
    applied <- apply_symptom_combinations(
      data, d$symptoms, n_required = d$n_required, clusters = cl
    )
    combo_cols <- grep("^symptom_[0-9]+(_[0-9]+)+$", names(applied), value = TRUE)
    for (i in seq_along(combo_cols)) {
      cc        <- combo_cols[i]
      combo_str <- gsub("_", ", ", sub("^symptom_", "", cc))
      label     <- paste0(rule, " (", combo_str, ")")
      comparison[[label]] <- applied[[cc]]
      meta[[length(meta) + 1L]] <- data.frame(
        column = label, Approach = rule, Rank = i, Combination = combo_str,
        stringsAsFactors = FALSE
      )
    }
  }

  if (isTRUE(include_full_pcl5)) {
    comparison[["Full 20-item PCL-5"]] <-
      create_ptsd_diagnosis_binarized(data)$PTSD_orig
    meta[[length(meta) + 1L]] <- data.frame(
      column = "Full 20-item PCL-5", Approach = "Full 20-item PCL-5",
      Rank = 1L, Combination = NA_character_, stringsAsFactors = FALSE
    )
  }

  if (isTRUE(include_icd11)) {
    comparison[["ICD-11"]] <- create_icd11_diagnosis(data)$PTSD_icd11
    icd_symptoms <- .fixed_criterion_registry()$icd11$symptoms
    meta[[length(meta) + 1L]] <- data.frame(
      column = "ICD-11", Approach = "ICD-11", Rank = 1L,
      Combination = paste(icd_symptoms, collapse = ", "),
      stringsAsFactors = FALSE
    )
  }

  stats <- summarize_ptsd_changes(comparison)

  if (!isTRUE(tidy)) {
    return(create_readable_summary(stats))
  }

  meta_df <- do.call(rbind, meta)
  stats   <- stats[match(meta_df$column, stats$column), , drop = FALSE]

  out <- data.frame(
    Approach    = meta_df$Approach,
    Rank        = meta_df$Rank,
    Combination = meta_df$Combination,
    TP          = stats$true_positive,
    FN          = stats$newly_nondiagnosed,
    FP          = stats$newly_diagnosed,
    TN          = stats$true_negative,
    Sensitivity = stats$sensitivity,
    Specificity = stats$specificity,
    PPV         = stats$ppv,
    NPV         = stats$npv,
    Accuracy    = stats$accuracy,
    `Balanced Accuracy` = stats$balanced_accuracy,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (isTRUE(as_percent)) {
    out$Sensitivity <- out$Sensitivity * 100
    out$Specificity <- out$Specificity * 100
    out$PPV         <- out$PPV         * 100
    out$NPV         <- out$NPV         * 100
    out$Accuracy    <- out$Accuracy    * 100
    out$`Balanced Accuracy` <- out$`Balanced Accuracy` * 100
  }
  rownames(out) <- NULL
  out
}
