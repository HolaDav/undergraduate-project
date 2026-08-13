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
function-wrapped reference implementation. For actual execution in
this environment, each subject's processing is generated as a plain,
non-function script, following the same batch logic.

A second, related constraint: standalone SPM validates that all file
paths referenced in a batch exist on disk *before* any module
executes. Module 3 (Normalise) depends on `y_<subject>_T1w.nii`
produced by Module 2 (Segment) and cannot be included in the same
batch run as Module 2. Execution is therefore split into two parts
per subject:

  Part 1: Coregister (Module 1) + Segment (Module 2)
  Part 2: Normalise (Module 3) + Smooth (Module 4)

This is a deliberate, tested execution pattern - see
docs/methodology_decisions.md for full detail.

From sub-AD04 onward, both parts are executed as looped batch
scripts across multiple subjects (5-15 per batch) rather than
individual per-subject scripts, substantially reducing script-
writing overhead while preserving identical per-subject logic.

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

The majority of PET images across both AD and YC groups have their
coordinate origin placed at an image corner (commonly (0,0,0), some
subjects at (128,-128,0)) rather than near the brain centre. This
does not cause a visible error but produces silent coregistration
misalignment, detectable only via visual QC.

Fix: SPM Display tool, manual Set Origin + Reorient on both T1 and
PET independently, per subject.

Effect: Coregister: Estimate convergence time dropped from ~20
minutes (sub-AD01, uncorrected) to consistently 10-30 seconds
across all subsequent origin-corrected subjects.

Status: applied to all 56 valid subjects processed to date (45 AD,
11 YC). Considered a standard, required preprocessing step for this
dataset. Remains a manual step; not automated.

## Known dataset issue: Missing orientation metadata (AD group only)

A subset of AD subjects' originally-provided PET NIfTI files
(qform_code=0, sform_code=0 - no usable orientation information)
were found via proactive header screening, introduced after initial
failures on sub-AD10 and sub-AD23.

Affected subjects: sub-AD10, sub-AD23, sub-AD27, sub-AD35, sub-AD37,
sub-AD41, sub-AD45 (7 of 45 AD subjects). A full screen of all 34 YC
subjects for the same defect found zero matches - this issue is
isolated to the AD-100 cohort.

Root cause (confirmed): the original NIfTI conversion failed to
write valid orientation metadata. dcm2niix reconversion directly
from each subject's source DICOM series (all 7 subjects: 47 slices,
"PatientPosition (0018,5100) not specified" warning) produced valid
metadata and, on visual inspection, correctly oriented images -
confirming the underlying DICOM/scan data was never corrupted, only
the specific original conversion tool's output.

Status: all 7 affected subjects fully recovered via this DICOM
reconversion procedure, followed by standard origin correction. See
docs/flagged_subjects.md for full detail and the documented
recovery procedure.

## Known issue: manual origin-correction precision sensitivity

Retrospective re-QC of sub-AD01 (the first subject processed, using
the two-stage visual QC standard developed later in the project)
found that native-space coregistration was correct but MNI-space
alignment showed a slight misalignment on close inspection. Root
cause: imprecision in the manually-clicked T1 origin on this
project's very first attempt at the technique, before practice
improved click accuracy.

Refining the origin click and re-running Segment/Normalise/Smooth
changed the subject's Centiloid value by 21 CL (119.38 -> 98.64),
despite both versions passing native-space visual QC.

Status: sub-AD01 corrected; results table updated. A full
systematic re-QC of all subjects against this specific failure mode
was judged out of scope, based on a documented reasoning (Coregister
convergence speed as an indirect precision signal; no visual QC
concern raised for other early subjects) - see
docs/methodology_decisions.md. This is documented as an inherent
limitation of manual-correction-dependent workflows, not fully
resolved.

## Known issue: YC subjects with inconsistent origin coordinates

A separate category, identified in the original 79-subject
screening: 23 of 34 YC subjects show large, inconsistent (non-
corner) origin coordinates, distinct from both the standard corner-
origin pattern and the AD-group orientation-metadata defect. Not
yet individually investigated. Unknown whether standard origin
correction applies; may require the same DICOM-reconversion
approach used for the AD group, or a different fix entirely.

Status: unresolved. 11 of 34 YC subjects (the confirmed clean
corner-origin subset) have been processed; the remaining 23 are
pending this investigation.

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
  - Status: validated across all 56 processed subjects.

- [x] Module 2: MRI Segmentation (SPM12 preproc)
  - Objective: Segment T1 MRI into tissue classes (c1-c6), apply
    bias correction, generate forward deformation field.
  - Status: validated across all 56 processed subjects. See Stage 1
    note on origin-precision sensitivity affecting this module's
    output quality.

- [x] Module 3: PET Normalization to MNI (SPM12 norm.write)
  - Objective: Apply forward deformation field to warp coregistered
    PET into 2mm isotropic MNI space.
  - Output geometry: 91x109x91, 2x2x2mm, bounding box
    [-90 -126 -72; 90 90 108].
  - Status: validated across all 56 processed subjects. Bug fixed
    early on: deformation field must be referenced without a ",1"
    frame-index suffix (unlike standard 3D image inputs); see
    methodology_decisions.md.

- [x] Module 4: Spatial Smoothing (SPM12 smooth)
  - Objective: Apply 8mm FWHM Gaussian kernel to normalized PET.
  - Status: validated across all 56 processed subjects.

