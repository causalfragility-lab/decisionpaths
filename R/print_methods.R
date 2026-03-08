#' @export
print.decision_path <- function(x, ...) {

  dat <- x$data

  n_rows <- nrow(dat)
  n_ids  <- dplyr::n_distinct(dat$id)
  n_time <- length(unique(dat$time))

  cat("<decision_path>\n")
  cat("  Rows:        ", n_rows, "\n", sep = "")
  cat("  Individuals: ", n_ids, "\n", sep = "")
  cat("  Time points: ", n_time, "\n", sep = "")

  invisible(x)
}

#' @export
print.dp_entropy <- function(x, ...) {

  cat("<dp_entropy>\n")
  cat("  Entropy:             ", round(x$entropy, 3), "\n", sep = "")
  cat("  Normalized entropy:  ", round(x$normalized_entropy, 3), "\n", sep = "")

  invisible(x)
}

#' @export
print.dp_audit <- function(x, ...) {

  cat("<dp_audit>\n")
  cat("  Mean DRI:            ", round(mean(x$dri$DRI, na.rm = TRUE), 3), "\n", sep = "")
  cat("  Normalized entropy:  ", round(x$entropy$normalized_entropy, 3), "\n", sep = "")
  cat("  Equity diagnostics:  ", if (!is.null(x$equity)) "yes" else "no", "\n", sep = "")

  invisible(x)
}
