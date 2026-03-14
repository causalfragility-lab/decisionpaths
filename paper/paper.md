---
title: "decisionpaths: An R Package for Constructing and Auditing Longitudinal Decision Paths from Panel Data"
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

Many institutional systems repeatedly assign binary decisions to the same individuals across time. Examples include early-warning systems that flag students for intervention, clinical decision-support systems that recommend treatments across visits, and automated risk-scoring systems used in public policy. Standard statistical workflows typically analyze such decisions using point-in-time variables or panel models focused on outcomes. These approaches often overlook the structure of the *decision trajectory* itself.

The **decisionpaths** R package provides tools for constructing and auditing longitudinal decision paths from panel data. The package implements the **Decision Infrastructure Paradigm** [@hait2026], which conceptualizes institutional artificial intelligence (AI) systems not as static classifiers but as infrastructures that generate time-ordered sequences of binary decisions. These sequences—referred to as *decision paths*—represent the cumulative institutional actions experienced by individuals across time and serve as the primary empirical object of analysis.

The package implements a five-step workflow for analyzing decision infrastructures. Researchers can construct decision paths from panel data, compute descriptive metrics of decision exposure and stability, estimate a reliability measure for decision assignment, quantify trajectory diversity using information-theoretic measures, and evaluate subgroup disparities in decision trajectories.

The package is designed for researchers working with longitudinal institutional decision data in fields such as education, health systems, public policy, and organizational analytics.

# Statement of Need

Artificial intelligence and algorithmic decision systems are increasingly embedded in institutional environments where decisions are repeatedly applied to the same individuals. Examples include educational early-warning systems that identify students for intervention, clinical decision-support systems that guide treatment recommendations, and automated administrative decision systems used in policy contexts.

Research on such systems typically focuses on prediction accuracy, causal treatment effects, or fairness properties of individual decisions [@barocas2019; @kizilcec2022]. In empirical analyses, algorithmic decisions are usually represented using static indicators or covariates. This representation obscures the temporal structure of institutional decision processes.

In practice, algorithmic systems generate **sequences of decisions over time**. Two individuals with similar observed characteristics may receive different cumulative exposures to interventions, experience different levels of decision instability, or encounter interventions at different points in their trajectories. These differences may influence outcomes, complicate causal interpretation, and contribute to distributional inequalities.

The **decisionpaths** package provides a software implementation of the Decision Infrastructure Paradigm. It enables researchers to represent institutional decision systems as generators of decision trajectories and to compute interpretable diagnostics describing the stability, diversity, and equity implications of these trajectories.

To our knowledge, no existing R package integrates longitudinal path construction, reliability diagnostics, entropy-based complexity measures, and subgroup equity auditing for binary decision sequences in panel data.

# State of the Field

Existing statistical approaches for repeated decisions typically rely on panel models, dynamic treatment regime frameworks, or reinforcement learning approaches for sequential decision problems [@rubin1974; @robins2000; @murphy2003]. While these frameworks model outcomes or optimal policies, they rarely treat the sequence of institutional decisions experienced by each unit as the primary analytical object.

Sequence analysis methods have been used in fields such as sociology and bioinformatics to study ordered event trajectories, but these tools are not widely integrated into standard statistical workflows for panel data analysis in applied social science. As a result, researchers studying institutional AI systems often lack simple tools for describing the structure of decision trajectories themselves.

The **decisionpaths** package addresses this gap by providing tools for reconstructing decision trajectories from panel data and summarizing their structural properties using interpretable statistical diagnostics.

# Decision Infrastructure Paradigm

The Decision Infrastructure Paradigm models an AI-mediated decision system observed across discrete time periods $t = 1, \ldots, T$. The decision-generation process can be represented as

$$
D_t = g(A_t, X_t)
$$

where $X_t$ denotes observed information at time $t$ and $A_t$ represents the internal state of the decision system (such as model parameters, thresholds, or policy rules).

The system state may evolve through a feedback process

$$
A_{t+1} = h(A_t, D_t, Y_t)
$$

where $Y_t$ represents observed outcomes or feedback signals.

The observable **decision path**

$$
\mathcal{P}_i = \{D_{i1}, D_{i2}, \ldots, D_{iT_i}\}
$$

captures the sequence of institutional decisions experienced by unit $i$. Rather than requiring knowledge of the internal algorithmic functions $g(\cdot)$ or $h(\cdot)$, the framework analyzes the empirical structure of these decision trajectories.

# Software Design

The package is organized around the `decision_path` S3 object produced by the function `dp_build()`. This object stores cleaned panel data and reconstructed decision sequences. Subsequent functions operate on this object to compute diagnostics describing the temporal structure of decision systems.

The package provides the following core functions:

| Function | Description |
|---|---|
| `dp_build()` | Build a `decision_path` object from panel data |
| `dp_describe()` | Compute path descriptors including dosage, switching rate, onset, duration, and longest run |
| `dp_dri()` | Estimate the Decision Reliability Index |
| `dp_entropy()` | Compute Shannon decision-path entropy |
| `dp_equity()` | Evaluate subgroup disparities in decision exposure |
| `dp_audit()` | Run the full integrated decision infrastructure audit |

All functions return S3 objects with associated `print()`, `summary()`, and `plot()` methods. The design allows researchers to run individual diagnostics or execute the full workflow using the integrated `dp_audit()` function.

# Simulation Illustration

A small simulation study illustrates how the diagnostics implemented in `decisionpaths` characterize different decision systems. We simulated $N = 200$ units observed across $K = 8$ waves under four stylized decision infrastructures: static systems, periodically recalibrated systems, continuously adaptive systems, and human-in-the-loop systems.

Static infrastructures produce high decision reliability and low entropy, reflecting stable decision assignment across time. In contrast, continuously adaptive systems generate lower reliability and higher entropy, reflecting more complex and variable decision trajectories. Human-in-the-loop systems display moderate reliability with substantial trajectory diversity due to human overrides of algorithmic recommendations.

These results illustrate how the diagnostics implemented in `decisionpaths` distinguish different temporal decision structures and capture variation in cumulative decision exposure across groups. The simulation script used in this illustration is available in the repository at `inst/examples/simulation_study.R`.

# Research Impact

The **decisionpaths** package enables researchers to study institutional decision systems in settings where individuals are repeatedly classified or treated across time. Potential applications include educational placement systems, clinical treatment pathways, epidemiological testing pipelines, and algorithmic decision systems used in public policy and organizational governance.

By focusing on the temporal structure of decisions rather than isolated treatment indicators, the package provides new descriptive tools for analyzing the stability, complexity, and equity implications of institutional decision infrastructures.

# Companion Stata Package

A companion Stata implementation, **dpath**, provides the same workflow for constructing and auditing longitudinal decision paths. The package includes commands `dpath build`, `dpath describe`, `dpath dri`, `dpath entropy`, `dpath equity`, and `dpath audit`.
The package is available from the Statistical Software Components (SSC) archive and can be installed using

```
ssc install dpath
```

# AI Usage Disclosure

AI-assisted tools were used for minor language editing only. All methodological design, theoretical framing, and software implementation were developed and verified by the author.

# References
