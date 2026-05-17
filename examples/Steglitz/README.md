
# Steglitz Example – rSTEMMUS-SCOPE Workflow

This example demonstrates a complete reproducible workflow for running **rSTEMMUS-SCOPE** using observational data from the **Berlin-Steglitz urban flux tower site**.

The example illustrates how to:

1. Prepare input data
2. Configure and execute simulations
3. Perform parameter perturbation experiments
4. Evaluate model performance against observations

---

# Site Description

The Steglitz site is an urban ecosystem observation site located in Berlin, Germany.

Available observations include:

- Eddy covariance flux measurements
- Meteorological forcing data
- Soil moisture observations at multiple depths

These observations allow evaluation of model performance under heterogeneous urban environmental conditions.

---

# Workflow Overview

The example consists of four main scripts.

---

## `roadmap_Steglitz.R`

Reusable workflow engine responsible for:

- Data ingestion
- Input preprocessing
- Model configuration
- STEMMUS-SCOPE execution
- Output organization

This script is designed to be reusable across multiple experiments.

---

## `run_baseline.R`

Launcher script for the baseline simulation using default soil hydraulic properties.

---

## `run_porosity_sensitivity.R`

Launcher script for the porosity-sensitivity experiment, where porosity in deeper soil layers is increased programmatically before model execution.

---

## `diagnostic_Steglitz.R`

Evaluation workflow used to:

- Compare simulated and observed soil moisture
- Generate diagnostic plots
- Compute model performance metrics such as:

  - KGE
  - R²
  - RMSE
  - MAE

The same diagnostic workflow can be reused for multiple simulations.

---

# Directory Structure

```text
examples/Steglitz
├── README.md
├── roadmap_Steglitz.R
├── run_baseline.R
├── run_porosity_sensitivity.R
├── diagnostic_Steglitz.R
├── figures/
├── data/
└── outputs/
```

---

# How to Run the Example

## 1. Open the repository in RStudio

Navigate to:

```r
setwd("examples/Steglitz")
```

---

## 2. Run the baseline simulation

```r
source("run_baseline.R")
```

---

## 3. Run the porosity-sensitivity simulation

```r
source("run_porosity_sensitivity.R")
```

---

## 4. Evaluate simulation results

Update the simulation folder path inside:

```text
diagnostic_Steglitz.R
```

Example:

```r
sim_folder <- "D:/model/rSTEMMUS_SCOPE/output/DE-STG_Steglitz_baseline"
```

Then run:

```r
source("diagnostic_Steglitz.R")
```

---

# Expected Output

Running the example will produce:

- Simulated soil moisture time series
- Observed vs simulated comparison plots
- Model performance statistics
- Diagnostic figures for evaluating simulation behavior

These diagnostics help assess how well STEMMUS-SCOPE reproduces observed soil moisture dynamics at the Steglitz site.

---

# Requirements

To run this example, the following software must be installed:

- R (>= 4.1.0)
- MATLAB (required by STEMMUS-SCOPE backend)
- Required R packages used in the workflow

Install the package from GitHub:

```r
devtools::install_github("EcoExtreML/rSTEMMUS_SCOPE")
```

---

# Purpose of this Example

This example demonstrates how rSTEMMUS-SCOPE can be applied to urban ecosystem sites using a fully scripted and reproducible workflow.

The example also illustrates how parameter perturbation experiments can be performed programmatically while preserving full traceability through isolated simulation directories and reusable diagnostic workflows.