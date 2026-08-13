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



## 2026-08-08

### Centiloid conversion applied to sub-AD01, sub-AD02,
sub-YC101 using the published standard PiB equation
(Klunk et al., 2015):

  CL = 100 x (SUVR - 1.009) / 1.067

Anchors: YC-0 mean SUVR = 1.009 (0 CL), AD-100 mean
SUVR = 2.076 (100 CL), from the original Level-1
Centiloid calibration dataset.

Results:
  sub-AD01: SUVR 2.2828 -> 119.38 CL
  sub-AD02: SUVR 2.1032 -> 102.55 CL
  sub-YC101: SUVR 0.9786 -> -2.85 CL

Both AD subjects exceed 100 CL, consistent with
typical/advanced AD-range amyloid burden. YC101's
slightly negative CL is expected and normal - the
0 CL point is defined as the YC-0 group mean, so
individual controls scatter on both sides of zero.

Limitation noted: this applies the published standard
PiB equation directly rather than deriving a locally
calibrated Level-2 equation from the full GAAIN YC-0
(n=34) and AD-100 (n=45) reference datasets, which was
outside the scope of this feasibility study. Considered
a reasonable approximation given SPM12's methodological
continuity with the original SPM8-based standard
pipeline; documented as a limitation rather than an
unstated assumption.

Next planned step: process additional subjects (AD03,
AD04, YC102, YC103...) through the full pipeline
(preprocessing -> QC -> SUVR -> Centiloid in one pass)
to build a stronger validation dataset before concluding
pipeline validation.


## 2026-08-09

### Third pipeline validation run: sub-AD03, Modules 1-4.

Origin correction applied (same corner-origin pattern as
prior subjects), manual Set Origin + Reorient on T1 and PET
via SPM Display, before preprocessing.

Execution: two-part script pattern (Part 1: Coregister +
Segment; Part 2: Normalise + Smooth), same as AD02/YC101.
No new bugs encountered - both scripts ran cleanly on first
attempt.

Timings:
  Coregister: Estimate: 14 seconds (18:28:16-18:28:30)
  Segment: ~3.5 minutes (18:28:31-18:32:08)
  Normalise + Smooth: ~2 seconds combined (18:34:48-18:34:50)

Validation:
  Geometry confirmed: 91x109x91, 2x2x2mm
  Visual QC (native and MNI space): alignment clean, no
  shifts/flips/floating

SUVR:
  Mean cortex uptake: 13.068075
  Mean whole cerebellum: 5.525003
  SUVR = 2.3653

Centiloid:
  CL = 100 x (2.3653 - 1.009) / 1.067 = 127.11

Consistent with prior AD subjects (AD01: 119.38 CL, AD02:
102.55 CL) - third consecutive AD subject exceeding 100 CL,
strengthening evidence of correct group-level separation.

Conclusion:
Modules 1-4 validated for sub-AD03. No new issues found;
pipeline behaving consistently across three AD subjects.


### 2026-08-10

## Batch validation run: sub-AD04 through sub-AD08 (5 subjects),
Modules 1-4.

First use of batched (looped) execution rather than
per-subject individual scripts. Manual origin correction
(Set Origin + Reorient) still performed individually per
subject beforehand -- this remains the one step requiring
human judgement and was not automated.

Batch Part 1 (Coregister + Segment), looped over all 5
subjects in a single spm12 script invocation with per-subject
try/catch error handling: all 5 completed successfully,
total ~24 minutes. Coregister times ranged 12-24 seconds per
subject, consistent with prior origin-corrected subjects.

Batch Part 2 (Normalise + Smooth), same looped pattern: all
5 completed successfully, ~14 seconds total for all 5
combined.

SUVR extraction also batched via a new shell script
(scripts/extract_suvr_batch.sh) looping fslstats across
subjects and computing SUVR + Centiloid in one pass.

Validation:
  Geometry confirmed for all 5: 91x109x91, 2x2x2mm
  Visual QC (native and MNI space): clean for all 5

