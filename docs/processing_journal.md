# Processing Journal

## Project
Evaluation of a Cloud-Based Quantitative Amyloid PET Imaging Workflow for Resource-Constrained Nigerian Settings

## 2026-07-25
Created project directory structure.
Created:
- rawdata/
- sourcedata/
- derivatives/
- qc/
- logs/

Verified Neurodesk environment.

Imported:
- 45 AD subjects
- 34 YC subjects

Verified MRI/PET file counts.

Notes:
PET images are static 3D PiB images (dim4=1).
Dynamic motion-correction steps from original CONNExIN workflow are not required.

## 2026-07-26
Implemented BIDS-style renaming.
Created automated manifest generation script (participants.tsv + subject manifest).
Verified all 79 subjects.

### Centiloid Reference Mask Verification
Verified Centiloid standard VOIs.
Files inspected:
- voi_ctx_2mm.nii
- voi_WhlCbl_2mm.nii

Findings:
- MNI space
- 91 × 109 × 91 dimensions
- 2 mm isotropic voxel size

Conclusion:
Masks are compatible with standard Centiloid SUVR calculation following spatial normalization.

### Native Data Inspection
AD01 MRI and PET images were visually inspected in FSLeyes.
The MRI and PET images were not initially aligned in native space, which was expected because the modalities were acquired separately and stored in their own coordinate systems.
No preprocessing was performed at this stage. Alignment between MRI and PET will be achieved using automated PET-to-MRI coregistration (SPM12) during the preprocessing workflow.

## 2026-08-01

### Development of SPM Preprocessing Template

Developed a reusable MATLAB preprocessing function for the undergraduate workflow.

Completed preprocessing modules:

- Module 1 – PET to MRI Coregistration
- Module 2 – MRI Segmentation

Implementation improvements over the original CONNExIN workflow:

- Replaced hard-coded subject paths with function inputs (`base_dir`, `subject_id`)
- Replaced hard-coded TPM locations with dynamic lookup using `spm('Dir')`
- Added MRI/PET file validation before execution
- Structured the script into modular processing sections
- Converted the generated SPM batch into a reusable preprocessing function

Expected outputs after execution:

- Coregistered PET
- Bias-corrected MRI
- Tissue probability maps (c1–c6)
- Forward deformation field (y_*.nii)

Next step:

Implement and validate PET normalization to MNI space.
