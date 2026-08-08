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



## 2026-08-03

### Successfully validated preprocessing Modules 1–3
using subject AD01.

Initial coregistration (Coregister: Estimate) produced
poor spatial alignment — PET floating outside the
head, shifted, not following brain outline in FSLeyes.

Investigation:
- Ruled out header corruption (sform/qform mismatch
  traced back to SPM writing a bad estimate into the
  PET header on the first failed run — confirmed clean
  on a fresh copy from sourcedata/).
- Full header comparison (fslhd) showed the PET
  image's origin was set at the image corner rather
  than brain center, unlike the T1. This large initial
  offset likely prevented SPM's coregistration
  optimizer from converging correctly.

Fix:
Used SPM's Display tool to manually set the origin
near brain-center on both the T1 and PET images
(Set Origin → Reorient), giving Coregister a much
closer starting point before re-running.

Result:
Coregistration converged correctly on the second
attempt. Normalisation generated:
- y_sub-AD01_T1w.nii
- wsub-AD01_trc-pib_pet.nii

Validation:
- Output geometry confirmed: 91×109×91 voxels,
  2×2×2mm — matching MNI152 normalisation target.
- Visual QC in FSLeyes confirmed PET correctly
  overlays the MNI152 template brain.
- Total processing time: ~45 minutes (Modules 1–3,
  first pass, excluding manual origin correction).

Note for full cohort:
This origin issue may not be unique to AD01 — if the
same DICOM-to-NIfTI conversion was used across the
GAAIN dataset, other subjects (AD02–AD25, YC101–
YC125) may need the same manual origin check before
coregistration. Worth verifying systematically before
scaling up.

Conclusion:
Modules 1–3 validated for AD01. Manual origin
correction added as a required pre-coregistration
step; not yet automated.


## 2026-08-04

### Module 4 (Smoothing) validated on sub-AD01.
Applied 8mm FWHM Gaussian kernel to
wsub-AD01_trc-pib_pet.nii via SPM Spatial > Smooth,
producing swsub-AD01_trc-pib_pet.nii.

One transient failure during first run attempt:
"Failed to open file spm_write_plane.m ... File
stream is closed." — appears to be an environment/
mount-level glitch (possibly CVMFS), not a data or
config issue. Resolved by fully closing all terminals
and SPM windows and restarting; second attempt
completed successfully in ~6 seconds.

Output geometry confirmed unchanged from
normalisation stage (91x109x91, 2x2x2mm), as
expected — smoothing blurs values, does not resample
the grid.

Conclusion: Module 4 validated for AD01.


## 2026-08-07

### Second pipeline validation run: sub-AD02, Modules 1–4.

Origin correction:
Screening (fslorient loop, run previously) had flagged
sub-AD02 with the same corner-origin pattern as sub-AD01
(different corner: 128,-128,0 vs 0,0,0). Applied the same
manual fix as AD01 — SPM Display tool, Set Origin near
brain-center on both T1 and PET, followed by Reorient —
before running preprocessing.

Execution method:
Ran via standalone SPM (spm12 script) using plain,
non-function scripts adapted from the frozen
run_subject_preprocessing.m, split into two parts:
  Part 1: Coregister + Segment
  Part 2: Normalise + Smooth
Split was required because Normalise:Write references
y_sub-AD02_T1w.nii, which does not exist until Segment
completes — standalone SPM validates all file paths
before execution begins, so a single combined run fails
with "Number of matching files (0) less than required (1)"
even though the file is correctly generated mid-pipeline.
This is a genuine bug in the frozen script, not an error
in this run; not previously caught because AD01 was run
in a way that Segment had already completed beforehand.

A second, separate bug was found in Part 2: the
deformation field must be passed to Normalise:Write's
"Deformation Field" input as a bare file path, without a
",1" frame index suffix (unlike standard 3D image inputs
such as "Images to Write", which does use ",1"). Including
",1" caused SPM's batch file-matcher to fail to resolve
the file even though it existed on disk and passed a plain
isfile() check. Confirmed via a standalone debug script.
Fixed by removing ",1" from the deformation field
reference only.

Result:
Coregister: Estimate completed in 28 seconds (23:16:10 -
23:16:38), markedly faster than AD01's initial ~20-minute
run, consistent with the manual origin correction giving
the optimiser a much closer starting point.
Segment completed 23:16:38 - 23:24:59 (~8 min 20s).
Normalise + Smooth completed 23:42:05 - 23:42:08 (3
seconds).

Outputs generated:
- y_sub-AD02_T1w.nii
- wsub-AD02_trc-pib_pet.nii
- swsub-AD02_trc-pib_pet.nii

Validation:
- Output geometry confirmed: 91x109x91 voxels, 2x2x2mm.
- Visual QC (native space): coregistered PET correctly
  follows sub-AD02's own T1 brain shape in FSLeyes.
- Visual QC (MNI space): normalised/smoothed PET aligns
  correctly with MNI152 template — alignment assessed as
  very clean, better than AD01's initial visual fit.

SUVR:
Mean cortex uptake:      649.462394
Mean whole cerebellum:   308.784584
SUVR = 649.462394 / 308.784584 = 2.10

Consistent with AD01 (SUVR 2.28) — both in the expected
range for amyloid-positive AD-labelled subjects.

Note on absolute uptake units:
AD02's absolute mean uptake values (649 / 308) are
approximately 65x larger than AD01's (10.21 / 4.47),
despite similar SUVR. This indicates raw PET intensity
scaling is not consistent across subjects in this dataset
(likely differing reconstruction/calibration), which SUVR,
as a ratio measure, is robust to. Worth noting as a
dataset-level observation for the feasibility study.

Conclusion:
Modules 1–4 validated for sub-AD02. Pipeline confirmed to
generalise beyond AD01, with two real bugs identified and
fixed in the frozen script (multi-module file-dependency
ordering; deformation field frame-index syntax). Manual
origin correction required again, consistent with prior
finding that this is a systemic dataset issue rather than
isolated to AD01.
