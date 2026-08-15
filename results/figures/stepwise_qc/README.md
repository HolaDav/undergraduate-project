# Stepwise QC Figures

Visual record of pipeline outputs at each processing stage, for a
representative subset of subjects (5 of 79), generated to allow
step-by-step visual review without re-running the pipeline.

## Subjects included and why

- **sub-AD01** — pilot subject; first subject processed in this
  project.
- **sub-AD15** — an AD-group subject with lower Centiloid burden
  (56.60 CL) than the group median, illustrating within-group
  clinical heterogeneity.
- **sub-AD10** — recovered from a missing-orientation-metadata
  defect via DICOM reconversion (see docs/flagged_subjects.md).
  Includes both the originally-provided (broken) and reconverted
  raw PET for comparison.
- **sub-YC101** — first YC (young control) subject processed.
- **sub-YC103** — test case for the "wild origin value" YC subject
  category (see docs/pipeline_design.md, Stage 1).

## Stages shown, per subject

1. `01_raw_anat.png` — native T1 MRI, unprocessed
2. `01_raw_pet.png` — native PET, unprocessed (post manual origin
   correction, pre-coregistration)
3. `02_coregistered.png` — PET coregistered to the subject's own T1
   (native space)
4. `03_normalized.png` — PET warped to MNI152 space (before
   smoothing)
5. `04_smoothed.png` — final output: normalized + 8mm FWHM smoothed
   PET in MNI space, as used for SUVR/Centiloid quantification

All images generated in FSLeyes, colour map: NIH (brain_colours_nih),
crosshair and orientation labels hidden for clarity, colour bar
shown on the final (smoothed) stage image only.
