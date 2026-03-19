#' Write symptom combinations to a JSON file
#'
#' @description
#' Exports optimized symptom combinations to a human-readable JSON file.
#' This enables sharing of derived combinations across research groups without
#' needing to share raw data, supporting reproducible derivation-validation
#' workflows.
#'
#' @details
#' The JSON file contains the combinations alongside metadata needed to apply
#' them via \code{\link{apply_symptom_combinations}}: the required symptom
#' threshold (\code{n_required}) and optional cluster structure
#' (\code{clusters}). Additional fields (\code{score_by}, \code{n_symptoms},
#' \code{description}) provide context for reproducibility.
#'
#' The \code{combinations} argument can be either:
#' \itemize{
#'   \item A list of integer vectors (e.g., from \code{results$best_symptoms})
#'   \item The full result object from \code{\link{optimize_combinations}} or
#'     \code{\link{optimize_combinations_clusters}} (the function automatically
#'     extracts \code{$best_symptoms})
#' }
#'
#' @param combinations A list of integer vectors specifying symptom
#'   combinations, or the full result object from
#'   \code{\link{optimize_combinations}} /
#'   \code{\link{optimize_combinations_clusters}} (which contains
#'   \code{$best_symptoms}).
#'
#' @param file Character string. Path to the output JSON file.
#'
#' @param n_required Integer specifying how many symptoms must be present for
#'   a positive diagnosis (default: 4). This value is stored in the file so
#'   that \code{\link{read_combinations}} can retrieve it.
#'
#' @param clusters \code{NULL} (default) for non-hierarchical combinations, or
#'   a named list of integer vectors defining the cluster structure for
#'   hierarchical combinations. Stored in the file for use with
#'   \code{\link{apply_symptom_combinations}}.
#'
#' @param n_symptoms Integer or \code{NULL}. Number of symptoms per
#'   combination. If \code{NULL} (default), inferred from the length of the
#'   first combination.
#'
#' @param score_by Character or \code{NULL}. The scoring criterion used during
#'   optimization (\code{"false_cases"} or \code{"newly_nondiagnosed"}).
#'   Stored as metadata for reproducibility. If \code{NULL} (default), omitted
#'   from the file.
#'
#' @param description Character string. Optional free-text description of the
#'   derivation context (e.g., sample characteristics, dataset name). Default
#'   is an empty string.
#'
#' @returns The file path (invisibly), following the convention of
#'   \code{\link[utils]{write.csv}}.
#'
#' @seealso
#' \code{\link{read_combinations}} to import combinations from a JSON file.
#'
#' \code{\link{optimize_combinations}} and
#' \code{\link{optimize_combinations_clusters}} for deriving optimal
#' combinations.
#'
#' \code{\link{apply_symptom_combinations}} for applying imported combinations
#' to new data.
#'
#' @export
#'
#' @importFrom jsonlite write_json
#'
#' @examples
#' # Create example combinations
#' my_combos <- list(
#'   c(1, 6, 8, 10, 15, 19),
#'   c(2, 7, 9, 11, 16, 20)
#' )
#'
#' # Write to a temporary file
#' tmp <- tempfile(fileext = ".json")
#' write_combinations(my_combos, tmp, n_required = 4,
#'                    score_by = "false_cases",
#'                    description = "Example non-hierarchical combinations")
#'
#' # Can also pass a full optimization result directly:
#' # write_combinations(optimization_result, tmp, n_required = 4)
#'
#' # Clean up
#' unlink(tmp)
#'
write_combinations <- function(combinations, file, n_required = 4,
                               clusters = NULL, n_symptoms = NULL,
                               score_by = NULL, description = "") {
  # Auto-detect optimization result object
  if (is.list(combinations) && "best_symptoms" %in% names(combinations)) {
    combinations <- combinations$best_symptoms
  }

  # Validate inputs
  .validate_combinations_input(combinations)

  combo_length <- length(combinations[[1]])
  .validate_n_required(n_required, combo_length)

  if (!is.null(clusters)) {
    .validate_clusters(clusters)
  }

  if (!is.null(score_by)) {
    .validate_score_by(score_by)
  }

  if (is.null(n_symptoms)) {
    n_symptoms <- combo_length
  }

  if (!is.character(file) || length(file) != 1) {
    stop("'file' must be a single character string specifying the output path")
  }

  if (!is.character(description) || length(description) != 1) {
    stop("'description' must be a single character string")
  }

  # Compute canonical combination IDs and ranks
  combination_ids <- vapply(combinations, function(combo) {
    paste(sort(combo), collapse = "_")
  }, character(1))
  ranks <- seq_along(combinations)

  # Build output structure
  output <- list(
    ptsddiag_version = as.character(utils::packageVersion("PTSDdiag")),
    created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    description = description,
    parameters = list(
      n_symptoms = n_symptoms,
      n_required = n_required,
      score_by = score_by,
      clusters = clusters
    ),
    combinations = combinations,
    combination_ids = combination_ids,
    ranks = ranks
  )

  # Write JSON
  jsonlite::write_json(output, path = file, pretty = TRUE, auto_unbox = TRUE,
                       null = "null")

  message("Combinations written to ", file)
  invisible(file)
}


