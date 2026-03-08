# R/plot_methods.R
# S3 plot methods for all decisionpaths classes
# All non-ASCII characters written as \uxxxx escapes
# Global variable bindings declared to satisfy R CMD check

utils::globalVariables(c(
  "prev", "value", "dri", "smd", "metric", "comparison"
))


# ── Shared helpers ────────────────────────────────────────────────────────────

.require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(c(
      "Package {.pkg ggplot2} is required for plotting.",
      "i" = "Install it with {.code install.packages('ggplot2')}."
    ))
  }
}

.require_tidyr <- function() {
  if (!requireNamespace("tidyr", quietly = TRUE)) {
    cli::cli_abort(c(
      "Package {.pkg tidyr} is required for this plot.",
      "i" = "Install it with {.code install.packages('tidyr')}."
    ))
  }
}

.dp_theme <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold", size = 12),
      plot.subtitle = ggplot2::element_text(color = "grey40", size = 10),
      legend.title  = ggplot2::element_blank()
    )
}


# ── plot.decision_path ────────────────────────────────────────────────────────

#' Plot a decision_path object
#'
#' Produces a heatmap or spaghetti plot of sampled decision paths across
#' units and time periods.
#'
#' @param x A \code{decision_path} object from \code{\link{dp_build}}.
#' @param type Character. \code{"heatmap"} (default) or \code{"spaghetti"}.
#' @param sample_n Integer. Maximum number of units to display. Default 50.
#' @param ... Ignored.
#'
#' @return A \code{ggplot2} object.
#' @export
plot.decision_path <- function(x, type = "heatmap", sample_n = 50L, ...) {
  .require_ggplot2()

  id_var <- x$id_var
  t_var  <- x$time_var
  d_var  <- x$decision_var
  paths  <- x$paths

  all_ids    <- unique(paths[[id_var]])
  sample_ids <- if (length(all_ids) > sample_n) sample(all_ids, sample_n) else all_ids
  pd         <- paths[paths[[id_var]] %in% sample_ids, ]

  if (type == "heatmap") {
    ggplot2::ggplot(
      pd,
      ggplot2::aes(
        x    = factor(pd[[t_var]]),
        y    = factor(pd[[id_var]]),
        fill = factor(pd[[d_var]])
      )
    ) +
      ggplot2::geom_tile(color = "white", linewidth = 0.3) +
      ggplot2::scale_fill_manual(
        values = c("0" = "#D9E8F5", "1" = "#2166AC"),
        labels = x$decision_labels,
        name   = "Decision"
      ) +
      ggplot2::labs(
        title    = "Decision Paths \u2014 Heatmap",
        subtitle = paste0(length(sample_ids), " sampled units"),
        x = "Wave", y = "Unit"
      ) +
      .dp_theme() +
      ggplot2::theme(
        axis.text.y  = ggplot2::element_blank(),
        axis.ticks.y = ggplot2::element_blank(),
        panel.grid   = ggplot2::element_blank()
      )

  } else if (type == "spaghetti") {
    ggplot2::ggplot(
      pd,
      ggplot2::aes(
        x     = pd[[t_var]],
        y     = pd[[d_var]],
        group = factor(pd[[id_var]])
      )
    ) +
      ggplot2::geom_line(alpha = 0.15, color = "#2166AC") +
      ggplot2::stat_summary(
        ggplot2::aes(group = 1),
        fun       = mean,
        geom      = "line",
        color     = "#D73027",
        linewidth = 1.2
      ) +
      ggplot2::scale_y_continuous(
        breaks = c(0, 1),
        labels = x$decision_labels
      ) +
      ggplot2::labs(
        title    = "Decision Paths \u2014 Spaghetti Plot",
        subtitle = "Red line = mean prevalence across units",
        x = "Wave", y = "Decision"
      ) +
      .dp_theme()

  } else {
    cli::cli_abort("{.arg type} must be {.val heatmap} or {.val spaghetti}.")
  }
}


# ── plot.dp_describe ──────────────────────────────────────────────────────────

