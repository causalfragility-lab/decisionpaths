# tests/testthat/test-dp_build.R

# ── Minimal build ─────────────────────────────────────────────────────────────

test_that("dp_build creates a valid decision_path object", {
  dat <- tibble::tibble(
    id       = c(1, 1, 2, 2),
    time     = c(1, 2, 1, 2),
    decision = c(0, 1, 1, 1)
  )
  dp <- dp_build(dat, id, time, decision)

  # correct S3 class
  expect_s3_class(dp, "decision_path")

  # all required slots present
  expect_true(all(c(
    "paths", "path_strings", "ids", "times",
    "n_units", "n_waves", "balanced",
    "has_outcome", "has_group",
    "id_var", "time_var", "decision_var",
    "outcome_var", "group_var", "decision_labels"
  ) %in% names(dp)))

  # paths is a data frame with correct dimensions
  expect_s3_class(dp$paths, "data.frame")
  expect_equal(nrow(dp$paths), 4)

  # unit and wave counts
  expect_equal(dp$n_units, 2L)
  expect_equal(dp$n_waves, 2L)

  # path strings: one per unit
  expect_length(dp$path_strings, 2)

  # variable names stored correctly
  expect_equal(dp$id_var,       "id")
  expect_equal(dp$time_var,     "time")
  expect_equal(dp$decision_var, "decision")

  # no outcome or group supplied
  expect_false(dp$has_outcome)
  expect_false(dp$has_group)
  expect_null(dp$outcome_var)
  expect_null(dp$group_var)
})

# ── With outcome and group ────────────────────────────────────────────────────

test_that("dp_build stores outcome and group correctly", {
  dat <- tibble::tibble(
    id       = c(1, 1, 2, 2),
    time     = c(1, 2, 1, 2),
    decision = c(0, 1, 1, 0),
    score    = c(50, 55, 60, 58),
    ses      = c("Q1", "Q1", "Q4", "Q4")
  )
  dp <- dp_build(dat, id, time, decision, outcome = score, group = ses)

  expect_true(dp$has_outcome)
  expect_true(dp$has_group)
  expect_equal(dp$outcome_var, "score")
  expect_equal(dp$group_var,   "ses")

  # outcome and group columns present in paths
  expect_true("score" %in% names(dp$paths))
  expect_true("ses"   %in% names(dp$paths))
})

# ── Path strings ──────────────────────────────────────────────────────────────

test_that("dp_build generates correct path strings", {
  dat <- tibble::tibble(
    id       = c(1, 1, 1, 2, 2, 2),
    time     = c(1, 2, 3, 1, 2, 3),
    decision = c(0, 1, 1, 1, 1, 0)
  )
  dp <- dp_build(dat, id, time, decision)

  expect_equal(as.character(dp$path_strings["1"]), "0-1-1")
  expect_equal(as.character(dp$path_strings["2"]), "1-1-0")
})

# ── Sorting ───────────────────────────────────────────────────────────────────

test_that("dp_build sorts by id then time", {
  # Feed data in reverse order
  dat <- tibble::tibble(
    id       = c(2, 2, 1, 1),
    time     = c(2, 1, 2, 1),
    decision = c(0, 1, 0, 1)
  )
  dp <- dp_build(dat, id, time, decision)

  expect_equal(dp$paths$id,   c(1, 1, 2, 2))
  expect_equal(dp$paths$time, c(1, 2, 1, 2))
})

# ── Input validation ──────────────────────────────────────────────────────────

test_that("dp_build errors on non-binary decision", {
  dat <- tibble::tibble(
    id       = c(1, 1),
    time     = c(1, 2),
    decision = c(0, 2)   # invalid
  )
  expect_error(dp_build(dat, id, time, decision), regexp = "binary")
})

test_that("dp_build errors on missing required column", {
  dat <- tibble::tibble(
    id   = c(1, 1),
    time = c(1, 2)
    # decision column missing
  )
  expect_error(dp_build(dat, id, time, decision))
})

# ── Balance detection ─────────────────────────────────────────────────────────

test_that("dp_build detects balanced panels correctly", {
  dat_balanced <- tibble::tibble(
    id       = c(1, 1, 2, 2),
    time     = c(1, 2, 1, 2),
    decision = c(0, 1, 1, 0)
  )
  dp_bal <- dp_build(dat_balanced, id, time, decision)
  expect_true(dp_bal$balanced)

  dat_unbalanced <- tibble::tibble(
    id       = c(1, 1, 1, 2, 2),
    time     = c(1, 2, 3, 1, 2),
    decision = c(0, 1, 0, 1, 1)
  )
  expect_message(
    dp_unbal <- dp_build(dat_unbalanced, id, time, decision),
    regexp = "Unbalanced"
  )
  expect_false(dp_unbal$balanced)
  expect_equal(dp_unbal$n_waves, 3L)
})
