# Suppress R CMD check NOTEs from ggplot2 NSE in plot_symptom_frequency().
utils::globalVariables(c("Symptom_Factor", "RelFreq", "Count", "Approach",
                         "Group"))

#' Heatmap of PCL-5 symptom selection frequency across optimization scenarios
#'
#' @description
#' Visualises how often each of the 20 PCL-5 symptoms is selected across the
#' top combinations of each optimization scenario in a
#' \code{\link{compare_optimizations}} result. Replicates the symptom-frequency
#' heatmap (Figure 1) of the PTSDdiag preprint and helps identify "core"
#' symptoms that recur across data-driven combinations.
#'
#' @details
#' Each tile shows the frequency with which a symptom appears in the stored
#' combinations of a scenario. Fixed criteria (e.g. ICD-11) appear as rows
#' with cells at \code{RelFreq = 1} on their included symptoms and
#' \code{RelFreq = 0} elsewhere. The optional \code{OVERALL} row pools across
#' optimization scenarios by default (set
#' \code{overall_includes_fixed = TRUE} to include fixed criteria in the
#' pool). It is rendered in a separate facet so it is visually distinct from
#' the per-scenario rows.
#'
#' Requires the \pkg{ggplot2} package.
#'
#' @param comparison A \code{ptsdiag_comparison} object.
#' @param type \code{"relative"} (default; fill = \code{RelFreq}, percentage
#'   labels) or \code{"absolute"} (fill = \code{Count}).
#' @param show_overall Logical. Include the pooled \code{OVERALL} row.
#'   Default \code{TRUE}.
#' @param overall_includes_fixed Logical. If \code{TRUE}, fixed criteria
#'   contribute to the OVERALL row. Default \code{FALSE}.
#' @param symptom_labels Optional character vector of length 20 used to label
#'   the x-axis ticks. Default uses the numeric indices \code{1:20}.
#' @param low_colour,high_colour Gradient endpoints for the fill scale.
#'
#' @returns A \code{ggplot} object. Users can extend it with additional
#'   layers, themes, or labels via the usual \code{+} operator.
#'
#' @seealso \code{\link{compare_optimizations}},
#'   \code{\link{symptom_frequency}},
#'   \code{\link{summarize_top_combinations}}.
#'
#' @importFrom rlang .data
#'
#' @export
#'
#' @examples
#' \donttest{
#' ptsd_data <- rename_ptsd_columns(simulated_ptsd)
#' comp <- compare_optimizations(ptsd_data, n_top = 5, show_progress = FALSE)
#' plot_symptom_frequency(comp)
#' }
plot_symptom_frequency <- function(comparison,
                                   type           = c("relative", "absolute"),
                                   show_overall   = TRUE,
                                   overall_includes_fixed = FALSE,
                                   symptom_labels = NULL,
                                   low_colour     = "#f7fbff",
                                   high_colour    = "#084594") {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(c(
      "Package {.pkg ggplot2} is required for {.fn plot_symptom_frequency}.",
      "i" = "Install it with {.run install.packages(\"ggplot2\")}."
    ))
  }
  if (!inherits(comparison, "ptsdiag_comparison")) {
    cli::cli_abort(
      "{.arg comparison} must be a {.cls ptsdiag_comparison} object \\
       (from {.fn compare_optimizations})."
    )
  }
  type <- match.arg(type)

  if (!is.null(symptom_labels)) {
    if (!is.character(symptom_labels) || length(symptom_labels) != 20) {
      cli::cli_abort(
        "{.arg symptom_labels}, when supplied, must be a character vector of \\
         length 20."
      )
    }
  }

  data <- symptom_frequency(
    comparison,
    include_overall       = show_overall,
    overall_includes_fixed = overall_includes_fixed
  )

  # Display order: top-to-bottom in the plot = first scenario at top, OVERALL
  # in its own facet at the top.
  data$Approach <- factor(
    data$Approach,
    levels = rev(levels(data$Approach))
  )

  # Group lets us place OVERALL in its own facet for visual separation.
  data$Group <- ifelse(as.character(data$Approach) == "OVERALL",
                       "A_Summary", "B_Individual")

  data$Symptom_Factor <- factor(data$Symptom, levels = 1:20)
  x_labels <- if (is.null(symptom_labels)) as.character(1:20) else symptom_labels

  fill_var <- if (type == "relative") "RelFreq" else "Count"
  scale_name <- if (type == "relative") "Relative\nfrequency" else "Count"

  p <- ggplot2::ggplot(
    data,
    ggplot2::aes(x = Symptom_Factor, y = Approach,
                 fill = .data[[fill_var]])
  ) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.5) +
    ggplot2::scale_x_discrete(labels = x_labels, expand = c(0, 0)) +
    ggplot2::labs(
      title = "Symptom selection frequency",
      x     = "PCL-5 symptom",
      y     = NULL
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      strip.text          = ggplot2::element_blank(),
      panel.spacing.y     = ggplot2::unit(1, "lines"),
      panel.grid          = ggplot2::element_blank(),
      panel.background    = ggplot2::element_rect(fill = "white", colour = NA),
      plot.background     = ggplot2::element_rect(fill = "white", colour = NA),
      axis.text.y         = ggplot2::element_text(face = "bold", colour = "black"),
      axis.text.x         = ggplot2::element_text(colour = "black"),
      text                = ggplot2::element_text(size = 11)
    )

  if (type == "relative") {
    p <- p + ggplot2::scale_fill_gradient(
      low      = low_colour,
      high     = high_colour,
      limits   = c(0, 1),
      name     = scale_name,
      labels   = function(x) paste0(round(x * 100), "%")
    )
  } else {
    p <- p + ggplot2::scale_fill_gradient(
      low  = low_colour,
      high = high_colour,
      name = scale_name
    )
  }

  if (isTRUE(show_overall)) {
    p <- p + ggplot2::facet_grid(rows = ggplot2::vars(Group),
                                 scales = "free_y",
                                 space  = "free_y")
  }

  p
}