Results:
  sub-AD04: SUVR 2.1984 -> 111.47 CL
  sub-AD05: SUVR 2.1303 -> 105.09 CL
  sub-AD06: SUVR 2.1243 -> 104.53 CL
  sub-AD07: SUVR 2.1740 -> 109.18 CL
  sub-AD08: SUVR 1.9568 -> 88.82 CL

sub-AD08 is the first AD-group subject to fall below 100 CL.
Considered expected biological/clinical heterogeneity within
the AD-labelled group rather than a processing error --
geometry and visual QC for AD08 were clean, consistent with
the other 4 subjects in this batch.

Running total: 8 AD subjects processed (all > 88 CL, 7 of 8
> 100 CL), 1 YC subject processed (-2.85 CL). Group
separation direction remains correct and consistent.

Conclusion:
Batched execution pattern validated across 5 subjects with
zero failures. This significantly reduces per-subject script-
writing overhead for remaining subjects; manual origin
correction remains the rate-limiting manual step.

2026-08-10 (continued)

Batch validation run: sub-AD09 through sub-AD13 (5 subjects
attempted), Modules 1-4. Continued use of looped batch
execution pattern established with AD04-AD08.

Batch Part 1 and Part 2 completed without script errors for
all 5 subjects. Resource snapshot taken once during this
batch (not per-subject): 3.9GB RAM used, 34GB disk used
(logged in logs/resource_tracking.csv as a batch-level
measurement, cpu_usage_percent not_measured).

Visual QC flagged a real issue on sub-AD10: PET appeared
mirrored relative to MNI template in both sagittal
(left-right) and axial (superior-inferior) views. Investigated
via fslhd rather than assumed to be a rendering artifact.

Root cause confirmed: sub-AD10's PET file has qform_code = 0
and sform_code = 0 (both "Unknown") on a freshly re-copied,
untouched file from sourcedata/ - i.e. the file has no valid
orientation metadata at all, not merely a qform/sform
disagreement like the AD01-style origin issue. Attempted
fixes (fslorient -copysform2qform) did not resolve the visual
mirroring, consistent with there being no valid sform to copy
from in the first place; the earlier "success" of that command
only updated derived orientation labels, not the underlying
data handedness.

sub-AD10 excluded from results/tables/suvr_centiloid_summary.csv
pending dedicated investigation (see docs/flagged_subjects.md).
Its interim outputs moved to derivatives/flagged/sub-AD10/ to
keep them clearly separated from validated results.

Confirmed sub-AD11's own header and QC were clean (only AD10
was affected) - AD11 included in results normally.

Results (4 of 5 subjects):
  sub-AD09: SUVR 1.9647 -> 89.57 CL
  sub-AD11: SUVR 2.1381 -> 105.82 CL
  sub-AD12: SUVR 2.0276 -> 95.47 CL
  sub-AD13: SUVR 2.0194 -> 94.69 CL

Running total: 12 valid AD subjects processed, 1 YC subject,
1 AD subject flagged and excluded (AD10).

Conclusion:
Batching pattern continues to hold for clean subjects.
First genuinely distinct data-quality failure mode
identified (missing orientation metadata, as opposed to the
now well-understood corner-origin issue) - correctly caught
by visual QC rather than passing silently, validating the
importance of the two-stage visual QC step even as
processing is increasingly batched/automated.

## 2026-08-11

### Batch validation run: sub-AD14 through sub-AD18 (5 subjects),
Modules 1-4. Continued looped batch execution pattern.

Manual origin correction performed for all 5 beforehand
(sub-AD16 and sub-AD17 had the alternate corner-origin
pattern, 128,-128,0, per original screening - same fix
applied regardless of which corner).

Batch Part 1 and Part 2 completed without errors for all 5
subjects. Multiple resource snapshots taken across the run
(6 total) rather than single before/after measurements:
RAM climbed from 3.8GB to a peak of 4.2GB over the batch,
disk 35GB to 36GB. Logged as a range per subject in
logs/resource_tracking.csv (cpu_usage_percent still
not_measured).

