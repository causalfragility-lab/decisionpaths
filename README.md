
# decisionpaths <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/decisionpaths)](https://CRAN.R-project.org/package=decisionpaths)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

## Overview

`decisionpaths` is an R package for constructing and auditing
**longitudinal decision paths** from panel data. It implements the
**Decision Infrastructure Paradigm** (Hait, 2025), which
reconceptualises institutional AI systems not as static classifiers but
as infrastructure that generates time-ordered binary decision sequences
— the decision path — as the primary empirical object.

Core functions:

| Function | Description |
|----|----|
| `dp_build()` | Build a `decision_path` object from panel data |
| `dp_describe()` | Per-unit path descriptors: dosage, switching rate, onset, duration |
| `dp_dri()` | Decision Reliability Index (Cronbach, 1951) |
| `dp_entropy()` | Shannon path entropy (Shannon, 1948) |
| `dp_equity()` | Group equity diagnostics via standardized mean differences |
| `dp_audit()` | Full five-step integrated audit |

## Installation

Install the released version from CRAN:

``` r
install.packages("decisionpaths")
```

Install the development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("causalfragility-lab/decisionpaths")
```

## Quick Start

``` r
library(decisionpaths)

# Panel data: 3 students x 4 waves, binary decision (0/1)
dat <- data.frame(
  id       = rep(1:3, each = 4),
  wave     = rep(1:4, times = 3),
  decision = c(1, 1, 1, 1,    # student 1: always treated
               0, 1, 0, 1,    # student 2: high switching
               0, 0, 1, 1),   # student 3: onset at wave 3
  ses      = rep(c("Q1", "Q2", "Q4"), each = 4)
)

# Step 1: Build decision-path object
dp <- dp_build(dat, id, wave, decision, group = ses)

# Step 2: Path descriptors
desc <- dp_describe(dp, by = "ses")
desc$dosage
#> [1] 1.00 0.50 0.50

# Step 3: Decision Reliability Index
dri <- dp_dri(dp)
dri$DRI
#> [1] 0.619

# Step 4: Shannon path entropy
ent <- dp_entropy(dp)
ent$entropy
#> [1] 1.585

# Step 5: Equity diagnostics
eq <- dp_equity(dp, group = "ses")

# Step 6: Full audit
aud <- dp_audit(dp, group = "ses")
```

## Plot Methods

``` r
# Decision path heatmap
plot(dp, type = "heatmap")

# Decision prevalence over time
plot(dp, type = "spaghetti")

# DRI distribution
plot(dri)

# Path entropy
plot(ent)

# Equity SMD chart
plot(eq)
```

## Infrastructure Types

The package operationalises four infrastructure types defined in Hait
(2025):

| Type | Description | DRI | Entropy |
|----|----|----|----|
| I — Static | Decision fixed at baseline, never changes | ~1.0 | Very low |
| II — Periodic | Recalibrated every N waves | ~0.6–0.8 | Medium |
| III — Continuous | Updates every wave (fully adaptive) | ~0.4–0.6 | High |
| IV — Human-in-loop | Algorithmic decision + human override | ~0.3–0.5 | High |

## Simulation Results

A simulation study with N = 200 students × K = 8 waves × 4
infrastructure types (6,400 rows total, seed = 2025) confirms the
theoretical predictions:

| Type             | DRI       | Entropy (bits) | Unique Paths | Q1 vs Q4 Dosage Gap |
|------------------|-----------|----------------|--------------|---------------------|
| I — Static       | **1.000** | 1.00           | 2            | 0.40                |
| II — Periodic    | 0.585     | 6.75           | 127          | 0.49                |
| III — Continuous | 0.616     | 6.54           | 122          | 0.31                |
| IV — Human-loop  | 0.536     | 6.88           | 132          | 0.23                |

All 11 validation checks passed. The full simulation script is in
`inst/examples/simulation_study.R`.

## Companion Stata Package

A companion Stata package `dpath` implementing the same paradigm is
available at: <https://github.com/causalfragility-lab/dpath>

``` stata
* Stata equivalent workflow
dpath build ai_flag, id(studentid) time(wave) group(sesq)
dpath describe, by(sesq)
dpath dri, by(sesq)
dpath entropy
dpath equity, by(sesq)
dpath audit, by(sesq)
```

## References

- Cronbach, L. J. (1951). Coefficient alpha and the internal structure
  of tests. *Psychometrika*, 16(3), 297–334.
  <https://doi.org/10.1007/BF02310555>

- Hait, S. (2025). Artificial intelligence as decision infrastructure:
  Rethinking institutional decision processes. Michigan State
  University. <https://github.com/causalfragility-lab/decisionpaths>

- Shannon, C. E. (1948). A mathematical theory of communication. *Bell
  System Technical Journal*, 27(3), 379–423.
  <https://doi.org/10.1002/j.1538-7305.1948.tb01338.x>

## Citation

``` r
citation("decisionpaths")
```

> Hait, S. (2025). *decisionpaths: Construct and Audit Longitudinal
> Decision Paths*. R package version 0.1.1.
> <https://github.com/causalfragility-lab/decisionpaths>

## Author

**Subir Hait**\
Michigan State University\
<haitsubi@msu.edu>\
ORCID: [0009-0004-9871-9677](https://orcid.org/0009-0004-9871-9677)
