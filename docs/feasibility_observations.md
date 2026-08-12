# Feasibility Observations

Date Updated: 2026-08-12

### Objective:
Assess whether a quantitative amyloid PET Centiloid workflow can be
implemented reproducibly on modest laptop hardware using Neurodesk,
SPM12 standalone and FSL.

------------------------------------------------------------

## Dataset Progress

AD subjects attempted: 25

Successfully processed:
23

Excluded:
2

Reason for exclusion:
PET orientation metadata defect
(qform_code=0, sform_code=0)

Additional flagged subjects identified:
AD27, AD35, AD37, AD41, AD45

------------------------------------------------------------

## Runtime Observations

Typical processing time per subject
(after origin correction workflow established):

3-7 minutes

Longest runtime observed:
~7 minutes

Initial pilot subject (AD01):
~45 minutes

Reason:
Workflow development, troubleshooting,
and optimisation phase.

------------------------------------------------------------

## Memory Usage

Observed RAM range:

2.8 GB - 4.8 GB

Peak observed RAM:
4.8 GB

Most resource-intensive stage:
MRI Segmentation (SPM12)

------------------------------------------------------------

## Storage Usage

Approximate disk usage remained within
available laptop resources throughout
processing.

No storage-related failures observed.

------------------------------------------------------------

## Manual Intervention Requirements

Required:

1. PET/T1 origin correction
   using SPM Display

2. Visual QC
   using FSLeyes

3. Header screening
   (qform/sform validation)

Not required:

- Motion correction
- Frame averaging
- High-performance computing
- MATLAB license

------------------------------------------------------------

## Quality Control Outcomes

Successful subjects:
23

QC pass rate:
100% among processed subjects

Common failure mode discovered:

Missing PET orientation metadata
(qform_code=0, sform_code=0)

This issue was identified through
dataset-wide screening and not through
pipeline failure.

------------------------------------------------------------

## Feasibility Conclusion

The pipeline is feasible on modest laptop
hardware using Neurodesk, SPM12 standalone
and FSL.

Quantitative Centiloid generation was
successfully demonstrated across 23 AD
subjects and 1 YC subject with acceptable
runtime, memory usage and reproducibility.

The primary limitation encountered was
dataset quality rather than computational
capacity.
