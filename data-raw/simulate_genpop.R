# Generate simulated general population PCL-5 dataset
# Target: ~20% PTSD prevalence (vs. ~94% in the veterans simulated_ptsd)
# N = 1,200 observations, 20 symptoms (S1-S20), 0-4 scale
#
# Approach: Mixture of ~17% "PTSD-like" profiles (elevated scores)
# and ~83% "non-PTSD" profiles (low scores), with noise.

set.seed(2025)
n <- 1200
ptsd_group <- round(n * 0.17)
non_ptsd_group <- n - ptsd_group

# Non-PTSD group: mostly 0s and 1s, occasional 2+
non_ptsd <- matrix(
  sample(0:4, non_ptsd_group * 20, replace = TRUE,
         prob = c(0.50, 0.28, 0.13, 0.06, 0.03)),
  nrow = non_ptsd_group, ncol = 20
)

# PTSD group: elevated scores (similar to veterans data)
ptsd <- matrix(
  sample(0:4, ptsd_group * 20, replace = TRUE,
         prob = c(0.05, 0.10, 0.20, 0.30, 0.35)),
  nrow = ptsd_group, ncol = 20
)

simulated_ptsd_genpop <- as.data.frame(rbind(non_ptsd, ptsd))
names(simulated_ptsd_genpop) <- paste0("S", 1:20)

# Shuffle rows so PTSD cases are not at the end
simulated_ptsd_genpop <- simulated_ptsd_genpop[sample(nrow(simulated_ptsd_genpop)), ]
rownames(simulated_ptsd_genpop) <- NULL

# Save
usethis::use_data(simulated_ptsd_genpop, overwrite = TRUE)