Added a header sanity check (qform_code/sform_code) to the
standard QC routine for this batch, following the sub-AD10
orientation defect found in the previous batch. All 5
subjects showed qform_code=1, sform_code=2 - normal,
consistent with all prior valid subjects, no repeat of
AD10's qform_code=0/sform_code=0 defect.

Visual QC (native and MNI space, both sagittal and axial
views checked specifically) confirmed clean for all 5.

SUVR results showed a wider spread than prior batches,
including the two lowest Centiloid values recorded so far:
  sub-AD14: SUVR 1.9384 -> 87.11 CL
  sub-AD15: SUVR 1.6129 -> 56.60 CL
  sub-AD16: SUVR 1.6414 -> 59.27 CL
  sub-AD17: SUVR 1.7952 -> 73.68 CL
  sub-AD18: SUVR 1.9871 -> 91.66 CL

sub-AD15 and sub-AD16 in particular are noticeably lower
than any subject processed to date (previous low: sub-AD08
at 88.82 CL). Given a second, more skeptical visual QC pass
- checking specifically these two - showed no header defects
and no alignment/mask-placement issues, this is interpreted
as genuine clinical heterogeneity within the AD-labelled
group rather than a processing error. Noted as expected:
not every AD-diagnosed subject in a real-world dataset will
show high amyloid burden.

Running total: 17 valid AD subjects processed, 1 YC subject,
1 AD subject flagged and excluded (AD10).

Conclusion:
Batch validated. Header sanity check now a standard part of
QC going forward, in addition to visual inspection - catches
orientation-metadata defects like AD10's more directly and
efficiently than relying on visual impression alone.

## 2026-08-11 (continued)

### Batch validation run: sub-AD19, AD20, AD21, AD22, AD24, AD25
(6 subjects), Modules 1-4. This completes processing attempts
across the full AD-100 group (sub-AD01 through sub-AD25).

sub-AD23 was excluded from this batch before any processing
was attempted - header screen (qform_code=0, sform_code=0)
run proactively before manual origin correction, following
the sub-AD10 finding. A full screen of all remaining
unprocessed subjects at this point (docs/orientation_defect_
screen.csv) found 7 AD subjects total sharing this exact
defect: AD10, AD23, AD27, AD35, AD37, AD41, AD45. All 7 are
flagged in docs/flagged_subjects.md pending dedicated
investigation, rather than attempted and failed individually.

Batch Part 1 and Part 2 completed without errors for all 6
processed subjects. Resource snapshots (7 total across the
run): RAM ranged 2.8-4.6GB, disk 36-37GB.

Header sanity check and visual QC (native + MNI, sagittal +
axial + coronal) confirmed clean for all 6.

Results:
  sub-AD19: SUVR 2.1591 -> 107.79 CL
  sub-AD20: SUVR 2.1112 -> 103.30 CL
  sub-AD21: SUVR 2.3709 -> 127.64 CL
  sub-AD22: SUVR 2.2372 -> 115.11 CL
  sub-AD24: SUVR 2.0316 -> 95.84 CL
  sub-AD25: SUVR 1.6458 -> 59.68 CL

sub-AD25 is a third subject (alongside sub-AD15, sub-AD16)
showing a notably lower Centiloid value (~60 CL) despite
clean QC. Growing evidence across 3 of 23 valid AD subjects
strengthens the "genuine clinical heterogeneity" interpretation
established in the previous batch, rather than this being
processing error - a real AD-diagnosed cohort would be
expected to show some spread rather than uniformly high
values.

AD-100 GROUP PROCESSING SUMMARY (sub-AD01 - sub-AD25):
  23 subjects successfully processed and validated
  2 subjects flagged and excluded (sub-AD10, sub-AD23) due
    to missing PET orientation metadata (qform_code=0,
    sform_code=0)
  5 additional subjects (AD27, AD35, AD37, AD41, AD45) also
    carry the same defect and remain unprocessed pending the
    same investigation
  Centiloid range across 23 valid subjects: 56.60 - 127.64 CL
  All 23 valid subjects exceed 0 CL; 20 of 23 exceed 100 CL

