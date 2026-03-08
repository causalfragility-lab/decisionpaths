#' @export
summary.dp_audit <- function(object, ...) {
  list(
    mean_dosage = mean(object$descriptors$dosage, na.rm = TRUE),
    mean_switching = mean(object$descriptors$switching_rate, na.rm = TRUE),
    dri = object$dri,
    entropy = object$entropy,
    equity = object$equity
  )
}