#' Plot a dp_describe object
#'
#' Produces density or histogram plots of path descriptor distributions,
#' optionally stratified by group.
#'
#' @param x A \code{dp_describe} object from \code{\link{dp_describe}}.
#' @param metrics Character vector of metrics to plot. Defaults to
#'   \code{c("dosage", "switching_rate", "onset")}.
#' @param ... Ignored.
#'
#' @return A \code{ggplot2} object.
#' @export
plot.dp_describe <- function(x,
                             metrics = c("dosage", "switching_rate", "onset"),
                             ...) {
  .require_ggplot2()
  .require_tidyr()

  # dp_describe now returns a flat tibble, not a nested list
  unit <- if (inherits(x, "data.frame")) x else x$unit_level
  if (is.null(unit)) {
    cli::cli_abort(
      "{.arg x} does not appear to be a valid {.cls dp_describe} object."
    )
  }

  grp_var <- attr(x, "group_var")
  if (is.null(grp_var) && "group" %in% names(unit)) grp_var <- "group"

  metrics <- intersect(metrics, names(unit))
  if (length(metrics) == 0L) {
    cli::cli_abort("None of the requested metrics found in the descriptor table.")
  }

  keep <- c(if (!is.null(grp_var) && grp_var %in% names(unit)) grp_var,
            metrics)
  plot_data <- tidyr::pivot_longer(
    unit[, keep, drop = FALSE],
    cols      = tidyr::all_of(metrics),
    names_to  = "metric",
    values_to = "value"
  )

  if (!is.null(grp_var) && grp_var %in% names(plot_data)) {
    ggplot2::ggplot(
      plot_data,
      ggplot2::aes(x = value, fill = plot_data[[grp_var]])
    ) +
      ggplot2::geom_density(alpha = 0.5, color = NA) +
      ggplot2::facet_wrap(~metric, scales = "free") +
      ggplot2::labs(
        title = "Path Descriptor Distributions by Group",
        x = NULL, y = "Density", fill = grp_var
      ) +
      ggplot2::scale_fill_brewer(palette = "Set2") +
      .dp_theme()
  } else {
    ggplot2::ggplot(plot_data, ggplot2::aes(x = value)) +
      ggplot2::geom_histogram(
        bins = 20L, fill = "#2166AC", color = "white", alpha = 0.85
      ) +
      ggplot2::facet_wrap(~metric, scales = "free") +
      ggplot2::labs(
        title = "Path Descriptor Distributions",
        x = NULL, y = "Count"
      ) +
      .dp_theme()
  }
}


# ── plot.dp_dri ───────────────────────────────────────────────────────────────

#' Plot a dp_dri object
#'
#' Produces a histogram or density plot of per-unit switching rates with
#' the overall DRI marked.
#'
#' @param x A \code{dp_dri} object from \code{\link{dp_dri}}.
#' @param ... Ignored.
#'
#' @return A \code{ggplot2} object.
#' @export
plot.dp_dri <- function(x, ...) {
  .require_ggplot2()

  unit_tbl <- x$unit_dri
  grp_var  <- x$group_var

  subtitle <- paste0(
    "Overall DRI = ", round(x$DRI, 3),
    "  |  Mean switching rate = ", round(x$mean_switching_rate, 3)
  )

  if (!is.null(grp_var) && !is.na(grp_var) && grp_var %in% names(unit_tbl)) {
    ggplot2::ggplot(
      unit_tbl,
      ggplot2::aes(x = unit_tbl$switching_rate, fill = unit_tbl[[grp_var]])
    ) +
      ggplot2::geom_density(alpha = 0.5, color = NA) +
      ggplot2::geom_vline(
        xintercept = x$mean_switching_rate,
        color = "#D73027", linewidth = 1, linetype = "dashed"
      ) +
      ggplot2::scale_x_continuous(limits = c(0, 1)) +
      ggplot2::labs(
        title    = "Decision Reliability Index (DRI)",
        subtitle = subtitle,
        x = "Switching Rate", y = "Density",
        fill = grp_var
      ) +
      ggplot2::scale_fill_brewer(palette = "Set2") +
      .dp_theme()
  } else {
    ggplot2::ggplot(unit_tbl, ggplot2::aes(x = unit_tbl$switching_rate)) +
      ggplot2::geom_histogram(
        bins = 20L, fill = "#4DAC26", color = "white", alpha = 0.9
      ) +
      ggplot2::geom_vline(
        xintercept = x$mean_switching_rate,
        color = "#D73027", linewidth = 1
      ) +
      ggplot2::scale_x_continuous(limits = c(0, 1)) +
      ggplot2::labs(
        title    = "Decision Reliability Index (DRI)",
        subtitle = subtitle,
        x = "Switching Rate", y = "Count"
      ) +
      .dp_theme()
  }
}


# ── plot.dp_entropy ───────────────────────────────────────────────────────────

