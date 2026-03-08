#' Compare path descriptors across groups
#'
#' Produces simple subgroup summaries for key decision-path descriptors.
#'
#' @param x A decision_path object
#' @param group Grouping variable name as a character string
#'
#' @return A tibble of grouped summaries
#' @export
dp_equity <- function(x, group) {

  if (!inherits(x, "decision_path")) {
    stop("x must be a decision_path object", call. = FALSE)
  }

  desc <- dp_describe(x)

  if (!group %in% names(desc)) {
    stop("`group` not found in descriptor table", call. = FALSE)
  }

  desc %>%
    dplyr::group_by(.data[[group]]) %>%
    dplyr::summarise(
      n = dplyr::n(),
      mean_dosage = mean(.data$dosage, na.rm = TRUE),
      mean_switching = mean(.data$switching_rate, na.rm = TRUE),
      mean_onset = mean(.data$onset, na.rm = TRUE),
      mean_duration = mean(.data$duration, na.rm = TRUE),
      DRI = 1 - mean(.data$switching_rate, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::rename(group_value = 1)
}
