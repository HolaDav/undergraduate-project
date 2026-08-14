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

1. Full interactive MATLAB fails at launch with a license checkout
   error and cannot be used.
2. Standalone SPM12 (`spm12` command, MATLAB Compiler Runtime-based)
   requires no license, but as a compiled application cannot execute
   custom MATLAB functions, use `addpath()`, or run any script
   containing a `function ... end` definition. Only plain sequential
   scripts calling SPM's built-in functions, invoked via
   `spm12 script <file>.m`, are supported.

Design implication: `run_subject_preprocessing.m` is retained as a
function-wrapped reference implementation. Actual execution uses
plain, non-function scripts following the same batch logic.

Standalone SPM also validates all batch file paths exist on disk
*before* any module executes, so Module 3 (Normalise, which depends
on Module 2's output) cannot share a batch with Module 2. Execution
is split into two parts per subject:

  Part 1: Coregister (Module 1) + Segment (Module 2)
  Part 2: Normalise (Module 3) + Smooth (Module 4)

From sub-AD04 onward, both parts are executed as looped batch
scripts across multiple subjects (5-22 per batch, scaling up as
confidence in the pattern grew), rather than individual per-subject
scripts.

---

# Stage 0 -- Pre-flight Validation

Purpose: confirm subject inputs are present, readable, and
reasonable before committing compute time to preprocessing.

Software: SPM12 (spm_vol), via scripts/validate_subject_inputs.m

Checks performed: file existence, header readability, dimensions
and voxel size (printed, not thresholded).

Status: implemented and tested on sub-AD01. Not integrated as an
automatic gate before every run - a scope limitation, not a
technical barrier.

---

# Stage 1 -- Input

Input: sub-<id>_T1w.nii, sub-<id>_trc-pib_pet.nii
Software: none (visual/header inspection only)
QC: visual inspection; fslhd sform/qform check

## Data-quality issue 1: PET origin placement (both groups)

The majority of PET images have their coordinate origin at an image
corner rather than brain centre - silent misalignment, not a
visible error. Fix: SPM Display, manual Set Origin + Reorient on T1
and PET independently, per subject. Effect: Coregister convergence
time dropped from ~20 minutes (sub-AD01, uncorrected) to 10-30
seconds on all subsequent origin-corrected subjects. Status: applied
to all 79 valid subjects. Remains a manual step.

## Data-quality issue 2: Missing orientation metadata (AD group only)

7 of 45 AD subjects (AD10, AD23, AD27, AD35, AD37, AD41, AD45)
originally had qform_code=0, sform_code=0 - no usable orientation
information. A full 34-subject YC screen for the same pattern found
zero matches - isolated to the AD-100 cohort.

Root cause (confirmed): the original NIfTI conversion failed to
write valid orientation metadata. dcm2niix reconversion directly
from each subject's source DICOM (all 7: 47 slices, "PatientPosition
not specified" warning) produced valid metadata and correctly
oriented images - the underlying scan data was never corrupted,
only the specific original conversion tool's output.

Status: all 7 fully recovered via DICOM reconversion followed by
standard origin correction. See docs/flagged_subjects.md.

## Data-quality issue 3: origin-correction precision sensitivity

Retrospective re-QC of sub-AD01 (first subject processed, using the
two-stage visual QC standard developed later) found MNI-space
misalignment despite correct native-space coregistration, traced to
imprecision in the very first manual T1 origin click attempted in
this project. Refining the click and re-running Segment/Normalise/
Smooth changed the Centiloid value by 21 CL (119.38 -> 98.64).

Status: sub-AD01 corrected. A full systematic re-QC of all subjects
against this failure mode was judged out of scope, based on
documented reasoning (Coregister convergence speed as an indirect
precision signal for other early subjects; no visual QC concern
raised elsewhere) - see docs/methodology_decisions.md. Documented as
an inherent, not fully resolved, limitation of manual-correction-
dependent workflows.

## Data-quality issue 4: YC subjects with inconsistent origin coordinates

23 of 34 YC subjects showed large, inconsistent (non-corner) origin
coordinates, distinct from issues 1-3 above, initially set aside
pending investigation.

Investigation: 3 diagnostic subjects spanning the apparent sub-
patterns (sub-YC103, sub-YC109, sub-YC116) all showed completely
valid headers (qform_code=1, sform_code=2) - ruling out a data
defect. Test case sub-YC103 (most extreme offsets) processed
individually confirmed the standard origin-correction fix applies
directly (21-second Coregister convergence, clean QC, SUVR
consistent with the existing YC group).

Status: all 23 subjects (test case + 22-subject batch) resolved via
standard origin correction. One subject (sub-YC131) required a full
redo after a manually-missed origin correction was caught by visual
QC - resolved by restoring from source and repeating the process
correctly.

## Summary: all data-quality issues resolved

Across the complete 79-subject dataset, every subject was ultimately
processed successfully. No subject was permanently excluded. Four
distinct root causes were identified, diagnosed, and resolved over
the course of the project, each via a QC mechanism specifically
developed in response to that failure mode - representing an
increasingly systematic and proactive approach to data quality as
the project progressed.

---

# Stage 2 -- Preprocessing

Purpose: coregister PET to native T1 MRI, segment structural brain
tissues, transform images into standard MNI space.

Software: SPM12 standalone (spm12 script), FSL (QC/geometry
verification).

Modular Processing Steps (all validated across the full 79-subject
dataset):

- [x] Module 1: PET -> MRI Coregistration (SPM12 coreg.estimate)
- [x] Module 2: MRI Segmentation (SPM12 preproc)
- [x] Module 3: PET Normalization to MNI (SPM12 norm.write) - output
  geometry 91x109x91, 2x2x2mm, bounding box [-90 -126 -72; 90 90
  108]. Bug fixed early on: deformation field must be referenced
  without a ",1" frame-index suffix.
- [x] Module 4: Spatial Smoothing (SPM12 smooth), 8mm FWHM

Output location: derivatives/preprocessed/sub-<id>/{anat,pet}/

QC: two-stage visual assessment (native-space PET-vs-T1; MNI-space
swPET-vs-template) plus a header sanity check (qform_code/
sform_code), the latter added after the sub-AD10 finding and applied
proactively before origin correction from that point onward.

Current QC outcome: 79 of 79 subjects processed and reviewed (45
AD, 34 YC). No unresolved coregistration or normalization failures.
Six distinct failure modes were found and resolved over the course
of the project (see Stage 1) - all caught by the project's own QC
procedures, not discovered externally.

One container-level crash (Bus error) and one associated silent
output-corruption case occurred during a 15-subject AD batch,
resolved via environment restart and isolated rerun - demonstrating
that batch automation on this platform can fail silently, making
per-subject output validation a necessary QC step.

---

# Stage 3 -- Quantification

Purpose: compute SUVR and convert to the Centiloid scale.

Software: FSL (fslstats)

Processing:
1. Apply Whole Cortex VOI mask (masks/voi_ctx_2mm.nii), compute
   mean uptake
2. Apply Whole Cerebellum VOI mask (masks/voi_WhlCbl_2mm.nii),
   compute mean uptake
3. SUVR = Cortex mean / Cerebellum mean
4. CL = 100 x (SUVR - 1.009) / 1.067 (Klunk et al., 2015, standard
   PiB equation)
   Limitation: applies the published equation directly rather than
   a locally-calibrated Level-2 equation - documented scope
   limitation, not an unstated assumption.

Output: results/tables/suvr_centiloid_summary.csv (79 rows: subject,
group, cortex_mean, cerebellum_mean, suvr, centiloid)

FINAL RESULTS (2026-08-14):

AD group: 45 of 45 subjects, Centiloid range 54.79 - 127.64 CL
YC group: 34 of 34 subjects, Centiloid range -5.66 to 11.78 CL

Group separation: complete, non-overlapping, across the full
dataset (n=45 vs n=34) - the central validating result of the
feasibility study.

Observations:
- Several AD subjects show lower burden than the group median
  despite clean QC (e.g. AD15, AD16, AD25, AD41, in the 50-90 CL
  range) - interpreted as genuine clinical heterogeneity within the
  AD-labelled cohort, consistent with a real diagnosed population.
- sub-AD01's value was revised (119.38 -> 98.64 CL) following the
  origin-precision finding; the only subject re-processed for this
  reason.
- Absolute uptake values vary substantially across subjects
  (dataset-wide, not group-specific) - interpreted as reconstruction/
  calibration differences in the source PET data; SUVR is robust to
  this as a ratio measure.

QC: visual confirmation of VOI mask placement over cortex/
cerebellum on swsub-*.nii; mean values checked for positivity,
cortex > cerebellum, and plausible magnitude.

---

# Stage 4 -- Feasibility Assessment

Metrics: runtime (logs/runtime_tracking.csv), RAM/disk usage
(logs/resource_tracking.csv), manual intervention (docs/
processing_journal.md, docs/methodology_decisions.md), QC outcome
(qc/qc_tracking.csv, qc/sub-<id>/notes.txt).

FINAL FEASIBILITY FINDINGS:
- Successfully processed and validated: 79 of 79 subjects (100%)
- Typical runtime: 3-9 minutes per subject (steady-state)
- Observed RAM usage: 2.2-5.0 GB
- Observed disk usage: 34-46 GB (well within a 1TB system)
- Most resource-intensive stage: SPM12 Segmentation
- No high-performance computing resources required

The recurring limitation throughout was dataset quality (multiple
distinct header/orientation defect types, plus manual-step
precision sensitivity) rather than computational resources or
software availability. This is itself a central feasibility
finding: on modest hardware with no specialised infrastructure, the
practical bottleneck for reproducible amyloid PET quantification in
a resource-constrained setting was data validation and cleaning
effort, not compute capacity - and this bottleneck was fully
surmountable within an undergraduate project timeline, given
systematic, iteratively-developed QC procedures.
