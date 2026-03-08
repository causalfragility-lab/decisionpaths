# =========================================================
# Internal helper functions for decision path metrics
# =========================================================

# Compute switching rate (fraction of times the decision changes)
.compute_switching_rate <- function(x) {

  x <- stats::na.omit(x)

  if (length(x) <= 1) {
    return(0)
  }

  mean(x[-1] != x[-length(x)])
}


# Compute onset time (first occurrence of decision == 1)
.compute_onset <- function(x) {

  idx <- which(x == 1)

  if (length(idx) == 0) {
    return(NA_integer_)
  }

  min(idx)
}


# Compute total duration of decision == 1
.compute_duration <- function(x) {

  sum(x == 1, na.rm = TRUE)

}


# Compute longest consecutive run of decision == 1
.compute_longest_run <- function(x) {

  if (length(x) == 0) {
    return(0L)
  }

  runs <- rle(x)

  if (!any(runs$values == 1)) {
    return(0L)
  }

  max(runs$lengths[runs$values == 1])
}


# Convert decision vector into a path string
.compute_path_string <- function(x) {

  paste0(x, collapse = "")

}


# Compute Shannon entropy
.compute_entropy <- function(p) {

  p <- p[p > 0]

  -sum(p * log2(p))

}
