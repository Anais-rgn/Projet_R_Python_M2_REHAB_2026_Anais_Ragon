# ==========================================================
# STATISTICAL ANALYSIS FOR REPRODUCIBILITY STUDY
# ==========================================================
#
# Scientific Question:
# What is the reproducibility of instrumental angular velocity
# during passive elbow extension in healthy subjects?
#
# Hypothesis:
# Instrumental biomechanical parameters show good intra-session
# reproducibility in healthy subjects.
#
# Author: Anaïs RAGON + Claude 
# Date: 12/05/2026
# ==========================================================

# Part 3 — Intra-Session Reproducibility Analysis

## Objective
Assess the intra-session reproducibility of angular velocity during passive elbow
extension across three speed conditions (slow, medium, fast) using the Intraclass
Correlation Coefficient (ICC).

## Inputs
- `velocity_trials_clean.csv`: exported from Part 2, one row per trial
Columns: `patient_id`, `side`, `speed`, `trial`, `velocity` (°/s)

## Method
1. Data is reshaped from long to wide format: one row per subject, one column per trial
2. ICC is computed using the `irr` package with the following model:
  - `model = "twoway"` — both subjects and trials are treated as random effects
- `type = "agreement"` — absolute agreement (penalizes systematic differences)
- `unit = "single"` — reliability of a single trial, noted ICC(A,1)
3. Packages are installed only if missing (`requireNamespace`) — safe on any machine
4. Results are interpreted using Koo & Mae (2016) thresholds:
  poor < 0.50 / moderate 0.50–0.75 / good 0.75–0.90 / excellent > 0.90

## Outputs
- ICC value, F-test (p-value), and 95% confidence interval per speed condition
- `icc_slow`, `icc_medium`, `icc_fast`: R objects storing full ICC results
- A formatted summary table rendered automatically via `kable`



```{r}
# ----------------------------------------------------------
# INSTALL & LOAD PACKAGES
# Installs only if not already present 
# ----------------------------------------------------------
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
if (!requireNamespace("irr",       quietly = TRUE)) install.packages("irr")
if (!requireNamespace("knitr",     quietly = TRUE)) install.packages("knitr")

library(tidyverse)
library(irr)
library(knitr)
```


```{r}
# ----------------------------------------------------------
# LOAD DATA
# Place velocity_trials_clean.csv in the same folder as this
# .Rmd file, OR adjust the path below.
# ----------------------------------------------------------
df <- read.csv("data/velocity_trials_clean.csv", stringsAsFactors = FALSE)

cat("Rows:", nrow(df), "| Columns:", ncol(df), "\n")
kable(head(df), caption = "Preview — velocity_trials_clean.csv")
```

```{r}
# ----------------------------------------------------------
# ICC ANALYSIS — INTRA-SESSION RELIABILITY
# Model   : twoway (subjects + trials both random)
# Type    : agreement (absolute, penalises systematic bias)
# Unit    : single  → ICC(A,1)
# Ref     : Koo & Mae, J Chiropr Med, 2016
# ----------------------------------------------------------

# Create unique subject ID (patient + side)
df <- df %>%
  mutate(subject = paste(patient_id, side, sep = "_"))

# ----------------------------------------------------------
# FUNCTION: compute ICC for one speed condition
# ----------------------------------------------------------
compute_icc <- function(speed_name, data) {
  
  df_wide <- data %>%
    filter(speed == speed_name) %>%
    select(subject, trial, velocity) %>%
    pivot_wider(names_from  = trial,
                values_from = velocity) %>%
    select(-subject)           # keep numeric columns only
  
  if (nrow(df_wide) < 2 || ncol(df_wide) < 2) {
    cat("\n[WARNING] Not enough data for speed:", speed_name, "\n")
    return(NULL)
  }
  
  res <- icc(df_wide,
             model = "twoway",
             type  = "agreement",
             unit  = "single")
  
  cat("\n============================\n")
  cat("Speed:", speed_name, "\n")
  print(res)
  return(res)
}

# ----------------------------------------------------------
# RUN FOR EACH SPEED CONDITION
# ----------------------------------------------------------
icc_slow   <- compute_icc("slow",   df)
icc_medium <- compute_icc("medium", df)
icc_fast   <- compute_icc("fast",   df)
```