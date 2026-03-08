#' Describe Decision Paths
#'
#' Computes per-unit path descriptors from a \code{decision_path} object,
#' including dosage, switching rate, onset wave, duration, and longest run.
#' Returns a flat tibble — one row per unit — so that all descriptors are
#' directly accessible as columns (e.g. \code{desc$dosage}).
#'
#' @param x A \code{decision_path} object from \code{\link{dp_build}}.
#' @param by Optional character string naming a group variable for stratified
#'   summaries. Defaults to \code{x$group_var} if set in \code{\link{dp_build}}.
#'
#' @return A tibble of class \code{dp_describe} with one row per unit and
#'   columns:
#' \describe{
#'   \item{id}{Unit identifier (column name matches original data).}
#'   \item{n_periods}{Number of observed waves for this unit.}
#'   \item{treatment_count}{Number of waves with decision = 1.}
#'   \item{dosage}{Proportion of waves with decision = 1.}
#'   \item{switching_rate}{Proportion of consecutive waves where decision changed.}
#'   \item{onset}{First wave where decision = 1 (NA if never treated).}
#'   \item{duration}{Total number of waves with decision = 1 (same as treatment_count).}
#'   \item{longest_run}{Length of longest uninterrupted run of decision = 1.}
#'   \item{path}{Decision sequence as a string e.g. \code{"0-1-1-0"}.}
#'   \item{group}{Group value (NA if no group variable supplied).}
#' }
#'
#' @examples
#' dat <- data.frame(
#'   id       = c(1, 1, 2, 2),
#'   time     = c(1, 2, 1, 2),
#'   decision = c(0, 1, 1, 0)
#' )
#' dp   <- dp_build(dat, id, time, decision)
#' desc <- dp_describe(dp)
#' desc$dosage
#' desc$path
#'
#' @export
dp_describe <- function(x, by = NULL) {

  if (!inherits(x, "decision_path")) {
    cli::cli_abort(
      "{.arg x} must be a {.cls decision_path} object from {.fn dp_build}."
    )
  }

  paths   <- x$paths
  id_var  <- x$id_var
  t_var   <- x$time_var
  d_var   <- x$decision_var
  grp_var <- if (!is.null(by)) by else x$group_var

  ids <- unique(paths[[id_var]])

  # ── Per-unit computation ──────────────────────────────────────────────────
  rows_list <- lapply(ids, function(uid) {

    sub     <- paths[paths[[id_var]] == uid, ]
    d       <- sub[[d_var]]
    t       <- sub[[t_var]]
    d_clean <- d[!is.na(d)]

    # Switching rate: proportion of consecutive pairs that differ
    switching_rate <- if (length(d_clean) < 2L) {
      NA_real_
    } else {
      sum(diff(d_clean) != 0L) / (length(d_clean) - 1L)
    }

    # Onset: first wave where decision == 1
    first_on <- t[!is.na(d) & d == 1L]
    onset    <- if (length(first_on) == 0L) NA_real_ else min(first_on)

    # Longest consecutive run of decision == 1
    longest_run <- if (length(d_clean) == 0L) {
      0L
    } else {
      r     <- rle(d_clean)
      runs1 <- r$lengths[r$values == 1L]
      if (length(runs1) == 0L) 0L else max(runs1)
    }

    # Group value for this unit
    grp_val <- if (!is.null(grp_var) && grp_var %in% names(sub)) {
      sub[[grp_var]][1L]
    } else {
      NA
    }

    data.frame(
      id              = uid,
      n_periods       = nrow(sub),
      treatment_count = sum(d == 1L, na.rm = TRUE),
      dosage          = mean(d == 1L, na.rm = TRUE),
      switching_rate  = switching_rate,
      onset           = onset,
      duration        = sum(d == 1L, na.rm = TRUE),
      longest_run     = longest_run,
      path            = paste(d, collapse = "-"),
      group           = grp_val,
      stringsAsFactors = FALSE
    )
  })

  out <- tibble::as_tibble(do.call(rbind, rows_list))

  # Rename generic "id" column back to the original id variable name
  names(out)[names(out) == "id"] <- id_var

  class(out) <- c("dp_describe", class(out))
  out
}


#' @export
print.dp_describe <- function(x, ...) {
  cli::cli_h2("Decision Path Descriptors")
  cli::cli_text("{nrow(x)} unit(s)")
  cli::cli_text(
    "Mean dosage        : {round(mean(x$dosage, na.rm = TRUE), 3)}"
  )
  cli::cli_text(
    "Mean switching rate: {round(mean(x$switching_rate, na.rm = TRUE), 3)}"
  )
  cli::cli_text(
    "Mean duration      : {round(mean(x$duration, na.rm = TRUE), 3)}"
  )
  cli::cli_text(
    "Unique paths       : {length(unique(x$path))}"
  )
  grp_col <- if ("group" %in% names(x) &&
                 !all(is.na(x$group))) "group" else NULL
  if (!is.null(grp_col)) {
    cli::cli_h3("Mean dosage by group:")
    grp_means <- tapply(x$dosage, x$group, mean, na.rm = TRUE)
    print(round(sort(grp_means, decreasing = TRUE), 3))
  }
  invisible(x)
}

#' @export
summary.dp_describe <- function(object, ...) print(object, ...)
