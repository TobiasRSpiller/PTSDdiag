# Tests for the bundled datasets

test_that("simulated_ptsd has demographics + 20 PCL-5 items", {
  data("simulated_ptsd", package = "PTSDdiag")
  expect_equal(nrow(simulated_ptsd), 5000)
  expect_equal(names(simulated_ptsd)[1:3], c("patient_id", "age", "sex"))
  expect_true(all(paste0("S", 1:20) %in% names(simulated_ptsd)))
})

test_that("simulated_ptsd_genpop carries paired PCL-5 and CAPS-5 items", {
  data("simulated_ptsd_genpop", package = "PTSDdiag")
  d <- simulated_ptsd_genpop

  expect_equal(ncol(d), 43L)
  expect_equal(names(d)[1:3], c("patient_id", "age", "sex"))
  expect_true(all(paste0("S", 1:20) %in% names(d)))
  expect_true(all(paste0("C", 1:20) %in% names(d)))

  # Both instruments use the 0-4 severity scale
  expect_true(all(unlist(d[, paste0("S", 1:20)]) %in% 0:4))
  expect_true(all(unlist(d[, paste0("C", 1:20)]) %in% 0:4))

  # PCL-5 and CAPS-5 total scores correlate ~0.8 (realistic, not chance)
  r <- cor(rowSums(d[, paste0("S", 1:20)]), rowSums(d[, paste0("C", 1:20)]))
  expect_gt(r, 0.7)
  expect_lt(r, 0.9)
})
