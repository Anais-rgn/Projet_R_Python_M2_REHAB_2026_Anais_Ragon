Projet_R_Python_M2_REHAB_2026 : Master's internship Anaïs RAGON + Claude — May 2026
# Pilot Study — Intra-Session Reproducibility of Instrumental Elbow Extension Velocity in Healthy Subjects

---

## 1. Scientific Background

### 1.1 Context

Spasticity is a frequent motor symptom following central nervous system injury (stroke, traumatic brain injury, spinal cord injury). It is defined as a **velocity-dependent increase in muscle tone**, causing functional limitations, pain, and significant impairment in daily life activities.

Current clinical assessment relies on standardised scales such as the **Modified Tardieu Scale (MTS)** and the **Modified Ashworth Scale (MAS**). However, these tools have well-documented limitations, in particular **poor inter- and intra-rater reproducibility**, which limits their reliability for longitudinal monitoring and clinical research.

Inertial Measurement Units (IMU) and portable dynamometers now offer the possibility of obtaining **objective, quantified, and reproducible measurements**. Combining these two technologies could provide a precise instrumental quantification of spasticity.

### 1.2 Overall Study

This pilot study is part of a larger observational study conducted at **CHU Montpellier (Lapeyronie Hospital, MPR department)**:

> *"Evaluation of the reliability of a portable device combining inertial sensors and a dynamometer for the analysis of elbow flexor spasticity in hemiparetic patients."*

**Primary objective of the main study:** Assess inter- and intra-rater reproducibility of instrumental spasticity measurement (IMU + dynamometer) in hemiparetic patients, compared to the Modified Tardieu Scale.

**Main inclusion criteria:** Age ≥ 18, post-stroke hemiparesis with clinical elbow spasticity (MAS ≥ 1), signed informed consent.

**Statistical analysis:** ICC (two-way mixed model), Spearman correlations, descriptive analyses. Target sample: **n = 40 patients**.

### 1.3 This Pilot Study

Before recruiting patients, a **feasibility and reliability pilot study was conducted on healthy subjects** to:
- Test the measurement pipeline on clean, artefact-free data
- Assess the **intra-session reproducibility** of kinematic parameters derived from the device
- Identify technical and methodological limitations before the main study

> **Scientific question:** What is the intra-session reproducibility of instrumental angular velocity during passive elbow extension in healthy subjects?

> **Hypothesis:** Instrumental biomechanical parameters show good intra-session reproducibility in healthy subjects.

---

## 2. Experimental Setup

### 2.1 Participants

3 healthy subjects, bilateral measurements (right and left) → **6 limbs analysed**.

### 2.2 Protocol

Passive elbow extension was performed in a standardised position according to the study protocol, at **3 speed conditions**, each repeated **3 times**:

| Condition | Label | Target duration |
|-----------|-------|----------------|
| Slow | V1 — `slow` | ~5 s (metronome-guided) |
| Medium | V2 — `medium` | ~2 s |
| Fast | V3 — `fast` | < 1 s |

Both limbs (right / left) were tested for each subject.

### 2.3 Instrumentation

| Device | Type | Acquisition frequency |
|--------|------|-----------------------|
| **K-Push** | Portable dynamometer | 1000 Hz |
| **K-Move** (× 2) | Inertial sensors (IMU) | 250 Hz |

### 2.4 Raw Signals Recorded

- Force (Newtons) — from K-Push
- Quaternions (orientation in 3D space) — from K-Move sensors
- Time series (seconds)

### 2.5 Derived Variables Analysed

- Mean **angular velocity** (°/s)


---

## 3. Analysis Pipeline

```
Raw CSV files (K-Push + K-Move)
        │
        ▼
[Part 1 — Python]  Data parsing & angle computation
        │   • Separate K-Push and K-Move blocks
        │   • Extract quaternions (wrist: S121577 / shoulder: S121578)
        │   • Convert quaternions → elbow angle (°)
        │
        ▼
[Part 2 — Python]  Application of Filter, Event detection & velocity analysis
        │   • Low-pass Butterworth filter (4th order, cutoff 10 Hz)
        │   • Peak detection (find_peaks) → 9 extensions, 9 flexions
        │   • Group by speed: trials 1–3 = slow, 4–6 = medium, 7–9 = fast
        │   • Compute angular velocity per trial (°/s)
        │   • Export → velocity_trials_clean.csv
        │
        ▼
[Part 3 — R]  Intra-session reproducibility (ICC)
            • ICC(A,1) — twoway agreement model
            • One ICC per speed condition (slow / medium / fast)
            • Interpretation: Koo & Mae (2016) thresholds
```

