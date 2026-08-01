# Pipeline Design

## Objective

To evaluate the feasibility of implementing a quantitative amyloid PET
processing workflow on modest laptop hardware using Neurodesk,
SPM12 and FSL.

---

# Pipeline Overview

Raw MRI
        ↓
Raw PET
        ↓
Preprocessing
        ↓
Quality Control
        ↓
SUVR
        ↓
Centiloid
        ↓
Feasibility Metrics

---

# Stage 1 – Input

Input:
- sub-AD01_T1w.nii
- sub-AD01_trc-pib_pet.nii

Software:
None

Output:
Native images

QC:
Visual inspection

---

# Stage 2 – Preprocessing

Purpose

Transform MRI and PET into standard MNI space suitable for Centiloid
quantification.

Software

SPM12
MATLAB
FSL

Processing

1. Reorient MRI
2. Reorient PET
3. PET → MRI Coregistration
4. MRI Segmentation
5. Generate deformation field
6. Apply deformation to PET
7. Smooth PET (8 mm)

Output

pet_to_MNI_smoothed.nii.gz

QC

Visual assessment of:
- PET/MRI alignment
- Normalization
- Image quality

---

# Stage 3 – Quantification

Purpose

Compute quantitative amyloid burden.

Software

FSL

Processing

1. Apply Whole Cerebellum mask
2. Apply Global Cortex mask
3. Compute regional means
4. Compute SUVR
5. Convert SUVR to Centiloid

Output

subject_results.csv

QC

Verify masks overlap normalized PET.

---

# Stage 4 – Feasibility Assessment

Metrics

Runtime

RAM usage

Storage used

Manual intervention

QC outcome

Processing success

Output

runtime_tracking.csv

resource_tracking.csv

qc_tracking.csv