#' Read symptom combinations from a JSON file
#'
#' @description
#' Imports symptom combinations from a JSON file previously created by
#' \code{\link{write_combinations}}. The returned list contains all fields
#' needed to apply the combinations to new data via
#' \code{\link{apply_symptom_combinations}}.
#'
#' @details
#' The function validates the imported data using the same checks as
#' \code{\link{apply_symptom_combinations}}, ensuring that the file contains
#' valid combinations, a valid \code{n_required} threshold, and (if present)
#' a valid cluster structure.
#'
#' If the file was created with a different version of PTSDdiag than the one
#' currently installed, an informational message is displayed.
#'
#' @param file Character string. Path to the JSON file to read.
#'
#' @returns A named list with the following elements:
#'
#' \describe{
#'   \item{combinations}{List of numeric vectors. Each vector contains symptom
#'     indices for one combination.}
#'   \item{combination_ids}{Character vector of canonical combination IDs (sorted
#'     symptom indices joined by underscores, e.g. \code{"4_6_7_17_19_20"}).
#'     Computed from the combinations if not present in the file (backward
#'     compatibility with files created before v0.2.1).}
#'   \item{ranks}{Integer vector of ranks (1 = best). Computed from list
#'     position if not present in the file.}
#'   \item{n_required}{Numeric. Number of symptoms required for a positive
#'     diagnosis.}
#'   \item{clusters}{\code{NULL} for non-hierarchical combinations, or a named
#'     list of numeric vectors defining the cluster structure.}
#'   \item{parameters}{Named list with additional metadata: \code{n_symptoms}
#'     and \code{score_by} (may be \code{NULL} if not recorded).}
#'   \item{description}{Character string with the user-provided description.}
#'   \item{ptsddiag_version}{Character string indicating which package version
#'     created the file.}
#'   \item{created_at}{Character string with the creation timestamp.}
#' }
#'
#' The \code{combinations}, \code{n_required}, and \code{clusters} elements
#' can be passed directly to \code{\link{apply_symptom_combinations}}:
#'
#' \preformatted{
#' spec <- read_combinations("my_combos.json")
#' result <- apply_symptom_combinations(
#'   data, spec$combinations, spec$n_required, spec$clusters
#' )
#' }
#'
#' @seealso
#' \code{\link{write_combinations}} to export combinations to a JSON file.
#'
#' \code{\link{apply_symptom_combinations}} to apply imported combinations
#' to new data.
#'
#' @export
#'
#' @importFrom jsonlite read_json
#'
#' @examples
#' # Write example combinations
#' my_combos <- list(
#'   c(1, 6, 8, 10, 15, 19),
#'   c(2, 7, 9, 11, 16, 20)
#' )
#' tmp <- tempfile(fileext = ".json")
#' write_combinations(my_combos, tmp, n_required = 4,
#'                    score_by = "false_cases")
#'
#' # Read them back
#' spec <- read_combinations(tmp)
#' spec$combinations
#' spec$n_required
#'
#' # Apply to data (example workflow)
#' # comparison <- apply_symptom_combinations(
#' #   new_data, spec$combinations, spec$n_required, spec$clusters
#' # )
#'
#' # Clean up
#' unlink(tmp)
#'
read_combinations <- function(file) {
  if (!is.character(file) || length(file) != 1) {
    stop("'file' must be a single character string specifying the file path")
  }

  if (!file.exists(file)) {
    stop("File not found: ", file)
  }

  # Read JSON (keep as nested lists to handle varying structures)
  raw <- jsonlite::read_json(file, simplifyVector = FALSE)

  # Validate structure
  .validate_json_structure(raw)

  # Extract and convert combinations: list of lists -> list of vectors
  combinations <- lapply(raw$combinations, function(x) unlist(x))

  # Extract parameters
  n_required <- raw$parameters$n_required

  # Extract clusters (if present)
  # Note: JSON null -> R NULL, but JSON {} -> R list() (empty named list)
  # Treat both NULL and empty list as "no clusters"
  clusters <- NULL
  if (!is.null(raw$parameters$clusters) && length(raw$parameters$clusters) > 0) {
    clusters <- lapply(raw$parameters$clusters, function(x) unlist(x))
  }

  # Validate using existing validators
  .validate_combinations_input(combinations)

  combo_length <- length(combinations[[1]])
  .validate_n_required(n_required, combo_length)

  if (!is.null(clusters)) {
    .validate_clusters(clusters)
  }

  # Check version compatibility
  file_version <- raw$ptsddiag_version
  if (!is.null(file_version)) {
    current_version <- as.character(utils::packageVersion("PTSDdiag"))
    if (file_version != current_version) {
      message("Note: File was created with PTSDdiag ", file_version,
              ", currently using ", current_version)
    }
  }

  # Extract combination_ids and ranks (fall back for older files)
  combination_ids <- if (!is.null(raw$combination_ids)) {
    unlist(raw$combination_ids)
  } else {
    vapply(combinations, function(combo) {
      paste(sort(combo), collapse = "_")
    }, character(1))
  }
  ranks <- if (!is.null(raw$ranks)) {
    unlist(raw$ranks)
  } else {
    seq_along(combinations)
  }

  # Build return list with top-level convenience fields
  result <- list(
    combinations = combinations,
    combination_ids = combination_ids,
    ranks = ranks,
    n_required = n_required,
    clusters = clusters,
    parameters = list(
      n_symptoms = raw$parameters$n_symptoms,
      score_by = raw$parameters$score_by
    ),
    description = if (!is.null(raw$description)) raw$description else "",
    ptsddiag_version = if (!is.null(file_version)) file_version else NA_character_,
    created_at = if (!is.null(raw$created_at)) raw$created_at else NA_character_
  )

  return(result)
}
