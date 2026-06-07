# Augment the bundled simulated_ptsd dataset with demographic columns.
#
# We load the existing PCL-5 matrix (5,000 x 20) and prepend three columns:
#   patient_id (P0001..P5000), age (truncated normal 18-80), sex (female/male).
#
# Loading the existing matrix rather than regenerating from scratch preserves
# the numerical PCL-5 profile, so tests and worked examples that rely on the
# previous distribution continue to behave identically.

set.seed(2026)

load("data/simulated_ptsd.rda")
stopifnot(is.data.frame(simulated_ptsd),
          ncol(simulated_ptsd) == 20,
          all(grepl("^S[0-9]+$", names(simulated_ptsd))))

n <- nrow(simulated_ptsd)

# Demographic generators ----------------------------------------------------
patient_id <- sprintf("P%04d", seq_len(n))

# Age: truncated normal, mean ~ 42, sd ~ 12, bounded to [18, 80]
age <- pmin(80L, pmax(18L, as.integer(round(rnorm(n, mean = 42, sd = 12)))))

# Sex: ~52% female (a plausible community-sample skew); factor with two levels
sex <- factor(
  sample(c("female", "male"), n, replace = TRUE, prob = c(0.52, 0.48)),
  levels = c("female", "male")
)

simulated_ptsd <- cbind(
  data.frame(patient_id = patient_id,
             age        = age,
             sex        = sex,
             stringsAsFactors = FALSE),
  simulated_ptsd
)

stopifnot(identical(names(simulated_ptsd)[1:3], c("patient_id", "age", "sex")),
          identical(names(simulated_ptsd)[-(1:3)], paste0("S", 1:20)),
          nrow(simulated_ptsd) == n)

usethis::use_data(simulated_ptsd, overwrite = TRUE)