---

## 4. Project Structure

```
project/
│
├── data/
│   ├── Data_Ch_D.csv          # Raw data — subject Ch, right arm
│   ├── Data_Ch_G.csv          # Raw data — subject Ch, left arm
│   ├── Data_Lo_D.csv
│   ├── Data_Lo_G.csv
│   ├── Data_Ca_D.csv
│   ├── Data_Ca_G.csv
│   └── velocity_trials_clean.csv   # Exported from Part 2, input for R
│
├── Part1_parsing_angles.ipynb      # Data loading, quaternion → angle
├── Part2_detection_analysis.ipynb  # Filtering, peak detection, velocity
├── Part3_ICC_analysis.Rmd          # Reproducibility — ICC in R
│
└── README.md
```

---

## 5. Results

### 5.1 ICC Results

| Speed | ICC(A,1) | p-value | 95% CI | Interpretation |
|-------|----------|---------|--------|----------------|
| Slow | 0.27 | 0.067 | [–0.06 ; 0.78] | Poor |
| Medium | 0.11 | 0.301 | [–0.28 ; 0.73] | Poor |
| Fast | 0.77 | < 0.001 | [0.38 ; 0.96] | Good |

*Interpretation thresholds: Koo & Mae, J Chiropr Med, 2016.*

### 5.2 Critical Analysis

These results must be interpreted with **major caution** for two cumulative reasons:

**⚠️ Reason 1 — Unreliable trough (flexion) detection**

The most significant technical limitation of this pipeline is the **automatic detection of flexion minima**. Despite numerous strategies tested to improve minimum detection, none produced fully satisfactory results:

- Simple `find_peaks` on the inverted signal → missed troughs between long pauses
- Segment-based search between consecutive peaks → troughs sometimes detected during rest periods (> 5 s pause), not during actual flexion
- Prominence and distance thresholds → improved peak detection but did not resolve trough instability
- Padding with `np.pad(mode='edge')` when fewer troughs than expected → artificially duplicates the last valid trough
- Forward/backward fill (`ffill`/`bfill`) on missing events → propagates erroneous values

As a consequence, **several angular velocity values are incorrect**, as they are computed from a wrongly detected start (trough) or end (peak) of movement. The velocity = amplitude / duration formula directly depends on the accuracy of both endpoints.

**⚠️ Reason 2 — Insufficient sample size**

With only **n = 6 limbs**, statistical power is very limited. The very wide confidence intervals for slow (–0.06 to 0.78) and medium (–0.28 to 0.73) conditions — both including zero or negative values — reflect this limitation rather than true poor reproducibility.

**Conclusion:** The ICC values computed in this pilot study **do not carry valid clinical meaning**. They are based on partially erroneous velocity data (detection issue) from an underpowered sample (n = 6). These results nonetheless provide valuable methodological insight for improving the pipeline before the main study.

---
title: "Intra-Session Reproducibility of Instrumental Elbow Extension Velocity in Healthy Subjects"
author: "Anaïs RAGON"
date: "2026-05-12"
output:
  html_document:
    theme: flatly
    highlight: tango
    toc: true
    toc_float: true
    toc_depth: 4
    number_sections: false
    df_print: kable

---

## 0. Project Accessibility

