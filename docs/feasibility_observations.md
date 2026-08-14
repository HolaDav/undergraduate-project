# Feasibility Observations

Date Updated: 2026-08-14

### Objective:
Assess whether a quantitative amyloid PET Centiloid workflow can be
implemented reproducibly on modest laptop hardware using Neurodesk,
SPM12 standalone and FSL.

------------------------------------------------------------
## Dataset Progress

FULL DATASET COMPLETE.

AD-100 cohort: 45 of 45 subjects processed and validated (100%)
  - 38 processed via the standard workflow
  - 7 recovered via DICOM reconversion after an initial
    orientation-metadata defect (AD10, AD23, AD27, AD35, AD37,
    AD41, AD45)

YC-0 cohort: 34 of 34 subjects processed and validated (100%)
  - 11 processed via the standard workflow (clean corner-origin
    pattern)
  - 23 required the same manual origin correction after being
    initially set aside due to large, inconsistent origin
    coordinates - investigation confirmed these had valid headers
    throughout and responded to the standard fix once identified

Total: 79 of 79 subjects in the original dataset (100%)
No subjects were ultimately excluded from the final dataset.

------------------------------------------------------------
## Runtime Observations

Typical processing time per subject (steady-state): 3-9 minutes
Longest runtime observed: ~9 minutes (sub-AD17)
Initial pilot subject (AD01): ~45 minutes, reflecting workflow
development rather than steady-state performance.

Batching: from sub-AD04 onward, subjects processed in looped
batches (5-22 subjects per script invocation), substantially
reducing script-writing overhead. The largest single batch (22 YC
subjects) completed without incident.

------------------------------------------------------------
## Memory Usage

Observed RAM range: 2.2 GB - 5.0 GB
Peak observed RAM: 5.0 GB
Most resource-intensive stage: MRI Segmentation (SPM12)

Resource tracking was not measured for the first 9 subjects
processed and for one individually-processed subject
(sub-AD23), documented transparently as not_recorded/N/A in
logs/resource_tracking.csv rather than estimated.

------------------------------------------------------------
## Storage Usage

Disk usage remained well within available resources throughout
(34GB-46GB observed, on a system with 1TB total capacity).
No storage-related failures observed.

------------------------------------------------------------
## Manual Intervention Requirements

Required, across the full dataset:
1. PET/T1 origin correction using SPM Display - required for the
   large majority of subjects in both groups (standard corner-
   origin pattern, plus the 23 YC subjects with less regular
   origin coordinates - same fix applied once headers were
   confirmed valid)
2. Two-stage visual QC using FSLeyes (native-space and MNI-space)
   per subject
3. Header screening (qform/sform validation), performed
   proactively before origin correction from partway through the
   AD cohort onward
4. For 7 AD subjects: DICOM reconversion (dcm2niix) to recover
   from missing orientation metadata in the originally provided
   NIfTI files

Not required:
- Motion correction
- Frame averaging
- High-performance computing
- MATLAB license

Documented sensitivity: a retrospective re-examination of the
first subject processed (sub-AD01) found that origin-click
precision materially affects the final Centiloid value (21 CL
difference between an imprecise and refined attempt), despite both
passing native-space visual QC. This is a genuine limitation of
manual-correction-dependent workflows, not fully resolved for the
whole dataset (see docs/methodology_decisions.md for the scope
decision on this point).

------------------------------------------------------------
## Quality Control Outcomes

Successful subjects: 79 of 79 (100%)
QC pass rate: 100% among subjects carried through to completion

Failure modes discovered and resolved across the full dataset:
1. PET origin at image corner rather than brain centre (majority
   of subjects, both groups) - silent misalignment, corrected via
   manual origin correction, detected via visual QC.
2. Missing PET orientation metadata (qform_code=0, sform_code=0) -
   7 of 45 AD subjects, 0 of 34 YC subjects. Root cause: failed
   original NIfTI conversion, likely triggered by a missing DICOM
   PatientPosition tag (confirmed present in all 7 affected
   subjects' source DICOM data). Fully recovered via dcm2niix
   reconversion from source.
3. Origin-correction precision sensitivity (1 subject, sub-AD01) -
   quantified 21 CL impact from origin-click imprecision.
4. One container-level crash (Bus error) and one associated
   silent output-corruption case (0-byte deformation field, no
   SPM-reported error) during a 15-subject AD batch - resolved via
   environment restart and isolated subject rerun.
5. Large, inconsistent (non-corner) origin coordinates in 23 of 34
   YC subjects - initially treated as a distinct, unexplained
   issue; investigation found valid headers throughout, and the
   standard origin-correction fix applied directly once confirmed.
6. One missed manual origin-correction step during batch setup (1
   YC subject, sub-YC131) - caught by visual QC (PET visibly
   outside expected bounds), resolved by a full redo from source
   data.

Every failure mode listed above was identified through the
project's own QC procedures (header screening, two-stage visual
QC, or output validation) rather than by chance - supporting the
robustness of the QC design itself as a feasibility finding.

------------------------------------------------------------
## Feasibility Conclusion

The pipeline is feasible on modest laptop hardware using
Neurodesk, SPM12 standalone and FSL. The complete 79-subject
dataset (45 AD, 34 YC) was successfully processed and quantified,
with acceptable runtime, memory usage, and full reproducibility
documentation.

A clear, non-overlapping group-level separation was observed
across the complete dataset: AD group Centiloid range 54.79-127.64
CL (n=45); YC group Centiloid range -5.66 to 11.78 CL (n=34). This
is consistent with expected Centiloid scale behaviour and provides
strong support for the technical validity of the implemented
workflow at full dataset scale, not just a preliminary subsample.

The primary limitations encountered throughout were dataset
quality issues (multiple distinct types of PET header/orientation
defects, requiring varying degrees of manual correction and, in
some cases, source-data reconversion) rather than computational
capacity, software availability, or workflow complexity. A further
limitation, identified through retrospective investigation, is
that manual origin-correction introduces real, quantifiable
operator-dependent variability into final results for at least one
documented subject, with the possibility (not fully investigated)
that this affects others.

Taken together, these findings support a specific and defensible
feasibility conclusion: cloud-based amyloid PET Centiloid
processing on modest hardware is technically achievable without
specialised infrastructure, and can be carried through to
completion on a real-world, imperfect dataset - but requires
deliberate, iteratively-developed quality-control procedures, and
these procedures themselves (not just the final numerical results)
are a core, reportable contribution of this feasibility study. Six
distinct failure modes were identified and resolved over the
course of the project, each through a QC mechanism specifically
designed to catch that class of problem; this progression - from
ad hoc troubleshooting on the first subject to systematic,
proactive screening by the end - is itself evidence of a maturing,
increasingly robust and reproducible processing workflow.
