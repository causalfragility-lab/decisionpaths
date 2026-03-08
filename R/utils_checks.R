.check_required_cols <- function(data, cols) {
  missing_cols <- setdiff(cols, names(data))
  if (length(missing_cols) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }
}

.check_binary_decision <- function(x) {
  ux <- unique(stats::na.omit(x))
  if (!all(ux %in% c(0, 1))) {
    stop("`decision` must be coded as binary 0/1.", call. = FALSE)
  }
}