Conclusion:
AD group processing complete for all subjects without the
orientation defect. Next step: screen YC group for the same
defect pattern before beginning YC manual origin correction,
then process YC subjects to build a proper comparison group
(currently only 1 YC subject processed against 23 AD
subjects).

## 2026-08-12

### Batch validation run: 10 YC subjects (sub-YC102, YC104, YC105,
YC111, YC112, YC114, YC125, YC127, YC129, YC132), Modules 1-4.
First large-scale YC batch, following pivot from AD group.

Before manual origin correction, ran the same qform_code/
sform_code defect screen used on the AD group across all 34 YC
subjects. Result: zero matches - no YC subject shares the
orientation-metadata defect found in 7 AD-100 subjects
(AD10/AD23/AD27/AD35/AD37/AD41/AD45). Documented in
docs/flagged_subjects.md. Suggests the defect is isolated to
the AD-100 cohort's export/reconstruction rather than a
dataset-wide issue.

Cross-referenced the original 79-subject origin screening
(conducted earlier in the project) to confirm which YC subjects
have the simple, correctable (0,0,0) origin pattern versus the
separate, more complex "wild value" pattern (23 of 34 YC
subjects) requiring individual future investigation. This batch
used only the 10 remaining confirmed-clean subjects (11 of 34
YC total, including sub-YC101 processed earlier).

Manual origin correction performed for all 10. Batch Part 1 and
Part 2 completed without errors. Coregister times notably fast
(10-21 seconds) across all 10, consistent with well-corrected
starting points. Resource snapshots (7 total): RAM 3.2-4.8GB,
disk 37-39GB.

Header sanity check and visual QC (native + MNI, all views)
confirmed clean for all 10.

Results:
  sub-YC102: SUVR 1.0418 -> 3.08 CL
  sub-YC104: SUVR 1.0882 -> 7.42 CL
  sub-YC105: SUVR 1.0701 -> 5.72 CL
  sub-YC111: SUVR 1.0533 -> 4.15 CL
  sub-YC112: SUVR 1.1154 -> 9.97 CL
  sub-YC114: SUVR 1.0572 -> 4.52 CL
  sub-YC125: SUVR 1.0594 -> 4.73 CL
  sub-YC127: SUVR 1.0623 -> 4.99 CL
  sub-YC129: SUVR 1.0230 -> 1.31 CL
  sub-YC132: SUVR 1.1125 -> 9.70 CL

All 10 tightly clustered near 0 CL (range 1.31-9.97), consistent
with sub-YC101 (-2.85 CL) and with expected young-control
amyloid-negative status.

RUNNING TOTALS:
  AD group: 23 valid, 2 flagged (AD10, AD23), 5 more flagged but
    unprocessed (AD27, AD35, AD37, AD41, AD45) - CL range
    56.60-127.64
  YC group: 11 valid (of 34), 0 flagged for orientation defect,
    23 remain in the separate "wild origin value" category
    pending individual investigation - CL range -2.85 to 9.97
  Total valid subjects: 34

Conclusion:
Clear, strong group separation now established with a
reasonable YC sample size (11 subjects) rather than n=1: AD
group entirely above 56 CL, YC group entirely below 10 CL, no
overlap. This is the core feasibility result the dissertation
is built around. Remaining work: investigate the 7 flagged
orientation-defect AD subjects and the 23 wild-origin-value YC
subjects as separate, dedicated sessions.

## 2026-08-12 (continued)

### BREAKTHROUGH: sub-AD10 orientation defect resolved.

Investigated root cause by locating the original DICOM series for
AD10 in sourcedata/AD-100_PET_5070/dicom/AD10/ (47 files, matching
the expected dim3=47). Reconverted using dcm2niix (bundled with
the Neurodesk FSL container). dcm2niix flagged a warning during
conversion: "Patient Position (0018,5100) not specified" -
plausible explanation for why the original NIfTI conversion (as
provided in sourcedata/, AD10_PiB_5070.nii) failed to write valid
orientation metadata (qform_code=0, sform_code=0).

