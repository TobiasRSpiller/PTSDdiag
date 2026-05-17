#' Calculate PTSD total score
#'
#' Calculates the total score from PCL-5 items
#'
#' @description
#' Calculates the total PCL-5 (PTSD Checklist for DSM-5) score by summing all
#' 20 symptom scores. The total score ranges from 0 to 80, with higher scores
#' indicating greater symptom severity.
#'
#' @param data A dataframe containing standardized PCL-5 item scores (output of
#'   rename_ptsd_columns). Each symptom should be scored on a 0-4 scale where:
#'
#' \itemize{
#'   \item 0 = Not at all
#'   \item 1 = A little bit
#'   \item 2 = Moderately
#'   \item 3 = Quite a bit
#'   \item 4 = Extremely
#'}
#'
#' @returns A dataframe with all original columns plus an additional column "total"
#'   containing the sum of all 20 symptom scores (range: 0-80)
#'
#' @export
#'
#' @importFrom dplyr mutate select
#' @importFrom magrittr %>%
#' @importFrom rlang .data
#'
#' @examples
#' # Create sample data
#' sample_data <- data.frame(
#'   matrix(sample(0:4, 20 * 10, replace = TRUE),
#'          nrow = 10,
#'          ncol = 20)
#' )
#' colnames(sample_data) <- paste0("symptom_", 1:20)
#'
#' # Calculate total scores
#' scores_with_total <- calculate_ptsd_total(sample_data)
#' print(scores_with_total$total)
#'
calculate_ptsd_total <- function(data) {
  .validate_pcl5_data(data, strict_cols = FALSE, warn_total = FALSE)

  data$total <- rowSums(data[, paste0("symptom_", 1:20)])
  return(data)
}


#' Determine PTSD diagnosis based on DSM-5 criteria using non-binarized scores
#'
#' @description
#' Determines whether DSM-5 diagnostic criteria for PTSD are met based on PCL-5
#' item scores, using the original non-binarized values (0-4 scale).
#'
#' @details
#' The function applies the DSM-5 diagnostic criteria for PTSD:
#'
#' \itemize{
#' \item Criterion B (Intrusion): At least 1 symptom >= 2 from items 1-5
#' \item Criterion C (Avoidance): At least 1 symptom >= 2 from items 6-7
#' \item Criterion D (Negative alterations in cognitions and mood):
#'   At least 2 symptoms >= 2 from items 8-14
#' \item Criterion E (Alterations in arousal and reactivity):
#'   At least 2 symptoms >= 2 from items 15-20
#'}
#'
#' A symptom is considered present when rated 2 (Moderately) or higher.
#'
#' @param data A dataframe that can be either:
#'
#' \itemize{
#'   \item Output of rename_ptsd_columns(): 20 columns named symptom_1 to symptom_20
#'   \item Output of calculate_ptsd_total(): 21 columns including symptom_1 to
#'     symptom_20 plus a 'total' column
#'}
#'
#'   Each symptom should be scored on a 0-4 scale where:
#'
#' \itemize{
#'   \item 0 = Not at all
#'   \item 1 = A little bit
#'   \item 2 = Moderately
#'   \item 3 = Quite a bit
#'   \item 4 = Extremely
#'}
#'
#' @returns A dataframe with all original columns (including 'total' if present)
#'   plus an additional column "PTSD_orig" containing TRUE/FALSE values
#'   indicating whether DSM-5 diagnostic criteria are met
#'
#' @export
#'
#' @examples
#' # Example with output from rename_ptsd_columns
#' sample_data1 <- data.frame(
#'   matrix(sample(0:4, 20 * 10, replace = TRUE),
#'          nrow = 10,
#'          ncol = 20)
#' )
#' colnames(sample_data1) <- paste0("symptom_", 1:20)
#' diagnosed_data1 <- create_ptsd_diagnosis_nonbinarized(sample_data1)
#'
#' # Check diagnosis results
#' diagnosed_data1$PTSD_orig
#'
#' # Example with output from calculate_ptsd_total
#' sample_data2 <- calculate_ptsd_total(sample_data1)
#' diagnosed_data2 <- create_ptsd_diagnosis_nonbinarized(sample_data2)
#'
#' # Check diagnosis results
#' diagnosed_data2$PTSD_orig
#'
create_ptsd_diagnosis_nonbinarized <- function(data) {
  .validate_pcl5_data(data, strict_cols = FALSE, warn_total = FALSE)

  criteria <- list(
    A = rowSums(data[, paste0("symptom_", 1:5)] >= 2) >= 1,
    B = rowSums(data[, paste0("symptom_", 6:7)] >= 2) >= 1,
    C = rowSums(data[, paste0("symptom_", 8:14)] >= 2) >= 2,
    D = rowSums(data[, paste0("symptom_", 15:20)] >= 2) >= 2
  )

  data$PTSD_orig <- Reduce(`&`, criteria)
  return(data)
}


#' Summarize PTSD scores and diagnoses
#'
#' @description
#' Creates a summary of PCL-5 total scores and PTSD diagnoses, including mean
#' total score, standard deviation, and number of positive diagnoses.
#'
#' @details
#' This function calculates key summary statistics for PCL-5 data:
#'
#' \itemize{
#' \item Mean total score (severity indicator)
#' \item Standard deviation of total scores (variability in severity)
#' \item Count of positive PTSD diagnoses (prevalence in the sample)
#'}
#'
#' @param data A dataframe containing at minimum:
#'
#' \itemize{
#'   \item A 'total' column with PCL-5 total scores (from calculate_ptsd_total)
#'   \item A 'PTSD_orig' column with TRUE/FALSE values (from
#'     determine_ptsd_diagnosis)
#'}
#'
#' @returns A dataframe with one row containing:
#'
#' \itemize{
#'   \item mean_total: Mean PCL-5 total score
#'   \item sd_total: Standard deviation of PCL-5 total scores
#'   \item n_diagnosed: Number of positive PTSD diagnoses
#'}
#'
#' @export
#'
#' @importFrom dplyr summarise
#' @importFrom stats sd
#' @importFrom magrittr %>%
#'
#' @examples
#' # Create sample data
#' sample_data <- data.frame(
#'   total = sample(0:80, 100, replace = TRUE),
#'   PTSD_orig = sample(c(TRUE, FALSE), 100, replace = TRUE)
#' )
#'
#' # Generate summary statistics
#' summary_stats <- summarize_ptsd(sample_data)
#' print(summary_stats)
#'
summarize_ptsd <- function(data) {
  if (!all(c("total", "PTSD_orig") %in% colnames(data))) {
    cli::cli_abort("{.arg data} must contain both {.val total} and {.val PTSD_orig} columns.")
  }

  if (!is.numeric(data$total)) {
    cli::cli_abort("Column {.val total} must contain numeric values.")
  }

  if (any(is.na(data$total))) {
    cli::cli_abort("Column {.val total} contains missing values ({.val NA}).")
  }

  if (any(data$total < 0 | data$total > 80)) {
    cli::cli_abort("Column {.val total} contains invalid values (must be between 0 and 80).")
  }

  if (!is.logical(data$PTSD_orig)) {
    cli::cli_abort("Column {.val PTSD_orig} must contain logical ({.val TRUE}/{.val FALSE}) values.")
  }

  if (any(is.na(data$PTSD_orig))) {
    cli::cli_abort("Column {.val PTSD_orig} contains missing values ({.val NA}).")
  }

  data %>%
    dplyr::summarise(
      mean_total = mean(.data$total),
      sd_total = stats::sd(.data$total),
      n_diagnosed = sum(.data$PTSD_orig)
    )
}
