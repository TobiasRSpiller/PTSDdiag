
<!-- README.md is generated from README.Rmd. Please edit that file -->

# PTSDdiag

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/PTSDdiag)](https://CRAN.R-project.org/package=PTSDdiag)
[![R-CMD-check](https://github.com/TobiasRSpiller/PTSDdiag/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/TobiasRSpiller/PTSDdiag/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

<p>

<a href="https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.html" class="btn btn-primary btn-lg">Getting
Started</a>
<a href="https://tobiasrspiller.github.io/PTSDdiag/articles/comparing-criteria.html" class="btn btn-outline-primary btn-lg">Comparing
Criteria</a>
<a href="https://tobiasrspiller.github.io/PTSDdiag/reference/index.html" class="btn btn-outline-primary btn-lg">Reference</a>
<a href="https://doi.org/10.31219/osf.io/6rk72_v1" class="btn btn-outline-secondary btn-lg">Publication</a>
</p>

## Description

PTSDdiag is a comprehensive R package for analyzing and simplifying PTSD
diagnostic criteria using PCL-5 (PTSD Checklist for DSM-5) data. It
provides tools to identify optimal subsets of six PCL-5 items that
maintain diagnostic accuracy while reducing assessment burden.

## **Key Features**

- Data preparation and standardization for PCL-5 scores
- Implementation of DSM-5 diagnostic criteria
- Calculation of diagnostic metrics and summary statistics
- Simplification of diagnostic criteria through:
  - Hierarchical (cluster-based) approach
  - Non-hierarchical approach
- Comparison of different diagnostic approaches
- Model validation using:
  - Holdout Validation
  - Cross-Validation

## Installation

You can install the released version of PTSDdiag from
[CRAN](https://CRAN.R-project.org/package=PTSDdiag):

``` r
install.packages("PTSDdiag")
```

Or install the development version from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("TobiasRSpiller/PTSDdiag")
```

## Getting Started

The vignettes demonstrate how to prepare PCL-5 data, find the optimal
minimal symptom combinations for PTSD diagnosis, compare different
diagnostic approaches (including ICD-11 and the clinician-administered
CAPS-5), and validate the resulting definitions within and across
cohorts.

- [Getting started with
  PTSDdiag](https://tobiasrspiller.github.io/PTSDdiag/articles/getting-started.html)
- [Comparing diagnostic
  criteria](https://tobiasrspiller.github.io/PTSDdiag/articles/comparing-criteria.html)
- [Validating abbreviated symptom
  definitions](https://tobiasrspiller.github.io/PTSDdiag/articles/validation.html)
- [Validating a shared definition across
  sites](https://tobiasrspiller.github.io/PTSDdiag/articles/multi-site-validation.html)
- [CAPS-5
  workflow](https://tobiasrspiller.github.io/PTSDdiag/articles/caps5-workflow.html)
- [Package Website](https://tobiasrspiller.github.io/PTSDdiag/)

## Bugs, Contributions

- If you have any suggestions or if you find a bug, please report them
  using GitHub [issue
  tracker](https://github.com/TobiasRSpiller/PTSDdiag/issues).
- Contributions are welcome! Please feel free to submit a Pull Request.
