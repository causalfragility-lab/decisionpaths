#' Describe Decision Paths
#'
#' Computes per-unit path descriptors from a \code{decision_path} object,
#' including dosage, switching rate, onset, duration, and longest run.
#'
#' @param x A \code{decision_path} object from \code{\link{dp_build}}.
#' @param by Optional character string naming a group variable for stratified
#'   summaries. Defaults to \code{x$group_var} if set in \code{dp_build}.
#'
#' @return A tibble of class \code{dp_describe} with one row per unit and
#'   columns: \code{id}, \code{n_periods}, \code{treatment_count},
#'   \code{dosage}, \code{switching_rate}, \code{onset}, \code{duration},
#'   \code{longest_run}, \code{path}, \code{group}.
#'
#' @examples
#' dat <- data.frame(
#'   id       = c(1, 1, 2, 2),
#'   time     = c(1, 2, 1, 2),
#'   decision = c(0, 1, 1, 0)
#' )
#' dp   <- dp_build(dat, id, time, decision)
#' desc <- dp_describe(dp)
#' print(desc)
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

  rows_list <- lapply(ids, function(uid) {

    sub     <- paths[paths[[id_var]] == uid, ]
    d       <- sub[[d_var]]
    t       <- sub[[t_var]]
    d_clean <- d[!is.na(d)]

    switching_rate <- if (length(d_clean) < 2L) {
      NA_real_
    } else {
      sum(diff(d_clean) != 0) / (length(d_clean) - 1L)
    }

    first_on <- t[!is.na(d) & d == 1]
    onset    <- if (length(first_on) == 0L) NA_real_ else min(first_on)

    longest_run <- if (length(d_clean) == 0L) {
      0L
    } else {
      r     <- rle(d_clean)
      runs1 <- r$lengths[r$values == 1]
      if (length(runs1) == 0L) 0L else max(runs1)
    }

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

  # Rename id column to match original id_var name
  names(out)[names(out) == "id"] <- id_var

  class(out) <- c("dp_describe", class(out))
  out
}


#' @export
print.dp_describe <- function(x, ...) {
  cli::cli_h2("Decision Path Descriptors")
  cli::cli_text("{nrow(x)} unit(s)")
  NextMethod()
  invisible(x)
}

#' @export
summary.dp_describe <- function(object, ...) {
  print(object, ...)
}
