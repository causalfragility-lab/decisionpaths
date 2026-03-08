#' Compute the Decision Reliability Index (DRI)
#'
#' Computes the Decision Reliability Index (DRI), a measure of decision
#' consistency defined as 1 minus the mean switching rate across units.
#' A DRI of 1 indicates perfectly consistent decisions; 0 indicates
#' maximum instability.
#'
#' @param x A \code{decision_path} object from \code{\link{dp_build}}.
#' @param by Optional character string naming a group variable for stratified
#'   output. Defaults to \code{x$group_var}.
#'
#' @return A named list of class \code{dp_dri} with components:
#' \describe{
#'   \item{group}{Group label (NA if no group variable).}
#'   \item{mean_switching_rate}{Mean switching rate across units.}
#'   \item{DRI}{Decision Reliability Index = 1 - mean_switching_rate.}
#'   \item{unit_dri}{Per-unit tibble with switching_rate and DRI contribution.}
#'   \item{by_group}{By-group summary tibble (NULL if no group).}
#' }
#'
#' @references
#' Cronbach, L. J. (1951). Coefficient alpha and the internal structure of
#' tests. \emph{Psychometrika}, 16(3), 297--334.
#'
#' Nunnally, J. C. (1978). \emph{Psychometric theory} (2nd ed.). McGraw-Hill.
#'
#' @examples
#' dat <- data.frame(
#'   id       = c(1, 1, 1, 2, 2, 2),
#'   time     = c(1, 2, 3, 1, 2, 3),
#'   decision = c(0, 1, 1, 1, 1, 0)
#' )
#' dp  <- dp_build(dat, id, time, decision)
#' dri <- dp_dri(dp)
#' print(dri)
#'
#' @export
dp_dri <- function(x, by = NULL) {

  if (!inherits(x, "decision_path")) {
    cli::cli_abort(
      "{.arg x} must be a {.cls decision_path} object from {.fn dp_build}."
    )
  }

  paths   <- x$paths
  id_var  <- x$id_var
  d_var   <- x$decision_var
  grp_var <- if (!is.null(by)) by else x$group_var

  # ── Per-unit switching rate ──────────────────────────────────────────────
  ids <- unique(paths[[id_var]])

  unit_rows <- lapply(ids, function(uid) {
    d       <- paths[[d_var]][paths[[id_var]] == uid]
    d_clean <- d[!is.na(d)]
    sr      <- if (length(d_clean) < 2L) {
      NA_real_
    } else {
      sum(diff(d_clean) != 0) / (length(d_clean) - 1L)
    }
    grp_val <- if (!is.null(grp_var) && grp_var %in% names(paths)) {
      paths[[grp_var]][paths[[id_var]] == uid][1L]
    } else {
      NA
    }
    data.frame(
      id             = uid,
      switching_rate = sr,
      group          = grp_val,
      stringsAsFactors = FALSE
    )
  })

  unit_tbl <- tibble::as_tibble(do.call(rbind, unit_rows))
  names(unit_tbl)[names(unit_tbl) == "id"] <- id_var

  mean_sr <- mean(unit_tbl$switching_rate, na.rm = TRUE)
  dri_val <- 1 - mean_sr

  # Overall group label
  grp_label <- if (!is.null(grp_var) && grp_var %in% names(paths)) {
    grp_var
  } else {
    NA_character_
  }

  # ── By-group summary ─────────────────────────────────────────────────────
  by_group <- NULL
  if (!is.null(grp_var) && grp_var %in% names(unit_tbl)) {
    grp_vals <- unique(unit_tbl$group)
    by_group <- do.call(rbind, lapply(grp_vals, function(g) {
      sub <- unit_tbl[unit_tbl$group == g & !is.na(unit_tbl$group), ]
      msr <- mean(sub$switching_rate, na.rm = TRUE)
      data.frame(
        group                = g,
        n                    = nrow(sub),
        mean_switching_rate  = msr,
        DRI                  = 1 - msr,
        stringsAsFactors     = FALSE
      )
    }))
    names(by_group)[names(by_group) == "group"] <- grp_var
    by_group <- tibble::as_tibble(by_group)
  }

  # ── Return flat named list matching test expectations ─────────────────────
  # names(out) must include: "group", "mean_switching_rate", "DRI"
  structure(
    list(
      group               = grp_label,
      mean_switching_rate = mean_sr,
      DRI                 = dri_val,
      unit_dri            = unit_tbl,
      by_group            = by_group,
      group_var           = grp_var
    ),
    class = c("dp_dri", "list")
  )
}


#' @export
print.dp_dri <- function(x, ...) {
  cli::cli_h2("Decision Reliability Index (DRI)")
  cli::cli_ul(c(
    "Mean switching rate : {round(x$mean_switching_rate, 3)}",
    "DRI                 : {round(x$DRI, 3)}"
  ))
  if (!is.null(x$by_group)) {
    cli::cli_h3("By group:")
    print(x$by_group, n = Inf)
  }
  invisible(x)
}

#' @export
summary.dp_dri <- function(object, ...) print(object, ...)