Output location:
derivatives/preprocessed/sub-<id>/{anat,pet}/

QC:
Two-stage visual assessment per subject, both in FSLeyes:
1. Native space: coregistered PET vs subject's own T1
2. MNI space: normalized/smoothed PET vs MNI152_T1_2mm template
Plus a header sanity check (qform_code/sform_code), added after the
sub-AD10 finding, run proactively before origin correction on every
subject/batch since.

Current QC outcome:
56 subjects processed and reviewed (45 AD, 11 YC). No
coregistration failures, normalization failures, or major spatial
misalignment among final validated subjects. Two distinct data-
quality failure modes were found and resolved during processing
(missing orientation metadata; origin-correction precision
sensitivity) - both are documented above and in
docs/processing_journal.md, not concealed as clean results.

One container-level crash (Bus error) occurred during a 15-subject
batch, with one associated silent output-corruption case (0-byte
deformation field, not flagged by SPM's own completion message).
Both resolved via environment restart and isolated subject rerun.
This demonstrates a real feasibility-relevant finding: batch
automation on this platform can fail silently, making per-subject
output file validation (not log inspection alone) a necessary QC
step, not an optional one.

---

# Stage 3 -- Quantification

Purpose:
Compute quantitative amyloid burden (SUVR) and convert to the
standardized Centiloid scale.

Software:
FSL (fslstats)

Processing:
1. Apply Whole Cortex VOI mask (masks/voi_ctx_2mm.nii) to
   swsub-*.nii, compute mean uptake (fslstats -k ... -M)
2. Apply Whole Cerebellum VOI mask (masks/voi_WhlCbl_2mm.nii),
   compute mean uptake
3. Compute SUVR = Cortex mean / Cerebellum mean
4. Convert SUVR to Centiloid using the published standard PiB
   equation (Klunk et al., 2015):
     CL = 100 x (SUVR - 1.009) / 1.067
   Limitation: applies the published equation directly rather than
   a locally-calibrated Level-2 equation derived from the full
   GAAIN YC-0/AD-100 reference datasets processed through this
   specific pipeline - documented as a scope limitation.

Output:
results/tables/suvr_centiloid_summary.csv
(columns: subject, group, cortex_mean, cerebellum_mean, suvr,
centiloid)

Current results (2026-08-13):

Successfully quantified subjects:
- AD group: 45 of 45 (100% of full cohort)
- YC group: 11 of 34 (32% of full cohort; 23 remain pending
  investigation of a separate origin-coordinate issue - see
  Stage 1)

Observed Centiloid range:
- AD group: 54.79 - 127.64 CL (n=45)
- YC group: -2.85 to 9.97 CL (n=11)

Observations:
- Clear, non-overlapping separation between AD (all >54 CL) and YC
  (all <10 CL) groups, consistent with expected Centiloid scale
  behaviour.
- Several AD subjects (AD15, AD16, AD25, AD41, and others in the
  50-90 CL range) show lower burden than the group median despite
  clean QC throughout - interpreted as genuine clinical
  heterogeneity within the AD-labelled cohort, consistent with a
  real-world diagnosed population rather than a uniformly high-
  burden sample.
- sub-AD01's value was revised (119.38 -> 98.64 CL) following the
  origin-precision finding described in Stage 1; this is the only
  subject re-processed for this reason to date.
- Absolute uptake values vary substantially across subjects
  (observed dataset-wide, not group-specific) - interpreted as
  reconstruction/calibration differences in the source PET data.
  SUVR, as a ratio measure, is robust to this variation.

Status:
Clear, non-overlapping group separation established with n=45 (AD)
vs n=11 (YC). Considered the core validating result of the
feasibility study to date. Completing the remaining 23 YC subjects
would strengthen the YC-side sample size further but is not
expected to change the qualitative conclusion given the tight
clustering already observed.

QC:
Visual confirmation that VOI masks overlap appropriate anatomy when
overlaid on swsub-*.nii in FSLeyes. Mean values checked for:
positive, cortex > cerebellum, physiologically plausible magnitude,
no zeros/negatives.

---

# Stage 4 -- Feasibility Assessment

Metrics:
- Runtime (per subject) -- logs/runtime_tracking.csv
- RAM/disk usage -- logs/resource_tracking.csv
- Manual intervention required -- tracked narratively in
  docs/processing_journal.md and docs/methodology_decisions.md
- QC outcome -- qc/qc_tracking.csv, qc/sub-<id>/notes.txt
- Processing success/failure, including failure modes found and
  their resolution

Current feasibility findings:
- Successfully processed and validated: 56 subjects (45 AD, 11 YC)
- Typical runtime: 3-9 minutes per subject (steady-state)
- Observed RAM usage: 2.3-5.0 GB
- Observed disk usage: 34-43 GB (well within a 1TB system)
- Most resource-intensive stage: SPM12 Segmentation

No high-performance computing resources were required. The
technical and computational aspects of the pipeline proved
reliable and reproducible. The recurring limitation throughout was
dataset quality (multiple distinct header/orientation defect types)
and manual-step precision, rather than computational resources -
itself a relevant feasibility finding for resource-constrained
deployment: the practical bottleneck was data validation and
cleaning effort, not infrastructure.
