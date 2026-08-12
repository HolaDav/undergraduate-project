# Feasibility Observations

Date Updated: 2026-08-12

### Objective:
Assess whether a quantitative amyloid PET Centiloid workflow can be
implemented reproducibly on modest laptop hardware using Neurodesk,
SPM12 standalone and FSL.

------------------------------------------------------------
## Dataset Progress

AD subjects attempted: 25
Successfully processed: 23
Excluded: 2 (sub-AD10, sub-AD23)
Additional flagged, unprocessed: 5 (AD27, AD35, AD37, AD41, AD45)
Reason for all AD exclusions:
PET orientation metadata defect (qform_code=0, sform_code=0)

YC subjects attempted: 11 (of 34 total in cohort)
Successfully processed: 11
Excluded for orientation defect: 0
  (full 34-subject YC screen found zero matches for the
  qform_code=0/sform_code=0 defect - this issue appears
  isolated to the AD-100 cohort)
Remaining YC subjects: 23, held back pending individual
  investigation of a separate issue: large, inconsistent,
  non-corner origin coordinates found during the original
  79-subject origin screening (distinct from the AD-group
  orientation-metadata defect)

Total valid subjects processed to date: 34 (23 AD, 11 YC)

------------------------------------------------------------
## Runtime Observations

Typical processing time per subject
(after origin correction workflow established):
3-9 minutes

Longest runtime observed:
~9 minutes (sub-AD17)

Initial pilot subject (AD01):
~45 minutes

Reason:
Workflow development, troubleshooting, and optimisation phase;
subsequent subjects benefit from the established origin-
correction and batching workflow.

Batching:
From sub-AD04 onward, subjects processed in looped batches
(5-10 subjects per script invocation) rather than individual
scripts, substantially reducing script-writing overhead without
changing per-subject processing logic or runtime.

------------------------------------------------------------
## Memory Usage

Observed RAM range: 2.8 GB - 4.8 GB
Peak observed RAM: 4.8 GB
Most resource-intensive stage: MRI Segmentation (SPM12)

Note: resource tracking was not measured for the first 9
subjects processed (sub-AD01 - sub-AD08, sub-YC101); this gap
is documented in docs/methodology_decisions.md. All subjects
from sub-AD09 onward have recorded measurements.

------------------------------------------------------------
## Storage Usage

Approximate disk usage remained within available laptop
resources throughout processing (34GB-39GB observed, on a
system with 1TB total capacity).
No storage-related failures observed.

------------------------------------------------------------
## Manual Intervention Requirements

Required:
1. PET/T1 origin correction using SPM Display
2. Visual QC using FSLeyes (native-space and MNI-space)
3. Header screening (qform/sform validation) - added after
   the sub-AD10 finding, now performed proactively before
   origin correction on any new batch

Not required:
- Motion correction
- Frame averaging
- High-performance computing
- MATLAB license

------------------------------------------------------------
## Quality Control Outcomes

Successful subjects: 34 (23 AD, 11 YC)
QC pass rate: 100% among subjects that passed the pre-processing
header screen

Failure modes discovered:
1. PET origin placed at image corner rather than brain center
   (majority of subjects, both groups) - corrected via manual
   Set Origin/Reorient; does not cause a visible error, only
   silent misalignment, detected via visual QC.
2. Missing PET orientation metadata (qform_code=0,
   sform_code=0) - found in 7 of 25 AD subjects, 0 of 34 YC
   subjects. Identified through proactive dataset-wide header
   screening, not through pipeline failure during processing.
3. A separate, apparently distinct issue affecting 23 of 34 YC
   subjects: large, inconsistent (non-corner) origin
   coordinates, identified in the original 79-subject
   screening. Not yet individually investigated; unknown
   whether the standard origin-correction fix applies.

------------------------------------------------------------
## Feasibility Conclusion

The pipeline is feasible on modest laptop hardware using
Neurodesk, SPM12 standalone and FSL. Quantitative Centiloid
generation was successfully demonstrated across 23 AD subjects
and 11 YC subjects with acceptable runtime, memory usage and
reproducibility.

A clear, non-overlapping group-level separation was observed:
AD group Centiloid range 56.60-127.64 CL; YC group Centiloid
range -2.85 to 9.97 CL. This is consistent with expected
Centiloid scale behaviour (YC-0 anchored near 0 CL, AD-100
anchored near 100 CL) and supports the technical validity of
the implemented workflow.

The primary limitation encountered throughout was dataset
quality (PET header/orientation metadata defects affecting a
subset of subjects in both groups, via two apparently distinct
mechanisms) rather than computational capacity, software
availability, or workflow complexity. This is itself a notable
feasibility finding: the barrier to reproducible cloud-based
amyloid PET quantification in a resource-constrained setting
was not primarily technical infrastructure, but the ordinary
practical work of validating and cleaning real-world imaging
data before it can be trusted.
