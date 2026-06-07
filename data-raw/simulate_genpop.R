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

# Demographic columns (community sample skew: ~55% female, slightly younger
# than the clinical veterans dataset).
n_gp <- nrow(simulated_ptsd_genpop)
patient_id <- sprintf("G%04d", seq_len(n_gp))
age <- pmin(80L, pmax(18L,
                      as.integer(round(rnorm(n_gp, mean = 38, sd = 14)))))
sex <- factor(
  sample(c("female", "male"), n_gp, replace = TRUE, prob = c(0.55, 0.45)),
  levels = c("female", "male")
)

simulated_ptsd_genpop <- cbind(
  data.frame(patient_id = patient_id,
             age        = age,
             sex        = sex,
             stringsAsFactors = FALSE),
  simulated_ptsd_genpop
)

# ---------------------------------------------------------------------------
# Paired CAPS-5 ratings (C1-C20)
#
# Simulate clinician-administered CAPS-5 severity ratings (0-4) for the SAME
# participants, correlated with the PCL-5 items so the PCL-5 and CAPS-5 TOTAL
# scores correlate ~0.8 (the value typically reported empirically). Because the
# bundled PCL-5 items are independent, the per-item latent correlation roughly
# equals the realized total-score correlation, so we set rho ~ 0.8 per item and
# verify the realized total correlation below.
#
# Method (latent Gaussian copula + marginal matching): for each item, build a
# latent normal from the PCL-5 item, mix in independent noise at the target
# correlation, then assign 0-4 CAPS scores by sorted latent so the CAPS item
# reproduces the PCL-5 item's score distribution.
#
# Note: the genpop PCL-5 items are positively inter-correlated (mixture of
# PTSD-like and non-PTSD profiles), so the summed totals are dominated by that
# shared structure and the total-score correlation is markedly higher than the
# per-item latent correlation. rho is therefore tuned (~0.55) so the realized
# total-score correlation lands near 0.8.
rho <- 0.55  # per-item latent correlation; tuned so total-score r ~ 0.8

pcl_items <- paste0("S", 1:20)
caps_mat  <- matrix(0L, nrow = n, ncol = 20)
for (j in seq_len(20)) {
  s     <- simulated_ptsd_genpop[[pcl_items[j]]]
  z     <- qnorm((rank(s, ties.method = "average") - 0.5) / n)  # latent from PCL
  latent <- rho * z + sqrt(1 - rho^2) * rnorm(n)                # correlated latent
  # Reproduce the PCL item's marginal: assign the same score counts, ordered by latent
  caps_sorted <- s[order(s)]                 # the exact multiset of PCL scores
  caps_j      <- integer(n)
  caps_j[order(latent)] <- caps_sorted       # rank-match latent -> scores
  caps_mat[, j] <- caps_j
}
caps_df <- as.data.frame(caps_mat)
names(caps_df) <- paste0("C", 1:20)

simulated_ptsd_genpop <- cbind(simulated_ptsd_genpop, caps_df)

# Verify realized total-score correlation
realized <- cor(rowSums(simulated_ptsd_genpop[, pcl_items]),
                rowSums(simulated_ptsd_genpop[, paste0("C", 1:20)]))
message(sprintf("Realized PCL-5 vs CAPS-5 total-score correlation: %.3f", realized))

# Save
usethis::use_data(simulated_ptsd_genpop, overwrite = TRUE)