The dcm2niix-reconverted file showed valid qform_code=1,
sform_code=1, with orientation labels matching every other
correctly-functioning subject. Visual inspection confirmed no
mirroring or flip - the underlying DICOM/scan data was never
corrupted, only the specific original NIfTI conversion tool's
output.

Replaced rawdata/sub-AD10/pet/sub-AD10_trc-pib_pet.nii with the
dcm2niix reconversion. This new file still required standard
origin correction (Set Origin + Reorient) - its default origin
was away from brain center, same as nearly every subject in this
dataset, but this is unrelated to and separate from the
orientation-metadata defect that was fixed.

Processed through Modules 1-4 (individual run, not batched, given
the investigative nature of this session). Coregister: Estimate
completed in 26 seconds, consistent with a properly origin-
corrected starting point. All QC stages (header check, native-
space visual QC, MNI-space visual QC) passed cleanly, with
particular attention paid to sagittal and axial views given
AD10's specific prior failure mode.

Result:
  sub-AD10: Cortex 12679.616551, Cerebellum 5878.051190,
  SUVR 2.1571, Centiloid 107.60

Consistent with the valid AD-group range (56.60-127.64 CL prior
to this addition).

A general recovery procedure was documented in
docs/flagged_subjects.md for the remaining 6 flagged subjects
(AD23, AD27, AD35, AD37, AD41, AD45), which share the identical
qform_code=0/sform_code=0 defect pattern and may respond to the
same DICOM-reconversion fix.

Running total: 24 valid AD subjects (up from 23), 11 valid YC
subjects. 6 AD subjects remain flagged, pending the same recovery
attempt.

Conclusion:
This resolves what was initially assumed to be an unfixable data-
quality exclusion into a genuine methodological finding: an
apparent NIfTI-conversion tool failure (likely triggered by a
missing DICOM PatientPosition tag) rather than corrupted source
data. This is a stronger, more defensible outcome for the
dissertation than simply excluding the subject - demonstrates the
pipeline's ability to diagnose and recover from a real data-
quality problem, not just detect it.

2026-08-13

Batch recovery run: sub-AD27, AD35, AD37, AD41, AD45 (5 subjects),
Modules 1-4. Completes recovery of all 7 originally flagged AD
subjects.

DICOM reconversion (dcm2niix) performed in a single batch loop
across all 5 - identical signature to sub-AD10/AD23: 47 slices,
"PatientPosition not specified" warning, valid qform_code=1/
sform_code=1 after reconversion, confirmed correctly oriented via
visual inspection before proceeding.

Manual origin correction applied to all 5 reconverted PET files.
Batch Part 1 and Part 2 completed without errors. Coregister times
12-20 seconds across all 5, consistent with well-corrected origins.
Resource snapshots: RAM peaked at 5.0GB, disk at 40GB.

Header check, geometry check, and two-stage visual QC (native +
MNI) confirmed clean for all 5.

Results:
  sub-AD27: SUVR 2.1885 -> 110.55 CL
  sub-AD35: SUVR 1.8811 -> 81.73 CL
  sub-AD37: SUVR 1.9276 -> 86.10 CL
  sub-AD41: SUVR 1.5936 -> 54.79 CL
  sub-AD45: SUVR 2.0282 -> 95.52 CL

sub-AD41 is a fourth AD subject (with sub-AD15, sub-AD16,
sub-AD25) showing a notably lower Centiloid value (~55 CL) despite
clean QC - consistent with the established genuine clinical
heterogeneity pattern.

MILESTONE: All 7 originally flagged AD subjects (AD10, AD23, AD27,
AD35, AD37, AD41, AD45) now fully recovered via the DICOM-
reconversion procedure. Root cause confirmed consistent across all
7: original sourcedata/ NIfTI conversion failed to write valid
orientation metadata, most likely due to a missing DICOM
PatientPosition tag (0018,5100) present across all 7 subjects'
source data.

