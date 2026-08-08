# Pipeline Design

## Objective
To evaluate the feasibility of implementing a quantitative amyloid PET
processing workflow on modest laptop hardware using Neurodesk,
SPM12 and FSL.

---

# Pipeline Overview

Raw MRI
        |
Raw PET
        |
        v
Pre-flight Validation
        |
        v
Preprocessing
        |
        v
Quality Control
        |
        v
SUVR
        |
        v
Centiloid
        |
        v
Feasibility Metrics

---

# Execution Environment Constraint

No MathWorks MATLAB license is available in this Neurodesk deployment.
Two consequences shape the entire pipeline design:

1. Full interactive MATLAB (`matlab`, `matlab -batch`) fails at launch
   with a license checkout error and cannot be used.
2. Standalone SPM12 (`spm12` command, MATLAB Compiler Runtime-based)
   requires no license and is fully functional, but as a compiled
   application it cannot execute custom MATLAB functions, use
   `addpath()`, or run any script containing a `function ... end`
   definition. It can only execute plain sequential scripts calling
   SPM's own built-in functions, invoked via `spm12 script <file>.m`.

Design implication: `run_subject_preprocessing.m` is retained as a
function-wrapped reference implementation (documents the intended
reusable design, and is ready to run unmodified if MATLAB or Octave
becomes available). For actual execution in this environment, each
subject's processing is generated as a plain, non-function script
per subject, following the same batch logic.

A second, related constraint discovered during testing: standalone
SPM validates that all file paths referenced in a batch exist on
disk *before* any module executes. This means Module 3 (Normalise),
which depends on `y_<subject>_T1w.nii` produced by Module 2
(Segment), cannot be included in the same batch run as Module 2 --
the file will not exist yet at validation time, and the batch fails
with "Number of matching files (0) less than required (1)" even
though the pipeline logic is otherwise correct. Execution is
therefore split into two parts per subject:

  Part 1: Coregister (Module 1) + Segment (Module 2)
  Part 2: Normalise (Module 3) + Smooth (Module 4), run only after
          Part 1 has completed and y_<subject>_T1w.nii exists

This is documented as a deliberate, tested execution pattern, not a
workaround -- see docs/methodology_decisions.md for full detail.

---

# Stage 0 -- Pre-flight Validation

Purpose:
Confirm subject inputs are present, readable, and reasonable before
committing compute time to preprocessing.

Software:
SPM12 (spm_vol), via scripts/validate_subject_inputs.m (reference
function form; executed per-subject as a plain script in the
standalone environment, same constraint as above)

Checks performed:
- MRI file exists
- PET file exists
- MRI header readable via spm_vol
- PET header readable via spm_vol
- MRI dimensions and voxel size (printed, not thresholded)
- PET dimensions and voxel size (printed, not thresholded)

Output:
Console validation report per subject (descriptive, not yet logged
to file automatically)

Status: implemented and tested on sub-AD01. Not yet integrated as
an automatic gate before every preprocessing run.

---

# Stage 1 -- Input

Input:
- sub-<id>_T1w.nii
- sub-<id>_trc-pib_pet.nii

Software:
None (visual/header inspection only)

Output:
Native images

QC:
Visual inspection; fslhd sform/qform check

## Known dataset issue: PET origin placement

Screening across all 79 subjects (fslorient-based qform origin
check) found that the great majority of PET images -- across both
AD and YC groups -- have their coordinate origin placed at an image
corner (commonly (0,0,0), with some subjects at other corners e.g.
(128,-128,0)) rather than near the brain center. This is
sufficiently far from a reasonable starting point that SPM's
Coregister: Estimate step can fail to converge to a correct
alignment, even though it completes without throwing an error --
the failure is silent and only detectable via visual QC.

A minority of YC subjects show large, non-corner, inconsistent
origin values, suggesting a different or additional header issue;
these require individual inspection rather than the standard fix
below.

Fix applied per affected subject, before preprocessing:
Using SPM's Display tool, manually click the approximate brain
center on both the T1 and PET image, use Set Origin to compute the
offset, then Reorient to write it to the file header. Applied to
both the T1 and PET image independently.

Effect observed: Coregister: Estimate convergence time dropped
from ~20 minutes (AD01, uncorrected starting point on first
attempt) to 20-30 seconds (AD01 corrected; AD02, YC101), consistent
with the optimiser starting from a much closer initial alignment.

Status: fix validated on sub-AD01, sub-AD02, sub-YC101. Not yet
automated; currently a required manual step per subject before
Part 1 execution. Batch/scripted correction (e.g. via
spm_auto_reorient or an image center-of-mass heuristic) identified
as a future improvement, not yet implemented.

---

# Stage 2 -- Preprocessing

Purpose:
Coregister PET to native T1 MRI, segment structural brain tissues,
and transform images into standard MNI space for Centiloid
quantification.

Software:
- SPM12 standalone (via spm12 script, MATLAB Compiler Runtime,
  Neurodesk)
- FSL (for visual QC and geometry verification via fslinfo/fslhd)

Modular Processing Steps:

- [x] Module 1: PET -> MRI Coregistration (SPM12 coreg.estimate)
  - Objective: Align native PET scan to T1 MRI using Normalized
    Mutual Information (NMI).
  - Output: Coregistered PET (header updated in place, native
    space).
  - Status: validated on sub-AD01, sub-AD02, sub-YC101.

