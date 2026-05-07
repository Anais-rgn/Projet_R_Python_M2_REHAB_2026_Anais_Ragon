Projet_R_Python_M2_REHAB_2026 : Master's internship Anaïs RAGON + Claude — May 2026
# Pilot Study — Intra-Session Reproducibility of Instrumental Elbow Extension Velocity in Healthy Subjects

---

## 1. Scientific Background

### 1.1 Context

Spasticity is a frequent motor symptom following central nervous system injury (stroke, traumatic brain injury, spinal cord injury). It is defined as a **velocity-dependent increase in muscle tone**, causing functional limitations, pain, and significant impairment in daily life activities.

Current clinical assessment relies on standardised scales such as the **Modified Tardieu Scale (MTS)** and the Modified Ashworth Scale (MAS). However, these tools have well-documented limitations, in particular **poor inter- and intra-rater reproducibility**, which limits their reliability for longitudinal monitoring and clinical research.

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

- Mean and maximum **angular velocity** (°/s)
- **Range of motion** (ROM) in degrees (°)
- Peak force (N)
- Angle at peak force (°)
- Mean force (N)
- Movement duration (s)

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
[Part 2 — Python]  Event detection & velocity analysis
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

1. Place all raw CSV files in the `data/` folder
2. Run `Part1_parsing_angles.ipynb` → produces angle time-series per subject and side
3. Run `Part2_detection_analysis.ipynb` → produces `velocity_trials_clean.csv`
4. Open `Part3_ICC_analysis.Rmd` in RStudio and click **Knit** → produces the ICC report

---

## 8. Reference

Koo TK, Mae AY. A Guideline of Selecting and Reporting Intraclass Correlation Coefficients for Reliability Research. *J Chiropr Med.* 2016;15(2):155–163.