#' Plot a dp_entropy object
#'
#' Produces a bar chart of the most frequent decision paths.
#'
#' @param x A \code{dp_entropy} object from \code{\link{dp_entropy}}.
#' @param top Integer. Number of top paths to display. Default 10.
#' @param ... Ignored.
#'
#' @return A \code{ggplot2} object.
#' @export
plot.dp_entropy <- function(x, top = 10L, ...) {
  .require_ggplot2()

  freq <- utils::head(x$path_frequencies, top)
  freq$path_string <- factor(freq$path_string, levels = rev(freq$path_string))

  ggplot2::ggplot(
    freq,
    ggplot2::aes(x = freq$proportion, y = freq$path_string)
  ) +
    ggplot2::geom_col(fill = "#762A83", alpha = 0.85) +
    ggplot2::labs(
      title    = "Decision Path Frequency Distribution",
      subtitle = paste0(
        "H* = ", round(x$entropy, 3),
        " bits  |  Normalized = ", round(x$normalized_entropy, 3),
        "  |  Unique paths = ", x$n_unique_paths
      ),
      x = "Proportion of units",
      y = "Path sequence"
    ) +
    .dp_theme()
}


# ── plot.dp_equity ────────────────────────────────────────────────────────────

#' Plot a dp_equity object
#'
#' Produces a dot plot of standardized mean differences (SMDs) across
#' path descriptor metrics and group comparisons.
#'
#' @param x A \code{dp_equity} object from \code{\link{dp_equity}}.
#' @param ... Ignored.
#'
#' @return A \code{ggplot2} object.
#' @export
plot.dp_equity <- function(x, ...) {
  .require_ggplot2()

  smd_data <- x$smd_table
  smd_data <- smd_data[
    smd_data$metric %in%
      c("dosage", "switching_rate", "onset", "duration", "dri"), ]

  ggplot2::ggplot(
    smd_data,
    ggplot2::aes(
      x     = smd_data$smd,
      y     = smd_data$metric,
      color = smd_data$comparison,
      shape = smd_data$comparison
    )
  ) +
    ggplot2::geom_point(size = 3.5) +
    ggplot2::geom_vline(
      xintercept = 0, linetype = "dashed", color = "grey50"
    ) +
    ggplot2::geom_vline(
      xintercept = c(-0.2, 0.2),
      linetype = "dotted", color = "#D73027", alpha = 0.6
    ) +
    ggplot2::labs(
      title    = "Equity Diagnostics \u2014 Standardized Mean Differences",
      subtitle = paste0(
        "Reference group: ", x$ref_level,
        "  |  Dotted lines = SMD \u00b10.2"
      ),
      x = "SMD", y = "Metric"
    ) +
    ggplot2::scale_color_brewer(palette = "Dark2") +
    .dp_theme()
}


# ── plot.dp_audit ─────────────────────────────────────────────────────────────

#' Plot a dp_audit object
#'
#' Produces a multi-panel summary figure combining DRI distribution,
#' prevalence over time, dosage distribution, and equity SMDs. Requires
#' \pkg{patchwork} for the combined layout; falls back to DRI panel alone.
#'
#' @param x A \code{dp_audit} object from \code{\link{dp_audit}}.
#' @param ... Ignored.
#'
#' @return A \code{ggplot2} or \code{patchwork} object.
#' @export
plot.dp_audit <- function(x, ...) {
  .require_ggplot2()

  p1 <- plot(x$dri)

  prev_data <- x$classification$signals$prevalence_by_wave
  t_col     <- names(prev_data)[1L]

  p2 <- ggplot2::ggplot(
    prev_data,
    ggplot2::aes(
      x = prev_data[[t_col]],
      y = prev_data[["prev"]]
    )
  ) +
    ggplot2::geom_line(color = "#2166AC", linewidth = 1) +
    ggplot2::geom_point(color = "#2166AC", size = 2.5) +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(
      title    = "Decision Prevalence Over Time",
      subtitle = paste0(
        x$classification$type, " \u2014 ",
        x$classification$type_label
      ),
      x = "Wave", y = "Proportion assigned"
    ) +
    .dp_theme()

  p3 <- plot(x$descriptors, metrics = "dosage")

  has_pw     <- requireNamespace("patchwork", quietly = TRUE)
  has_equity <- !is.null(x$equity)

  if (has_equity) {
    p4 <- plot(x$equity)
    if (has_pw) {
      (p1 + p2) / (p3 + p4) +
        patchwork::plot_annotation(
          title    = "Decision Infrastructure Audit",
          subtitle = paste0(
            "H* = ", round(x$entropy$entropy, 3),
            " bits  |  DRI = ", round(x$dri$DRI, 3)
          )
        )
    } else {
      cli::cli_inform(
        "i" = "Install {.pkg patchwork} for the full multi-panel layout."
      )
      p1
    }
  } else {
    if (has_pw) {
      (p1 + p2) / p3 +
        patchwork::plot_annotation(title = "Decision Infrastructure Audit")
    } else {
      p1
    }
  }
}