- [x] Module 2: MRI Segmentation (SPM12 preproc)
  - Objective: Segment T1 MRI into tissue classes (c1-c6), apply
    bias correction, generate forward deformation field.
  - Output: Bias-corrected T1 (m*.nii), tissue maps (c1-c6*.nii),
    Forward Deformation Field (y_*.nii).
  - Status: validated on sub-AD01, sub-AD02, sub-YC101.

- [x] Module 3: PET Normalization to MNI (SPM12 norm.write)
  - Objective: Apply forward deformation field (y_*.nii) to warp
    coregistered PET into 2mm isotropic MNI space.
  - Output: Normalized MNI PET image (wsub-*.nii), 91x109x91,
    2x2x2mm, bounding box [-90 -126 -72; 90 90 108].
  - Status: validated on sub-AD01, sub-AD02, sub-YC101. Bug fixed:
    deformation field must be referenced without a ",1" frame-index
    suffix (unlike standard 3D image inputs); see
    methodology_decisions.md.

- [x] Module 4: Spatial Smoothing (SPM12 smooth)
  - Objective: Apply 8mm FWHM Gaussian kernel to normalized PET.
  - Output: Normalized and smoothed PET image (swsub-*.nii).
  - Status: validated on sub-AD01, sub-AD02, sub-YC101.

Output location:
derivatives/preprocessed/sub-<id>/{anat,pet}/
(migrated here post-hoc for the first three subjects; new subjects
moved here as part of the standard per-subject workflow)

QC:
Two-stage visual assessment per subject, both in FSLeyes:
1. Native space: coregistered PET vs subject's own T1 -- confirms
   Coregister accuracy independent of normalization
2. MNI space: normalized/smoothed PET vs MNI152_T1_2mm template --
   confirms Normalise accuracy
Both checks passed, no shifts/flips/floating, for all three
subjects processed to date.

---

# Stage 3 -- Quantification

Purpose:
Compute quantitative amyloid burden (SUVR) and convert to the
standardized Centiloid scale.

Software:
FSL (fslstats)

Processing:
1. Apply Whole Cortex VOI mask (voi_ctx_2mm.nii) to swsub-*.nii,
   compute mean uptake (fslstats -k ... -M)
2. Apply Whole Cerebellum VOI mask (voi_WhlCbl_2mm.nii), compute
   mean uptake
3. Compute SUVR = Cortex mean / Cerebellum mean
4. Convert SUVR to Centiloid using the published standard PiB
   equation (Klunk et al., 2015):

     CL = 100 x (SUVR - 1.009) / 1.067

   where 1.009 = YC-0 cohort mean SUVR (anchored to 0 CL) and
   2.076 = AD-100 cohort mean SUVR (anchored to 100 CL), from the
   original Centiloid Level-1 calibration dataset.

   Limitation: this applies the published equation directly rather
   than deriving a locally-calibrated Level-2 equation from the
   full GAAIN YC-0 (n=34) / AD-100 (n=45) reference datasets
   processed through this specific pipeline, which was outside the
   scope of this feasibility study. Documented as a scope
   limitation rather than an unstated assumption.

Output:
results/tables/suvr_centiloid_summary.csv
(columns: subject, group, cortex_mean, cerebellum_mean, suvr,
centiloid)

Results to date:

| Subject   | Group | SUVR   | Centiloid |
|-----------|-------|--------|-----------|
| sub-AD01  | AD    | 2.2828 | 119.38    |
| sub-AD02  | AD    | 2.1032 | 102.55    |
| sub-YC101 | YC    | 0.9786 | -2.85     |

Both AD subjects exceed 100 CL (typical/advanced AD-range amyloid
burden); the YC subject falls near 0 CL with a small negative
value, expected since 0 CL is defined as the YC-0 group mean, not
an individual floor. Group separation direction is correct for a
first n=3 check; not yet sufficient to declare the pipeline
formally validated (target: additional AD and YC subjects before
that claim is made).

QC:
Visual confirmation that VOI masks overlap appropriate anatomy
(cortex mask over cortical ribbon, cerebellum mask over cerebellum)
when overlaid on swsub-*.nii in FSLeyes. Both mean values checked
for: positive, cortex > cerebellum, physiologically plausible
magnitude, no zeros/negatives (would indicate a masking or geometry
failure).

---

# Stage 4 -- Feasibility Assessment

Metrics:
- Runtime (per module, per subject) -- logs/runtime_tracking.csv
- RAM usage -- logs/resource_tracking.csv
- Storage used
- Manual intervention required (e.g. origin correction, script
  splitting) -- tracked narratively in docs/processing_journal.md
  and docs/methodology_decisions.md
- QC outcome -- qc/qc_tracking.csv, qc/sub-<id>/notes.txt
- Processing success/failure

Output:
- logs/runtime_tracking.csv
- logs/resource_tracking.csv
- qc/qc_tracking.csv

Status: runtime logged manually per subject to date (AD01: ~45 min
Modules 1-3 first pass; AD02/YC101: ~9-10 min total post origin-fix
across both parts). Not yet automated into the script itself.