Running total: 29 valid AD subjects (of 25 in the originally-
described AD-100 numbering, all now resolved), 11 valid YC
subjects. Note: the true dataset extends to AD45 (not AD25) per
the original 79-subject screening - 15 AD subjects (AD26, AD28-34,
AD36, AD38-40, AD42-44) remain entirely unprocessed and are not
part of the "flagged" set; they were simply not yet reached.

Next: process the remaining 15 unprocessed AD subjects (AD26,
AD28, AD29, AD30, AD31, AD32, AD33, AD34, AD36, AD38, AD39, AD40,
AD42, AD43, AD44) to complete the full AD cohort.

## 2026-08-13 (continued)

### Batch validation run: final 15 AD subjects (sub-AD26, AD28, AD29,
AD30, AD31, AD32, AD33, AD34, AD36, AD38, AD39, AD40, AD42, AD43,
AD44), Modules 1-4. This completes the full 45-subject AD-100
cohort.

INCIDENT during Part 1: after 3 subjects (AD26, AD28, AD29)
completed, the batch crashed with a Bus error (core dumped) during
sub-AD30's Segment step - a container-level crash, not a MATLAB/
SPM script error. No partial output was written for AD30 itself
(confirmed empty anat/ directory). Resolved by fully restarting
the environment (same fix that resolved an earlier similar glitch
during sub-AD01's Module 4 run) and resuming the batch from AD30
onward. All 12 remaining subjects completed cleanly after restart.

A second, related issue was discovered afterward: sub-AD29,
despite its Part 1 log showing "Segment ... Completed" with no
error, had written a 0-byte y_sub-AD29_T1w.nii deformation field -
a silent corruption, likely caused by the same underlying
instability that crashed AD30 shortly after, but without SPM
reporting a failure. This was caught only when Part 2 subsequently
failed to read the corrupt file ("Error reading header file").
The try/catch wrapper in the batch script correctly logged the
Part 2 failure and continued to the remaining 14 subjects rather
than halting. sub-AD29 was recovered by deleting the corrupt file
and re-running Part 1 and Part 2 individually; the retry completed
cleanly with a valid deformation field.

This incident is noted as a genuine feasibility finding: batch
automation on this environment can fail silently as well as
loudly, and per-subject output validation (not just log inspection)
is necessary to catch corruption that does not raise an explicit
error at the point of failure.

Header check, geometry check, and two-stage visual QC (native +
MNI) confirmed clean for all 15 subjects, including sub-AD29 post-
recovery.

Results:
  sub-AD26: SUVR 1.9910 -> 92.03 CL
  sub-AD28: SUVR 2.2062 -> 112.20 CL
  sub-AD29: SUVR 1.9300 -> 86.32 CL
  sub-AD30: SUVR 2.2252 -> 113.98 CL
  sub-AD31: SUVR 1.8170 -> 75.72 CL
  sub-AD32: SUVR 1.8527 -> 79.08 CL
  sub-AD33: SUVR 1.8544 -> 79.23 CL
  sub-AD34: SUVR 1.9684 -> 89.91 CL
  sub-AD36: SUVR 2.1326 -> 105.31 CL
  sub-AD38: SUVR 2.1859 -> 110.30 CL
  sub-AD39: SUVR 1.8214 -> 76.14 CL
  sub-AD40: SUVR 2.0962 -> 101.89 CL
  sub-AD42: SUVR 2.3401 -> 124.75 CL
  sub-AD43: SUVR 2.1982 -> 111.45 CL
  sub-AD44: SUVR 1.8490 -> 78.73 CL

All 15 pass sanity checks and fall within the established AD-range
pattern. sub-AD29's absolute uptake values (cortex 0.0066,
cerebellum 0.0034) are notably smaller by orders of magnitude than
any other subject in the dataset - an extreme case of the known
absolute-scale variation across subjects. Given this coincides
with sub-AD29 being the one subject requiring corruption recovery
in this batch, it is documented explicitly here rather than
treated as unremarkable, though the SUVR ratio (1.93) and full QC
pass are consistent with a valid result.

