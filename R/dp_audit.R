#' Run a Decision Path Audit
#'
#' Produces an integrated audit summary including path descriptors, the
#' Decision Reliability Index (DRI), Shannon entropy, and optional subgroup
#' equity diagnostics. This is the flagship function of the
#' \pkg{decisionpaths} package and implements the five-step decision
#' infrastructure audit described in Hait (2025).
#'
#' @param x A \code{decision_path} object from \code{\link{dp_build}}.
#' @param group Optional character string naming a group variable for
#'   stratified DRI and equity diagnostics. The variable must exist in the
#'   original data passed to \code{dp_build}. If the variable is not found
#'   in the path data, a warning is issued and equity diagnostics are skipped.
#'
#' @return An object of class \code{dp_audit}, a named list with components:
#' \describe{
#'   \item{descriptors}{Output of \code{\link{dp_describe}}.}
#'   \item{dri}{Output of \code{\link{dp_dri}}.}
#'   \item{entropy}{Output of \code{\link{dp_entropy}}.}
#'   \item{equity}{Output of \code{\link{dp_equity}}, or \code{NULL} if no
#'     group variable is supplied or found.}
#'   \item{group}{The group variable name used (or \code{NULL}).}
#' }
#'
#' @references
#' Hait, S. (2025). \emph{Artificial intelligence as decision infrastructure:
#' Rethinking institutional decision processes}. Preprint.
#'
#' @examples
#' dat <- data.frame(
#'   id       = c(1, 1, 1, 2, 2, 2),
#'   time     = c(1, 2, 3, 1, 2, 3),
#'   decision = c(0, 1, 1, 1, 1, 0)
#' )
#' dp  <- dp_build(dat, id, time, decision)
#' aud <- dp_audit(dp)
#' print(aud)
#'
#' @export
dp_audit <- function(x, group = NULL) {

  if (!inherits(x, "decision_path")) {
    cli::cli_abort(
      "{.arg x} must be a {.cls decision_path} object from {.fn dp_build}."
    )
  }

  # ── Validate group variable ───────────────────────────────────────────────
  grp <- NULL
  if (!is.null(group)) {
    if (!is.character(group) || length(group) != 1L) {
      cli::cli_abort("{.arg group} must be a single character string.")
    }
    if (group %in% names(x$paths)) {
      grp <- group
    } else {
      cli::cli_warn(c(
        "!" = "Group variable {.val {group}} not found in path data.",
        "i" = "Equity diagnostics will be skipped.",
        "i" = "Supply the group variable via {.arg group_var} in {.fn dp_build} to enable equity analysis."
      ))
    }
  }

  # ── Step 1: Path descriptors ──────────────────────────────────────────────
  desc <- dp_describe(x, by = grp)

  # ── Step 2: Decision Reliability Index ───────────────────────────────────
  dri <- dp_dri(x, by = grp)

  # ── Step 3: Entropy ───────────────────────────────────────────────────────
  ent <- dp_entropy(x, by = grp)

  # ── Step 4: Equity diagnostics (only if group found) ─────────────────────
  eq <- if (!is.null(grp)) {
    tryCatch(
      dp_equity(x, group = grp),
      error = function(e) {
        cli::cli_warn(c(
          "!" = "Equity diagnostics failed: {conditionMessage(e)}",
          "i" = "Returning NULL for equity component."
        ))
        NULL
      }
    )
  } else {
    NULL
  }

  # ── Assemble output ───────────────────────────────────────────────────────
  structure(
    list(
      descriptors = desc,
      dri         = dri,
      entropy     = ent,
      equity      = eq,
      group       = grp
    ),
    class = c("dp_audit", "list")
  )
}


#' @export
print.dp_audit <- function(x, ...) {
  cli::cli_h1("Decision Infrastructure Audit")

  cli::cli_h2("Step 1 \u2014 Path Descriptors")
  print(x$descriptors)

  cli::cli_h2("Step 2 \u2014 Decision Reliability Index")
  print(x$dri)

  cli::cli_h2("Step 3 \u2014 Entropy")
  print(x$entropy)

  if (!is.null(x$equity)) {
    cli::cli_h2("Step 4 \u2014 Equity Diagnostics")
    print(x$equity)
  } else if (!is.null(x$group)) {
    cli::cli_inform("i" = "Equity diagnostics not available.")
  }

  invisible(x)
}

#' @export
summary.dp_audit <- function(object, ...) {
  cli::cli_h1("Decision Infrastructure Audit \u2014 Summary")
  cli::cli_ul(c(
    "Units        : {nrow(object$descriptors)}",
    "DRI          : {round(object$dri$DRI, 3)}",
    "Entropy H*   : {round(object$entropy$entropy, 3)} bits",
    "Unique paths : {object$entropy$n_unique_paths}",
    "Group        : {if (is.null(object$group)) 'none' else object$group}",
    "Equity       : {if (is.null(object$equity)) 'not computed' else 'computed'}"
  ))
  invisible(object)
}