The project is available on GitHub at this link:
[https://github.com/Anais-rgn/Projet_R_Python_M2_REHAB_2026_Anais_Ragon](https://github.com/Anais-rgn/Projet_R_Python_M2_REHAB_2026_Anais_Ragon)

---

## 1. Scientific Problem

### 1.1. Context

Spasticity is a frequent motor symptom following central nervous system injury (stroke, traumatic brain injury, spinal cord injury). It is defined as a **velocity-dependent increase in muscle tone**, causing functional limitations, pain, and significant impairment in daily life activities.

Current clinical assessment relies on standardised scales such as the **Modified Tardieu Scale (MTS)** and the Modified Ashworth Scale (MAS). However, these tools have well-documented limitations, in particular **poor inter- and intra-rater reproducibility**, which limits their reliability for longitudinal monitoring and clinical research.

Inertial Measurement Units (IMU) and portable dynamometers now offer the possibility of obtaining **objective, quantified, and reproducible measurements**. Combining these two technologies could provide a precise instrumental quantification of spasticity.

**What we are looking for:** Obtain an objective, portable, and standardised measure of spasticity that is reliable and reproducible enough for clinical research and routine practice in Physical Medicine and Rehabilitation (PMR).

### 1.2. Aim

The aim of this pilot study is to assess the **intra-session reproducibility** of instrumental angular velocity during passive elbow extension in healthy subjects, as a necessary preliminary validation step before the main clinical study on hemiparetic patients.

This pilot study is part of a larger observational study conducted at **CHU Montpellier (Lapeyronie Hospital, PMR department)**:

> *"Evaluation of the reliability of a portable device combining inertial sensors and a dynamometer for the analysis of elbow flexor spasticity in hemiparetic patients"* — target sample: n = 40 patients.

### 1.3. Method

Three healthy subjects performed **passive elbow extension** movements in a standardised position at **3 speed conditions**, each repeated **3 times**, on both arms (right and left).

| Condition | Label | Target duration | Guidance |
|-----------|-------|-----------------|----------|
| Slow | V1 — `slow` | ~5 s | Metronome |
| Medium | V2 — `medium` | ~2 s | Metronome |
| Fast | V3 — `fast` | < 1 s | Metronome |

**Instrumentation:**

| Device | Type | Sampling frequency |
|--------|------|--------------------|
| **K-Push** (M122648) | Portable dynamometer | 1000 Hz |
| **K-Move** (S121577) | IMU — wrist sensor | 250 Hz |
| **K-Move** (S121578) | IMU — shoulder sensor | 250 Hz |

### 1.4. Participants

Three healthy subjects, bilateral measurements → **6 limbs** analysed (subjects: Ch, Lo, Ca).

### 1.5. Outcome Measures

**Raw signals recorded:**

- Force (Newtons) — from K-Push
- Quaternions (3D orientation: x, y, z, w) — from K-Move sensors
- Time series (seconds)

**Derived variables analysed:**

- Mean  **angular velocity** (°/s) 

The main outcome measure is **mean angular velocity** (°/s), computed for each extension trial as:

$$\text{velocity} = \frac{\theta_{max} - \theta_{min}}{t_{end} - t_{start}} \quad (°/s)$$

where $\theta_{max}$ and $\theta_{min}$ are the angle at the extension peak and the preceding flexion trough, and $t_{end} - t_{start}$ is the movement duration in seconds.

---

## 2. Aim of the Code

The objective of this project is to:

1. Load and parse raw CSV files from the IMU + dynamometer device (K-Push / K-Move) — **Python Part 1**
2. Convert quaternion data into elbow angle time-series (°) — **Python Part 1**
3. Automatically detect extension peaks and flexion troughs in the filtered signal — **Python Part 2**
4. Compute angular velocity per trial (°/s) and categorise trials by speed condition — **Python Part 2**
5. Export a clean dataset ready for statistical analysis — **Python Part 3**
6. Assess **intra-session reproducibility** using the Intraclass Correlation Coefficient (ICC) — **R**

---

## 3. Data Organisation

### 3.1. Raw Data Files (Python input)

One CSV file per subject × side (6 files total):

```
data/
├── Data_Ch_D.csv    # Subject Ch — right arm
├── Data_Ch_G.csv    # Subject Ch — left arm
├── Data_Lo_D.csv
├── Data_Lo_G.csv
├── Data_Ca_D.csv
└── Data_Ca_G.csv
```

Each file contains **two merged data blocks**, identified by keywords:

| Block | Keyword | Content | Columns |
|-------|---------|---------|---------|
| **K-Push** | `K-Push` | Force data at 1000 Hz | `time (s)` · `CHANNEL_1` = Force (N) |
| **K-Move** | `K-Move` | Quaternion data at 250 Hz | `time (s)` · `qx` · `qy` · `qz` · `qw` (× 2 sensors) |

Between the two blocks, **baseline quaternions** are recorded for each sensor, representing the reference orientation at the start of the measurement.

> ⚠️ File structure varied across subjects (block order, column separators) — a robust parser was required to handle these differences automatically.

### 3.2. Processed Data File (R input)

**File:** `velocity_trials_clean.csv` — exported from Python Part 3

| Column | Description |
|--------|-------------|
| `patient_id` | Subject identifier (Ch, Lo, Ca) |
| `side` | Limb side (`right` / `left`) |
| `speed` | Speed condition (`slow` / `medium` / `fast`) |
| `trial` | Trial number within each group (1, 2, 3) |
| `velocity` | Mean angular velocity (°/s) |

> One row per trial — 6 subjects × 3 speeds × 3 trials = **54 rows total**.

---

## 4. Script Organisation

### 4.1. Python — Part 1: Data Parsing & Angle Computation (section 5.1)

- **Aim:** Load raw CSV files, extract quaternion data from both IMU sensors, and compute elbow angle time-series
- **Input:** `Data_[ID]_[D/G].csv` files in `data/` folder
- **Output:** `all_angles` — angle time-series (columns: `time`, `angle`) per subject × side

### 4.2. Python — Part 2: Event Detection & Velocity Analysis (section 5.2)

- **Aim:** Filter the signal, automatically detect extension peaks and flexion troughs, compute angular velocity per trial
- **Input:** `all_angles` from Part 1
- **Key parameters:** filter cutoff 10 Hz · min peak prominence 15° · min distance between peaks 1.5 s
- **Output:** `resultats` dictionary + `all_events_long` list

> ⚠️ **Known limitation:** Trough (flexion minimum) detection was unreliable despite multiple strategies tested. Several velocity values may be incorrect as a consequence (see section 5.2.2).

### 4.3. Python — Part 3: Data Export for ICC (section 5.3)

- **Aim:** Standardise column names, number each trial within its group, and export the final dataset
- **Input:** `all_events_long` from Part 2
- **Output:** `velocity_trials_clean.csv` saved in `data/` folder

### 4.4. R — ICC Analysis (section 5.4)

- **Aim:** Assess intra-session reproducibility of angular velocity for each speed condition
- **Input:** `velocity_trials_clean.csv`
- **Calculation:** ICC(A,1) — twoway agreement model, single unit (Koo & Mae, 2016)
- **Output:** ICC value, F-test (p-value), 95% confidence interval, and summary table per speed condition

---

## 5. Code

---

### 5.1. Python Part 1 — Data Parsing & Angle Computation

> *The following sections describe the Python code run in `Part1_parsing_angles.ipynb`. Code is shown here for documentation and reproducibility purposes.*

#### 5.1.1. Imports and patient configuration

The script imports standard scientific libraries and defines the patient dictionary associating each subject with their raw data files.








```{r, eval=FALSE}
import os
import warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from io import StringIO

warnings.filterwarnings('ignore')

PATIENTS = {
    "P01": {"id": "Ch", "right": "Data_Ch_D.csv", "left": "Data_Ch_G.csv"},
    "P02": {"id": "Lo", "right": "Data_Lo_D.csv", "left": "Data_Lo_G.csv"},
    "P03": {"id": "Ca", "right": "Data_Ca_D.csv", "left": "Data_Ca_G.csv"},
}
```

#### 5.1.2. File loading and parsing functions

`load_data()` searches for each CSV file across multiple possible directories (robust to different working directory configurations). `process_file()` separates the K-Push and K-Move blocks, extracts baseline quaternions, and returns clean DataFrames for force and quaternion data.

```{r, eval=FALSE}
def load_data(filename):
    for base_dir in [os.path.join("..", "data"), os.path.join(".", "data"), "."]:
        path = os.path.join(base_dir, filename)
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                return f.readlines()
        if os.path.isdir(base_dir):
            matches = [f for f in os.listdir(base_dir)
                       if f.lower() == filename.lower()]
            if matches:
                with open(os.path.join(base_dir, matches[0]),
                          "r", encoding="utf-8") as f:
                    return f.readlines()
    raise FileNotFoundError(f"File not found: {filename}")


def process_file(filename):
    lines     = load_data(filename)
    idx_push  = next(i for i, l in enumerate(lines) if "K-Push" in l)
    idx_move  = next(i for i, l in enumerate(lines) if "K-Move" in l)

    if idx_push < idx_move:
        push_lines = lines[idx_push:idx_move]
        move_lines = lines[idx_move:]
    else:
        push_lines = lines[idx_push:]
        move_lines = lines[idx_move:idx_push]

    # K-Push block
    header_push = next(i for i, l in enumerate(push_lines) if "temps" in l)
    df_push = pd.read_csv(
        StringIO("".join(push_lines[header_push:])),
        sep=r"\t|,", engine="python"
    ).dropna(axis=1, how='all')
    df_push = df_push.rename(
        columns={"temps (seconde)": "time", "CHANNEL_1": "force"})
    df_push = df_push[["time", "force"]].apply(
        pd.to_numeric, errors='coerce').dropna()

    # Baseline quaternions
    baseline = {"wrist": [], "shoulder": []}
    for line in move_lines:
        if "Quaternion de base" in line:
            parts  = line.strip().split("\t") if "\t" in line \
                     else line.strip().split(",")
            values = [float(x) for x in parts[1:] if _is_float(x)][:4]
            if "S121577" in parts[0]:
                baseline["wrist"]    = values
            elif "S121578" in parts[0]:
                baseline["shoulder"] = values

    # K-Move block
    header_move = next(i for i, l in enumerate(move_lines) if "temps" in l)
    rows = [
        (l.strip().split("\t") if "\t" in l else l.strip().split(","))
        for l in move_lines[header_move + 1:]
    ]
    df_move = pd.DataFrame(rows).dropna(axis=1, how='all')
    df_move = df_move.apply(pd.to_numeric, errors='coerce').ffill().bfill()

    df_wrist    = df_move.iloc[:, [0,1,2,3,4]].copy()
    df_shoulder = df_move.iloc[:, [0,6,7,8,9]].copy()
    for df in [df_wrist, df_shoulder]:
        df.columns = ["time", "qx", "qy", "qz", "qw"]

    return df_push, df_wrist, df_shoulder, baseline
```

#### 5.1.3. Quaternion mathematics and angle computation

A quaternion is a mathematical representation of 3D orientation (x, y, z, w). The elbow angle is derived by computing the **relative rotation** between the current orientation and the baseline (reference position), using standard quaternion algebra.

```{r, eval=FALSE}
def quat_conjugate(q):
    return np.array([-q[0], -q[1], -q[2], q[3]])

def quat_multiply(q1, q2):
    x1,y1,z1,w1 = q1
    x2,y2,z2,w2 = q2
    return np.array([
        w1*x2 + x1*w2 + y1*z2 - z1*y2,
        w1*y2 - x1*z2 + y1*w2 + z1*x2,
        w1*z2 + x1*y2 - y1*x2 + z1*w2,
        w1*w2 - x1*x2 - y1*y2 - z1*z2
    ])

def normalize(q):
    return q / np.linalg.norm(q)

def compute_angle(df_quat, baseline_quat, baseline_deg=30):
    q_base_inv = quat_conjugate(normalize(np.array(baseline_quat)))
    angles = []
    for i in range(len(df_quat)):
        q = normalize(np.array([
            df_quat["qx"].iloc[i], df_quat["qy"].iloc[i],
            df_quat["qz"].iloc[i], df_quat["qw"].iloc[i]
        ]))
        q_rel     = quat_multiply(q_base_inv, q)
        qx,qy,qz,qw = q_rel
        angle = np.arctan2(2*(qw*qy + qx*qz), 1 - 2*(qy**2 + qz**2))
        angles.append(angle)
    angles  = np.degrees(np.unwrap(angles))
    angles -= angles[0]
    if np.mean(angles) < 0:
        angles = -angles
    angles += baseline_deg
    return df_quat[["time"]].assign(angle=angles)
```

#### 5.1.4. Main loop — output

For each patient and each side, the file is parsed and the elbow angle time-series is computed and stored in `all_angles[patient][side]` as a DataFrame with columns `time` and `angle` (°). One angle vs. time graph is produced per subject × side.

---

### 5.2. Python Part 2 — Event Detection & Velocity Analysis

> *The following sections describe the Python code run in `Part2_detection_analysis.ipynb`.*

#### 5.2.1. Signal filtering and peak detection

The raw angle signal is smoothed using a **4th-order zero-phase Butterworth low-pass filter** (cutoff: 10 Hz). Extension peaks are then detected using `find_peaks` with a minimum prominence of 15° and a minimum distance of 1.5 s between peaks.

```{r, eval=FALSE}
from scipy.signal import butter, filtfilt, find_peaks

N_MAX        = 9     # max extension peaks
N_MIN        = 10    # max flexion troughs
MIN_PROM     = 15    # minimum prominence (degrees)
MIN_DIST_SEC = 1.5   # minimum distance between peaks (seconds)
FILTER_CUTOFF = 10   # cutoff frequency (Hz)

def filtrer_signal(signal, cutoff, fs):
    b, a = butter(4, min(cutoff / (0.5 * fs), 0.99), btype='low')
    return filtfilt(b, a, signal)
```

#### 5.2.2. Trough detection — known limitation

> ⚠️ **This is the major technical limitation of this pipeline.**

Flexion minima (troughs) are required to define the start of each extension trial. Despite multiple strategies tested, none produced fully satisfactory results:

| Strategy tested | Issue encountered |
|----------------|-------------------|
| `find_peaks` on inverted signal | Missed troughs between long rest pauses |
| Segment-based search between consecutive peaks | Troughs sometimes detected during rest periods (> 5 s) |
| Prominence and distance thresholds | Improved peak detection, did not resolve trough instability |
| `np.pad(mode='edge')` when fewer troughs than expected | Artificially duplicates the last valid trough |
| `ffill` / `bfill` on missing events | Propagates erroneous trough values |

**Consequence:** since `velocity = amplitude / duration` depends entirely on accurate trough and peak positions, **several angular velocity values are incorrect**. This directly impacts the ICC results computed in R.

#### 5.2.3. Velocity computation and speed categorisation

For each detected event, angular velocity is computed and labelled by speed category based on trial order: trials 1–3 = **slow**, 4–6 = **medium**, 7–9 = **fast**.

```{r, eval=FALSE}
CATEGORIES = ['slow'] * 3 + ['medium'] * 3 + ['fast'] * 3

# For each event i:
t0, t1    = time[creux[i]], time[pics[i]]
duree     = t1 - t0
amplitude = signal[pics[i]] - signal[creux[i]]
velocity  = amplitude / duree if duree > 0 else 0
```

---

### 5.3. Python Part 3 — Data Export for ICC

This section standardises column names, numbers each trial within its group (patient × side × speed), and exports the final dataset.

```{r, eval=FALSE}
df_full = pd.DataFrame(all_events_long)

df_full = df_full.rename(columns={
    "subject":        "patient_id",
    "speed_category": "speed"
})

df_full["speed"] = df_full["speed"].replace({
    "lente": "slow", "moyenne": "medium", "rapide": "fast"
})

df_full = df_full.sort_values(by=["patient_id", "side", "speed"])
df_full["trial"] = (
    df_full
        .groupby(["patient_id", "side", "speed"])
        .cumcount() + 1
)

df_full.to_csv("data/velocity_trials_clean.csv", index=False)
```

---

### 5.4. R — ICC Analysis

#### 5.4.1. Setup

```{r packages}
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
if (!requireNamespace("irr",       quietly = TRUE)) install.packages("irr")
if (!requireNamespace("knitr",     quietly = TRUE)) install.packages("knitr")
if (!requireNamespace("here",      quietly = TRUE)) install.packages("here")

library(tidyverse)
library(irr)
library(knitr)
library(here)
```

#### 5.4.2. Load data

```{r load_data}
library(tidyverse)
library(irr)
library(knitr)

df <- read.csv("velocity_trials_clean.csv", stringsAsFactors = FALSE)

df <- df %>%
  mutate(subject = paste(patient_id, side, sep = "_"))

cat("Rows:", nrow(df), "| Columns:", ncol(df), "\n")
cat("Unique subjects:", paste(unique(df$subject), collapse = ", "), "\n\n")

kable(head(df, 9),
      caption = "**Table 1.** Preview — velocity_trials_clean.csv")
```

#### 5.4.3. Data preparation — wide format

The ICC requires data in **wide format**: one row per subject, one column per trial. The data is reshaped separately for each speed condition.

```{r data_prep}
prepare_wide <- function(speed_name, data) {
  data %>%
    filter(speed == speed_name) %>%
    select(subject, trial, velocity) %>%
    pivot_wider(names_from = trial, values_from = velocity)
}

wide_slow   <- prepare_wide("slow",   df)
wide_medium <- prepare_wide("medium", df)
wide_fast   <- prepare_wide("fast",   df)

kable(wide_slow,
      caption = "**Table 2.** Wide format — Slow condition (one column per trial)")
kable(wide_medium,
      caption = "**Table 3.** Wide format — Medium condition")
kable(wide_fast,
      caption = "**Table 4.** Wide format — Fast condition")
```

#### 5.4.4. ICC computation

The ICC(A,1) model is used with the following parameters:

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `model` | `"twoway"` | Subjects **and** trials treated as random effects |
| `type` | `"agreement"` | Absolute agreement — penalises systematic differences |
| `unit` | `"single"` | Reliability of a single trial → **ICC(A,1)** |

```{r icc_function}
compute_icc <- function(speed_name, data) {

  df_wide <- data %>%
    filter(speed == speed_name) %>%
    select(subject, trial, velocity) %>%
    pivot_wider(names_from  = trial,
                values_from = velocity) %>%
    select(-subject)

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
```

##### Slow condition

```{r icc_slow}
icc_slow <- compute_icc("slow", df)
```

##### Medium condition

```{r icc_medium}
icc_medium <- compute_icc("medium", df)
```

##### Fast condition

```{r icc_fast}
icc_fast <- compute_icc("fast", df)
```

#### 5.4.5. Summary table

```{r results_table}
extract_icc_row <- function(res, speed_name) {
  if (is.null(res)) return(NULL)
  data.frame(
    Speed          = speed_name,
    ICC            = round(res$value,   3),
    p_value        = round(res$p.value, 4),
    CI_lower       = round(res$lbound,  3),
    CI_upper       = round(res$ubound,  3),
    Interpretation = case_when(
      res$value < 0.50 ~ "Poor",
      res$value < 0.75 ~ "Moderate",
      res$value < 0.90 ~ "Good",
      TRUE             ~ "Excellent"
    )
  )
}

results_df <- bind_rows(
  extract_icc_row(icc_slow,   "Slow"),
  extract_icc_row(icc_medium, "Medium"),
  extract_icc_row(icc_fast,   "Fast")
)

kable(results_df,
      col.names = c("Speed", "ICC(A,1)", "p-value",
                    "95% CI lower", "95% CI upper", "Interpretation"),
      caption   = "**Table 5.** Intra-session reproducibility — ICC results (Koo & Mae, 2016)")
```

#### 5.4.6. Interpretation

The ICC ranges from 0 to 1 and measures absolute agreement across repeated trials for the same subject. The general interpretation scale (Koo & Mae, 2016) is as follows:

- **< 0.50:** Poor reliability
- **0.50 – 0.75:** Moderate reliability
- **0.75 – 0.90:** Good reliability
- **> 0.90:** Excellent reliability

```{r interpretation, echo=FALSE, results='asis'}
cat("> **Slow (ICC = 0.27, p = 0.067):** Poor reproducibility, non-significant.  \n")
cat("> Wide confidence interval (–0.06 to 0.78) reflects high inter-trial variability,  \n")
cat("> likely due to the difficulty of maintaining a constant slow movement speed.\n\n")

cat("> **Medium (ICC = 0.11, p = 0.301):** Very poor reproducibility, non-significant.  \n")
cat("> The intermediate speed is the hardest to standardise,  \n")
cat("> resulting in maximum inter-trial variability.\n\n")

cat("> **Fast (ICC = 0.77, p < 0.001):** Good reproducibility, highly significant.  \n")
cat("> The confidence interval (0.38–0.96) is entirely positive,  \n")
cat("> suggesting that fast ballistic movements are more consistent across trials.\n\n")

cat("> ⚠️ **Critical limitation:** These results must be interpreted with major caution:  \n")
cat("> (1) automatic trough detection was unreliable — several velocity values are incorrect;  \n")
cat("> (2) sample size is very limited (n = 6 limbs) — confidence intervals are very wide.  \n")
cat("> These ICC values do not carry valid clinical meaning.\n")
```

---

## 6. Conclusion

The analysis of intra-session reproducibility of angular velocity during passive elbow extension in healthy subjects reveals that:

- The **fast condition** shows good reproducibility (ICC = 0.77, p < 0.001), suggesting that fast ballistic movements are more stereotyped and therefore more consistently measured.
- The **slow and medium conditions** show poor and non-significant reproducibility (ICC = 0.27 and 0.11), with very wide confidence intervals including zero.

However, two cumulative limitations prevent valid clinical interpretation:

1. **Unreliable trough (flexion minimum) detection** — despite five different strategies tested, automatic detection failed in several cases, leading to incorrect velocity values.
2. **Insufficient sample size (n = 6 limbs)** — statistical power is very limited.
This pilot study initiated the development of an **end-to-end pipeline** (raw file → angle → velocity → ICC) within the framework of this Movement Analysis course. However, I encountered significant technical limitations — particularly in the automatic detection of flexion minima — that I was unable to fully resolve, resulting in partially incorrect angular velocity values. I critically acknowledge these shortcomings today.
That said, I was able to collaborate with the engineer (G. Desmyttere) from the research project involved in the main study, and we worked together on this pipeline. For his part, he successfully overcame the challenge of detecting troughs by extracting reliable flexion minima and producing accurate and interpretable angular velocity values.While this pilot study cannot be considered a methodological success in itself, it represented a necessary first step that contributed to the progress of the official study, which is now moving toward valid and clinically meaningful results.
---

## 7. References

Koo TK, Mae AY. A Guideline of Selecting and Reporting Intraclass Correlation Coefficients for Reliability Research. *J Chiropr Med.* 2016;15(2):155–163.

Shrout PE, Fleiss JL. Intraclass correlations: uses in assessing rater reliability. *Psychol Bull.* 1979;86(2):420–428.

Leuenberger K, Gonzenbach R, Wachter S, et al. A method to qualitatively assess arm use in stroke survivors at home. *Med Biol Eng Comput.* 2017;55:141–150.

---

## 6. Requirements

### Python (Jupyter Notebook)

```
numpy
pandas
matplotlib
scipy
```

Install with:
```bash
pip install numpy pandas matplotlib scipy
```

### R (R Markdown)

```r
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
if (!requireNamespace("irr",       quietly = TRUE)) install.packages("irr")
if (!requireNamespace("knitr",     quietly = TRUE)) install.packages("knitr")
```

> Packages are installed automatically if missing — safe to run on any machine.

---

## 7. How to Run


### 🐍 Python (Parts 1 & 2)
1. Place all raw CSV files in the `data/` folder
2. Run `Part1_parsing_angles.ipynb` → produces angle time-series per subject and side
3. Run `Part2_detection_analysis.ipynb` → produces `velocity_trials_clean.csv`

### 📊 R (Part 3)
1. Open `RStudio_Project/RStudio_Project.Rproj` in RStudio
   → this sets the working directory automatically
2. Make sure `velocity_trials_clean.csv` is in the `RStudio_Project/data/` subfolder
   (it is already included in the repository)
3. Open `main.Rmd` and click **Knit** → produces the ICC report

> ⚠️ Always open R via the `.Rproj` file — this sets the working directory
> automatically to the right folder, which fixes all path errors.
---

## 8. Reference

Koo TK, Mae AY. A Guideline of Selecting and Reporting Intraclass Correlation Coefficients for Reliability Research. *J Chiropr Med.* 2016;15(2):155–163.
