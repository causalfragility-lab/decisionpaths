---
title: 'decisionpaths: An R Package for Constructing and Auditing Longitudinal Decision Paths from Panel Data'
tags:
  - R
  - longitudinal data
  - decision infrastructure
  - institutional AI
  - educational research
  - psychometrics
  - equity
authors:
  - name: Subir Hait
    orcid: 0009-0004-9871-9677
    affiliation: 1
affiliations:
  - name: Michigan State University, United States
    index: 1
date: 2026-03-09
bibliography: paper.bib
---

# Summary

`decisionpaths` is an R package for constructing and auditing longitudinal
decision paths from panel data. It implements the **Decision Infrastructure
Paradigm** [@hait2026], which reconceptualises institutional AI systems not
as static classifiers or point-in-time treatments, but as infrastructure that
generates time-ordered sequences of binary decisions — the *decision path* —
as the primary empirical object of analysis.

The package provides a complete five-step audit workflow: (1) building a
`decision_path` object from standard longitudinal data; (2) computing
per-unit path descriptors including dosage, switching rate, onset, and
duration; (3) estimating the Decision Reliability Index (DRI), a psychometric
characterization of infrastructure consistency grounded in classical test
theory [@cronbach1951]; (4) measuring Shannon decision-path entropy
[@shannon1948] as a population-level summary of infrastructure complexity;
and (5) evaluating subgroup equity via standardized mean differences in
path-level outcomes. A companion Stata package, `dpath`, implements the same
workflow for Stata users.

# Statement of Need

Artificial intelligence systems are increasingly embedded in educational
institutions, healthcare organizations, and policy environments, where they
make repeated binary decisions about individuals across time — assigning
interventions, flagging risk, routing resources. Quantitative research has
largely represented these systems in one of three reductive ways: as observed
variables (e.g., risk scores), as binary treatments, or as measurement
instruments [@hait2026]. All three representations share a common limitation:
they obscure the temporal structure of AI-mediated decision processes.

This mis-specification matters because AI-based decision systems generate
*sequences* of institutional actions, not isolated decisions. Two individuals
with identical observed characteristics may receive different cumulative
decision exposures, experience different levels of decision instability, or
encounter AI-mediated interventions at different points in their trajectories.
These path-level differences have direct implications for educational outcomes,
causal inference, and distributional equity [@hait2026].

`decisionpaths` provides the first software implementation of the Decision
Infrastructure Paradigm, enabling researchers to:

- Represent AI-mediated decision systems as generators of time-ordered
  decision sequences rather than as static variables or treatments;
- Quantify the temporal consistency of decision infrastructure using the
  Decision Reliability Index (DRI), defined as $\text{DRI} = 1 -
  \mathbb{E}[\text{Switch}_i]$, where $\text{Switch}_i$ is the individual-level
  switching rate [@hait2026; @cronbach1951];
- Measure decision-path entropy $H^* = -\sum_j p(\omega_j) \log_2 p(\omega_j)$
  as a population-level characterization of infrastructure complexity
  [@shannon1948];
- Classify systems into four infrastructure types — static (Type I),
  periodically recalibrated (Type II), continuously adaptive (Type III), and
  human-in-the-loop (Type IV) — with direct implications for causal
  identification [@hait2026];
- Evaluate group disparities in decision exposure and path stability using
  standardized mean differences, grounding equity assessment at the level of
  decision paths rather than individual decisions.

No existing R package provides this combination of longitudinal path
construction, reliability quantification, entropy measurement, and equity
diagnostics for binary decision sequences in panel data.

# Decision Infrastructure Paradigm

The formal framework represents an AI-mediated decision system observed over
discrete time periods $t = 1, \ldots, T$ through two equations. The
decision-generating process is:

$$D_t = g(A_t, X_t)$$

where $X_t$ is observed information at time $t$ and $A_t$ is the internal
state of the AI system (its decision rules, parameters, or thresholds). The
state-update equation:

$$A_{t+1} = h(A_t, D_t, Y_t)$$

captures how the system adapts over time in response to observed outcomes
$Y_t$. The framework is algorithm-agnostic: it does not require knowledge
of $g(\cdot)$ or $h(\cdot)$. The observable decision path
$\mathcal{P}_i = \{D_{i1}, D_{i2}, \ldots, D_{iT_i}\}$ serves as an
empirical proxy for the underlying infrastructure [@hait2026].

# Core Functions

`decisionpaths` provides six user-facing functions organized around the
five-step Decision Infrastructure Audit:

| Function | Description |
|---|---|
| `dp_build()` | Build a `decision_path` S3 object from panel data |
| `dp_describe()` | Compute per-unit descriptors: dosage, switching rate, onset, duration, longest run |
| `dp_dri()` | Estimate the Decision Reliability Index and switching rate distribution |
| `dp_entropy()` | Compute Shannon path entropy, normalized entropy, and path frequency table |
| `dp_equity()` | Group equity diagnostics via standardized mean differences |
| `dp_audit()` | Full five-step integrated audit |

All functions return S3 objects with associated `print()`, `summary()`, and
`plot()` methods. The `dp_build()` function supports balanced and unbalanced
panels, optional outcome and group variables, and non-standard evaluation for
column name specification.

# Simulation Evidence

A simulation study with $N = 200$ students $\times$ $K = 8$ waves $\times$
4 infrastructure types (6,400 rows total) confirms the theoretical predictions
of the framework (Table 1). Type I (static) infrastructure produces
$\text{DRI} = 1.0$ and $H^* = 1$ bit (two unique paths: all-zero and all-one),
while Type III (continuously adaptive) infrastructure produces
$\text{DRI} = 0.616$ and $H^* = 6.54$ bits across 122 unique paths.
The SES dosage gradient (Q1 mean dosage = 0.72 vs. Q4 = 0.32 in Type I)
illustrates the equity diagnostic capabilities of the package. All 11
pre-specified validation checks passed.

: Simulation results by infrastructure type ($N = 200$, $K = 8$, seed = 2025).

| Type | DRI | Entropy (bits) | Unique Paths | Dosage Gap (Q1 vs Q4) |
|---|---|---|---|---|
| I — Static | **1.000** | 1.00 | 2 | 0.40 |
| II — Periodic | 0.585 | 6.75 | 127 | 0.49 |
| III — Continuous | 0.616 | 6.54 | 122 | 0.31 |
| IV — Human-loop | 0.536 | 6.88 | 132 | 0.23 |

The simulation script is available at
`inst/examples/simulation_study.R` in the package repository.

# Companion Stata Package

A companion Stata package `dpath` implements the same five-step audit
workflow for Stata users, including `dpath build`, `dpath describe`,
`dpath dri`, `dpath entropy`, `dpath equity`, and `dpath audit` subcommands.
The package is available at
[https://github.com/causalfragility-lab/dpath](https://github.com/causalfragility-lab/dpath)
and has been submitted to the Statistical Software Components (SSC) archive.

# Acknowledgements

The author thanks the Michigan State University College of Education for
institutional support. The empirical illustrations in the companion paper
[@hait2026] use data from the Early Childhood Longitudinal Study,
Kindergarten Class of 2010–11 (ECLS-K:2011), publicly available from the
National Center for Education Statistics [@nces2015].

# References