AD-100 COHORT COMPLETE: all 45 AD subjects (AD01-AD45) now
successfully processed and validated. Combined with 11 YC
subjects processed to date, total valid subjects: 56.

Full AD-group Centiloid range: 54.79 - 127.64 CL (n=45).
Full YC-group Centiloid range: -2.85 to 9.97 CL (n=11).

Conclusion:
The complete AD-100 cohort is now processed, including full
recovery of all 7 originally flagged orientation-defect subjects.
Remaining work: complete YC processing (23 of 34 subjects remain,
pending investigation of the separate wild-origin-value issue),
and revisit sub-AD01's original QC using the more rigorous
two-stage process developed later in the project.

## 2026-08-13 (continued)

### SIGNIFICANT FINDING: sub-AD01 re-QC and origin-precision
sensitivity analysis.

Revisited sub-AD01 - the very first subject processed in this
project - applying the more rigorous two-stage visual QC process
developed later (explicit native-space and MNI-space checks,
closely inspected sagittal view) rather than trusting the original
pass, which predated this standard.

Result: native-space coregistration (PET vs own T1) was confirmed
correctly aligned - Module 1 (Coregister) was never the issue.
However, MNI-space alignment (swPET vs MNI152 template) showed a
slight but real misalignment on close sagittal inspection, not
present in any subject processed after AD01.

Investigation: T1 header confirmed normal (qform_code=1,
sform_code=2, matching all valid subjects) - ruled out a data-
quality defect. Since Coregister was independently confirmed
correct, the issue was isolated to Segment's T1-to-MNI affine
registration, which depends on the manually-clicked T1 origin as
its starting point. sub-AD01 was the very first subject on which
the Set Origin/Reorient technique was ever performed, before
practice improved click precision (evidenced by Coregister
convergence times dropping from ~20 minutes on AD01's original
uncorrected attempt to consistently 10-30 seconds on all
subsequent subjects).

Fix: re-clicked sub-AD01's T1 origin with the benefit of
accumulated practice, re-ran Segment, Normalise, and Smooth
(Coregister/Module 1 was not repeated, since it was already
confirmed correct and does not depend on the T1 origin refinement).

Result: MNI-space visual QC now passes cleanly, matching the
standard of all other subjects.

QUANTITATIVE IMPACT:
  Original (imprecise T1 origin click):
    Cortex 10.210826, Cerebellum 4.472877, SUVR 2.2828, CL 119.38
  Refined (precise T1 origin click):
    Cortex 11.884938, Cerebellum 5.765136, SUVR 2.0615, CL 98.64
  Difference: 21 CL

This is a genuinely significant finding, not a minor correction:
manual origin-correction precision has a real, non-trivial effect
on final Centiloid values, despite both versions passing native-
space visual QC. This represents a documented source of operator-
dependent variability inherent to any pipeline requiring manual
intervention to compensate for header-defective source data (as
this dataset's AD-100 cohort required for the vast majority of
subjects). This is considered a legitimate methodological
limitation to report explicitly, not a flaw to conceal - and
arguably strengthens the feasibility study by quantifying a real
source of pipeline variability rather than only reporting clean
final numbers.

results/tables/suvr_centiloid_summary.csv updated with the refined
sub-AD01 value (98.64 CL, down from 119.38 CL). This does not
change AD01's classification (still clearly amyloid-positive,
still within the valid AD-range pattern) but is a materially
different number that would affect any statistical summary (mean,
range) computed across the AD group.

IMPLICATION FOR FUTURE WORK: given this finding, a systematic re-
QC pass across other early-processed subjects (particularly AD02
and AD03, processed before the two-stage QC standard was fully
established) may be warranted, time permitting, to check whether
similar origin-precision effects are present elsewhere in the
dataset.
