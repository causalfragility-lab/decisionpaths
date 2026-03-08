#' Build a Decision-Path Object from Panel Data
#'
#' Converts a longitudinal (panel) data frame into a \code{decision_path}
#' object, the core data structure used by all other functions in the package.
#' Supports unbalanced panels and optional outcome and group variables.
#'
#' @param data A data frame in long format (one row per unit-wave).
#' @param id Unquoted name of the unit identifier column.
#' @param time Unquoted name of the time/wave column (numeric or integer).
#' @param decision Unquoted name of the binary decision column (0/1).
#' @param outcome Optional. Unquoted name of the outcome column.
#' @param group Optional. Unquoted name of a grouping column for equity analysis.
#' @param decision_labels Character vector of length 2 labelling decision values
#'   0 and 1. Default \code{c("0", "1")}.
#'
#' @return An object of class \code{decision_path}, which is a list containing:
#' \describe{
#'   \item{paths}{A tibble with one row per unit-wave (cleaned and sorted).}
#'   \item{path_strings}{A named character vector of decision sequences per unit.}
#'   \item{ids}{Unique unit identifiers.}
#'   \item{times}{Sorted unique time points.}
#'   \item{n_units}{Number of units.}
#'   \item{n_waves}{Maximum number of observed waves.}
#'   \item{balanced}{Logical: TRUE if all units have the same number of waves.}
#'   \item{has_outcome}{Logical: TRUE if outcome was supplied.}
#'   \item{has_group}{Logical: TRUE if group was supplied.}
#'   \item{id_var}{Character name of the id column.}
#'   \item{time_var}{Character name of the time column.}
#'   \item{decision_var}{Character name of the decision column.}
#'   \item{outcome_var}{Character or NULL name of the outcome column.}
#'   \item{group_var}{Character or NULL name of the group column.}
#'   \item{decision_labels}{Character vector of length 2.}
#' }
#'
#' @examples
#' dat <- data.frame(
#'   id       = c(1, 1, 2, 2),
#'   time     = c(1, 2, 1, 2),
#'   decision = c(0, 1, 1, 0)
#' )
#' dp <- dp_build(dat, id, time, decision)
#' print(dp)
#'
#' @export
dp_build <- function(data,
                     id,
                     time,
                     decision,
                     outcome         = NULL,
                     group           = NULL,
                     decision_labels = c("0", "1")) {

  # ── 1. Capture variable names ──────────────────────────────────────────────
  id_quo       <- rlang::enquo(id)
  time_quo     <- rlang::enquo(time)
  decision_quo <- rlang::enquo(decision)
  outcome_quo  <- rlang::enquo(outcome)
  group_quo    <- rlang::enquo(group)

  id_var       <- rlang::as_name(id_quo)
  time_var     <- rlang::as_name(time_quo)
  decision_var <- rlang::as_name(decision_quo)

  has_outcome  <- !rlang::quo_is_null(outcome_quo) && !rlang::quo_is_missing(outcome_quo)
  has_group    <- !rlang::quo_is_null(group_quo)   && !rlang::quo_is_missing(group_quo)

  outcome_var  <- if (has_outcome) rlang::as_name(outcome_quo) else NULL
  group_var    <- if (has_group)   rlang::as_name(group_quo)   else NULL

  # ── 2. Validate required columns ───────────────────────────────────────────
  required <- c(id_var, time_var, decision_var)
  missing_cols <- setdiff(required, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort("Column(s) not found in data: {.var {missing_cols}}")
  }
  if (has_outcome && !outcome_var %in% names(data)) {
    cli::cli_abort("Outcome column {.var {outcome_var}} not found in data.")
  }
  if (has_group && !group_var %in% names(data)) {
    cli::cli_abort("Group column {.var {group_var}} not found in data.")
  }

  # ── 3. Validate binary decision ────────────────────────────────────────────
  dec_vals <- unique(data[[decision_var]])
  dec_vals <- dec_vals[!is.na(dec_vals)]
  if (!all(dec_vals %in% c(0, 1))) {
    cli::cli_abort(
      "Column {.var {decision_var}} must be binary (0/1). Found: {dec_vals}"
    )
  }

  # ── 4. Sort panel ──────────────────────────────────────────────────────────
  data <- data[order(data[[id_var]], data[[time_var]]), ]

  # ── 5. Check panel balance ─────────────────────────────────────────────────
  wave_counts <- tapply(data[[time_var]], data[[id_var]], length)
  balanced    <- length(unique(wave_counts)) == 1
  if (!balanced) {
    cli::cli_inform(c(
      "i" = "Unbalanced panel detected: wave counts range from {min(wave_counts)} to {max(wave_counts)}.",
      "i" = "All functions handle unbalanced panels correctly."
    ))
  }

  # ── 6. Build paths tibble ──────────────────────────────────────────────────
  keep_cols <- c(id_var, time_var, decision_var, outcome_var, group_var)
  keep_cols <- keep_cols[!is.null(keep_cols)]
  paths     <- tibble::as_tibble(data[, keep_cols, drop = FALSE])

  # ── 7. Build path strings (one per unit) ───────────────────────────────────
  path_strings <- tapply(
    data[[decision_var]],
    data[[id_var]],
    FUN = function(d) paste(d, collapse = "-")
  )

  # ── 8. Assemble and return object ──────────────────────────────────────────
  structure(
    list(
      paths           = paths,
      path_strings    = path_strings,
      ids             = unique(data[[id_var]]),
      times           = sort(unique(data[[time_var]])),
      n_units         = length(unique(data[[id_var]])),
      n_waves         = max(wave_counts),
      balanced        = balanced,
      has_outcome     = has_outcome,
      has_group       = has_group,
      id_var          = id_var,
      time_var        = time_var,
      decision_var    = decision_var,
      outcome_var     = outcome_var,
      group_var       = group_var,
      decision_labels = decision_labels
    ),
    class = "decision_path"
  )
}
