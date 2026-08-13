# Feasibility Observations

Date Updated: 2026-08-13

### Objective:
Assess whether a quantitative amyloid PET Centiloid workflow can be
implemented reproducibly on modest laptop hardware using Neurodesk,
SPM12 standalone and FSL.

------------------------------------------------------------
## Dataset Progress

AD subjects (full cohort): 45
Successfully processed and validated: 45 (100%)
  - 38 processed via the standard workflow
  - 7 recovered via DICOM reconversion after an initial
    orientation-metadata defect (AD10, AD23, AD27, AD35, AD37,
    AD41, AD45) - see docs/flagged_subjects.md
Excluded: 0

YC subjects (full cohort): 34
Successfully processed and validated: 11 (32%)
Remaining: 23, held back pending individual investigation of a
  separate issue - large, inconsistent, non-corner origin
  coordinates identified in the original 79-subject screening,
  distinct from the AD-group orientation-metadata defect (which
  a full 34-subject screen confirmed does not affect any YC
  subject)

Total valid subjects processed to date: 56 (45 AD, 11 YC)

------------------------------------------------------------
## Runtime Observations

Typical processing time per subject (steady-state, after origin
correction workflow established): 3-9 minutes

Longest runtime observed: ~9 minutes (sub-AD17)

Initial pilot subject (AD01): ~45 minutes, reflecting workflow
development and troubleshooting rather than steady-state
performance.

Batching: from sub-AD04 onward, subjects processed in looped
batches (5-15 subjects per script invocation), substantially
reducing script-writing overhead without changing per-subject
processing logic or runtime.

One container-level crash (Bus error) occurred during a 15-subject
batch, resolved by a full environment restart with no data loss
beyond one subject requiring an isolated rerun (see Quality
Control Outcomes below).

------------------------------------------------------------
## Memory Usage

Observed RAM range: 2.3 GB - 5.0 GB
Peak observed RAM: 5.0 GB
Most resource-intensive stage: MRI Segmentation (SPM12)

Note: resource tracking was not measured for the first 9 subjects
processed (sub-AD01 - sub-AD08, sub-YC101); documented in
docs/methodology_decisions.md. All subjects from sub-AD09 onward
have recorded measurements (RAM and disk; CPU% not measured -
free -h/df -h snapshots do not capture CPU utilisation).

------------------------------------------------------------
## Storage Usage

Disk usage remained well within available laptop resources
throughout processing (34GB-43GB observed, on a system with 1TB
total capacity).
No storage-related failures observed.

------------------------------------------------------------
## Manual Intervention Requirements

Required:
1. PET/T1 origin correction using SPM Display (Set Origin +
   Reorient) - required for the large majority of subjects in
   both groups, due to a systematic dataset-level issue placing
   PET origins at image corners rather than brain centre
2. Visual QC using FSLeyes (native-space and MNI-space, two
   separate checks per subject)
3. Header screening (qform/sform validation) - added after the
   sub-AD10 finding, now performed proactively before origin
   correction on any new batch
4. For 7 AD subjects: DICOM reconversion (dcm2niix) to recover
   from a missing-orientation-metadata defect in the originally
   provided NIfTI files

Not required:
- Motion correction
- Frame averaging
- High-performance computing
- MATLAB license

Observed impact of manual step precision: a retrospective re-
examination of the first subject processed (sub-AD01) found that
origin-click precision materially affects the final Centiloid
value (21 CL difference between an imprecise first attempt and a
refined re-click) despite both passing native-space visual QC.
This is documented as a genuine source of operator-dependent
variability inherent to manual-correction-based workflows - see
docs/processing_journal.md, 2026-08-13.

------------------------------------------------------------
## Quality Control Outcomes

Successful subjects: 56 (45 AD, 11 YC)
QC pass rate: 100% among subjects that passed the pre-processing
header screen and were carried through to completion

Failure modes discovered:
1. PET origin placed at image corner rather than brain centre
   (majority of subjects, both groups) - corrected via manual
   Set Origin/Reorient; causes silent misalignment, not a visible
   error, detected only via visual QC.
2. Missing PET orientation metadata (qform_code=0, sform_code=0) -
   found in 7 of 45 AD subjects, 0 of 34 YC subjects. Root cause
   traced to a failed original NIfTI conversion, most likely
   triggered by a missing DICOM PatientPosition tag (confirmed
   present in all 7 affected subjects' raw DICOM data). Fully
   recovered via reconversion from source DICOM using dcm2niix.
3. Origin-correction precision sensitivity: a materially different
   Centiloid value can result from imprecise vs refined manual
   origin clicks on the same subject, despite both passing native-
   space visual QC (see sub-AD01 finding above).
4. One container-level crash (Bus error) during a large (15-
   subject) batch run, and one associated silent output-corruption
   case (a 0-byte deformation field written without SPM reporting
   an error) - both resolved via environment restart and isolated
   subject rerun. Demonstrates that automated batch processing on
   this platform can fail silently as well as loudly, making per-
   subject output validation (not log inspection alone) necessary.
5. A separate, apparently distinct issue affecting 23 of 34 YC
   subjects: large, inconsistent (non-corner) origin coordinates.
   Not yet individually investigated; unknown whether the standard
   origin-correction fix applies.

------------------------------------------------------------
## Feasibility Conclusion

The pipeline is feasible on modest laptop hardware using
Neurodesk, SPM12 standalone and FSL. Quantitative Centiloid
generation was successfully demonstrated across the complete
45-subject AD cohort and 11 YC subjects, with acceptable runtime,
memory usage, and reproducibility.

A clear, non-overlapping group-level separation was observed: AD
group Centiloid range 54.79-127.64 CL (n=45); YC group Centiloid
range -2.85 to 9.97 CL (n=11). This is consistent with expected
Centiloid scale behaviour (YC-0 anchored near 0 CL, AD-100
anchored near 100 CL) and supports the technical validity of the
implemented workflow.

The primary limitations encountered throughout were dataset
quality issues (PET header/orientation metadata defects,
requiring manual correction and, in some cases, source-data
reconversion) rather than computational capacity, software
availability, or workflow complexity. A further limitation,
identified through retrospective investigation rather than assumed
in advance, is that manual origin-correction introduces real,
quantifiable operator-dependent variability into final results.

Taken together, these findings support a specific and defensible
feasibility conclusion: cloud-based amyloid PET Centiloid
processing on modest hardware is technically achievable without
specialised infrastructure, but requires deliberate, documented
quality-control procedures - automated where possible, and
explicitly acknowledged as a source of variability where manual
intervention remains necessary. This is considered a core
contribution of the present study, alongside the numerical results
themselves.
