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

Purpose:
Coregister PET to native T1 MRI, segment structural brain tissues, and transform images into standard MNI space for Centiloid quantification.

Software:
- SPM12 (via MATLAB Compiler Runtime inside Neurodesk)
- FSL (for visual QC and verification)

Modular Processing Steps:

- [x] Module 1: PET -> MRI Coregistration (SPM12 coreg.estimate)
  - Objective: Align native Amyloid PET scan to high-resolution T1 MRI using Normalized Mutual Information (NMI).
  - Output: Coregistered PET image in native space.

- [x] Module 2: MRI Segmentation (SPM12 preproc)
  - Objective: Segment T1 MRI into tissue classes (c1-c6), apply bias correction, and generate deformation fields.
  - Output: Bias-corrected T1 (m*.nii), tissue maps (c1*.nii, c2*.nii), and Forward Deformation Field (y_*.nii).

- [ ] Module 3: PET Normalization to MNI (SPM12 norm.write)
  - Objective: Apply forward deformation field (y_*.nii) to warp coregistered PET into 2mm isotropic MNI space.
  - Output: Normalized MNI PET image (wsub-*.nii).

- [ ] Module 4: Spatial Smoothing (SPM12 smooth)
  - Objective: Apply 8 mm FWHM Gaussian kernel to normalized PET for Centiloid calibration.
  - Output: Normalized and smoothed PET image (swsub-*.nii).

Output:
swsub-[subject_id]_trc-pib_pet.nii

QC:
Visual assessment of:
- PET/MRI alignment
- Segmentation quality
- Normalization to MNI space

---

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
