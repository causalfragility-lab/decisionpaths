test_that("dp_audit returns expected components", {
  dat <- tibble::tibble(
    id = c(1,1,1,2,2,2,3,3,3,4,4,4),
    time = c(1,2,3,1,2,3,1,2,3,1,2,3),
    decision = c(0,1,1,1,1,0,0,0,0,1,0,1),
    group = c("Low","Low","Low",
              "High","High","High",
              "Low","Low","Low",
              "High","High","High")
  )

  dp <- dp_build(dat, id, time, decision, group = group)
  out <- dp_audit(dp, group = "group")

  expect_s3_class(out, "dp_audit")
  expect_true(all(c("descriptors", "dri", "entropy", "equity") %in% names(out)))
})
