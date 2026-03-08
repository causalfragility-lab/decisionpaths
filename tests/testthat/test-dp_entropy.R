#' Compute Decision Path Entropy
#'
#' Computes Shannon entropy (H) of the decision-path distribution, grounded
#' in information theory (Shannon, 1948). Entropy is measured in bits.
#'
#' @param x A \code{decision_path} object from \code{\link{dp_build}}.
#' @param by Optional character string naming a group variable for stratified
#'   entropy. Defaults to \code{x$group_var}.
#' @param mutual_info Logical. Compute mutual information between path and
#'   group? Default \code{FALSE}.
#'
#' @return An object of class \code{dp_entropy}, a named list with:
#' \describe{
#'   \item{entropy}{Shannon entropy H in bits.}
#'   \item{normalized_entropy}{H divided by log2(number of unique paths).}
#'   \item{path_frequencies}{A tibble of path strings, counts, and proportions.}
#'   \item{n_unique_paths}{Number of unique decision paths observed.}
#'   \item{by_group}{By-group entropy tibble (NULL if no group).}
#'   \item{mutual_info}{Mutual information in bits (NULL if not requested).}
#'   \item{group_var}{Group variable name used.}
#' }
#'
#' @references
#' Shannon, C. E. (1948). A mathematical theory of communication.
#' \emph{Bell System Technical Journal}, 27(3), 379--423.
#'
#' @examples
#' dat <- data.frame(
#'   id       = c(1, 1, 1, 2, 2, 2),
#'   time     = c(1, 2, 3, 1, 2, 3),
#'   decision = c(0, 1, 1, 1, 1, 0)
#' )
#' dp  <- dp_build(dat, id, time, decision)
#' ent <- dp_entropy(dp)
#' print(ent)
#'
#' @export
dp_entropy <- function(x, by = NULL, mutual_info = FALSE) {

  if (!inherits(x, "decision_path")) {
    cli::cli_abort(
      "{.arg x} must be a {.cls decision_path} object from {.fn dp_build}."
    )
  }

  # ── Pull path strings ─────────────────────────────────────────────────────
  # dp_build stores path_strings as a named character vector (one per unit)
  path_strings <- as.character(x$path_strings)
  grp_var      <- if (!is.null(by)) by else x$group_var

  # ── Shannon entropy helper ────────────────────────────────────────────────
  .shannon <- function(strings) {
    freq  <- table(strings)
    probs <- as.numeric(freq) / sum(freq)
    probs <- probs[probs > 0]
    -sum(probs * log2(probs))
  }

  # ── Overall entropy ───────────────────────────────────────────────────────
  H          <- .shannon(path_strings)
  n_unique   <- length(unique(path_strings))
  H_norm     <- if (n_unique <= 1L) 0 else H / log2(n_unique)

  # ── Path frequency table  (slot name: path_frequencies) ───────────────────
  freq_raw  <- as.data.frame(
    table(path_string = path_strings),
    stringsAsFactors = FALSE
  )
  names(freq_raw)[names(freq_raw) == "Freq"] <- "count"
  freq_raw$proportion <- freq_raw$count / sum(freq_raw$count)
  freq_raw  <- freq_raw[order(-freq_raw$count), ]
  path_frequencies <- tibble::as_tibble(freq_raw)

  # ── By-group entropy ──────────────────────────────────────────────────────
  by_group <- NULL
  mi       <- NULL

  if (!is.null(grp_var) && grp_var %in% names(x$paths)) {

    id_var  <- x$id_var
    paths   <- x$paths

    # Build unit-level data frame: path_string + group
    uid_vec <- names(x$path_strings)
    path_df <- data.frame(
      uid      = as.character(uid_vec),
      path_str = path_strings,
      stringsAsFactors = FALSE
    )
    names(path_df)[names(path_df) == "uid"] <- id_var

    group_map           <- paths[!duplicated(paths[[id_var]]),
                                 c(id_var, grp_var)]
    group_map[[id_var]] <- as.character(group_map[[id_var]])
    path_df             <- merge(path_df, group_map, by = id_var, all.x = TRUE)

    grp_vals <- unique(path_df[[grp_var]])
    by_group <- do.call(rbind, lapply(grp_vals, function(g) {
      sub  <- path_df[path_df[[grp_var]] == g, ]
      H_g  <- .shannon(sub$path_str)
      n_g  <- length(unique(sub$path_str))
      data.frame(
        group          = g,
        n              = nrow(sub),
        entropy        = H_g,
        n_unique_paths = n_g,
        normalized_entropy = if (n_g <= 1L) 0 else H_g / log2(n_g),
        stringsAsFactors = FALSE
      )
    }))
    names(by_group)[names(by_group) == "group"] <- grp_var
    by_group <- tibble::as_tibble(by_group)

    # ── Mutual information ────────────────────────────────────────────────
    if (mutual_info) {
      joint   <- table(path_df$path_str, path_df[[grp_var]])
      p_joint <- joint / sum(joint)
      p_path  <- rowSums(p_joint)
      p_grp   <- colSums(p_joint)
      mi_val  <- 0
      for (i in seq_len(nrow(p_joint))) {
        for (j in seq_len(ncol(p_joint))) {
          pij <- p_joint[i, j]
          if (pij > 0) {
            mi_val <- mi_val + pij * log2(pij / (p_path[i] * p_grp[j]))
          }
        }
      }
      mi <- mi_val
    }
  }

  # ── Return — slot names must match tests ──────────────────────────────────
  # Required: "entropy", "normalized_entropy", "path_frequencies"
  structure(
    list(
      entropy            = H,
      normalized_entropy = H_norm,
      path_frequencies   = path_frequencies,
      n_unique_paths     = n_unique,
      by_group           = by_group,
      mutual_info        = mi,
      group_var          = grp_var
    ),
    class = c("dp_entropy", "list")
  )
}


#' @export
print.dp_entropy <- function(x, ...) {
  cli::cli_h2("Decision Path Entropy")
  cli::cli_ul(c(
    "Shannon entropy H   : {round(x$entropy, 3)} bits",
    "Normalized entropy  : {round(x$normalized_entropy, 3)}",
    "Unique paths        : {x$n_unique_paths}"
  ))
  if (!is.null(x$mutual_info)) {
    cli::cli_li(
      "Mutual information (path ~ group): {round(x$mutual_info, 3)} bits"
    )
  }
  cli::cli_h3("Top 5 paths:")
  print(utils::head(x$path_frequencies, 5L))
  if (!is.null(x$by_group)) {
    cli::cli_h3("Entropy by group ({x$group_var}):")
    print(x$by_group, n = Inf)
  }
  invisible(x)
}

#' @export
summary.dp_entropy <- function(object, ...) print(object, ...)
