# Extracted from test-alternative_criteria.R:302

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "PTSDdiag", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
make_pcl5 <- function(...) {
  scores <- list(...)
  base   <- as.list(stats::setNames(rep(0L, 20L), paste0("symptom_", 1:20)))
  for (nm in names(scores)) base[[nm]] <- scores[[nm]]
  as.data.frame(base)
}
icd11_cases <- rbind(
  # row 1: all three ICD-11 clusters present; also meets DSM-5-TR
  #   (B: item 1; C: item 6; D: items 8,9; E: items 15,16) -> PTSD_orig TRUE
  make_pcl5(symptom_1 = 3, symptom_2 = 3, symptom_3 = 3,
            symptom_6 = 3, symptom_7  = 3,
            symptom_8 = 3, symptom_9  = 3,
            symptom_15 = 3, symptom_16 = 3, symptom_17 = 3),
  # row 2: re-experiencing absent (items 1-3 all 0) -> ICD-11 FALSE
  make_pcl5(symptom_6 = 3, symptom_7  = 3,
            symptom_16 = 3, symptom_17 = 3),
  # row 3: avoidance absent (items 6-7 all 0) -> ICD-11 FALSE
  make_pcl5(symptom_1 = 3, symptom_2 = 3, symptom_3 = 3,
            symptom_16 = 3, symptom_17 = 3),
  # row 4: sense-of-current-threat absent (items 17-18 all 0) -> ICD-11 FALSE
  make_pcl5(symptom_1 = 3, symptom_2 = 3, symptom_3 = 3,
            symptom_6 = 3, symptom_7  = 3)
)
combo_df <- apply_symptom_combinations(
  icd11_cases,
  combinations = list(c(1, 6, 8, 10, 15, 19)),
  n_required   = 1L
)
caps5_cases <- rbind(
  make_pcl5(symptom_1 = 3, symptom_2 = 3, symptom_3 = 3,
            symptom_6 = 3, symptom_7 = 3,
            symptom_8 = 3, symptom_9 = 3,
            symptom_15 = 3, symptom_16 = 3, symptom_17 = 3),
  make_pcl5(symptom_1 = 3, symptom_6 = 3,
            symptom_8 = 3, symptom_9 = 3,
            symptom_15 = 3, symptom_16 = 3),
  make_pcl5(),
  make_pcl5()
)

# test -------------------------------------------------------------------------
result <- compare_diagnostic_systems(
    icd11_cases, combo_df,
    icd11 = TRUE, caps5_data = caps5_cases
  )
expect_true("DSM-5-TR (PCL-5)"  %in% result$system)
expect_true("DSM-5-TR (CAPS-5)" %in% result$system)
expect_true("ICD-11 (PCL-5)"    %in% result$system)
expect_equal(ncol(result), 13L)
