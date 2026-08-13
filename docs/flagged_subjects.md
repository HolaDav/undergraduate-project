# Flagged Subjects — Excluded Pending Investigation

Subjects excluded from the main processing pipeline due to
data-quality issues that could not be resolved with the standard
origin-correction workflow. Tracked separately so they are not
silently dropped or forgotten.

## sub-AD10

**Issue:** Left-right and superior-inferior mirroring in both
native PET and after normalization, visible in FSLeyes sagittal
and axial views.

**Root cause (confirmed):** PET header has no valid orientation
information at all — qform_code = 0 (Unknown) and sform_code = 0
(Unknown), with sform orientations explicitly reported as
"Unknown/Unknown/Unknown" on a pristine, freshly re-copied file
from sourcedata/. This differs from the AD01-style problem (where
qform and sform disagreed but both existed); AD10's PET simply
lacks orientation metadata entirely, so there is no valid
transform to copy or fall back on.

Confirmed NOT caused by our own processing: verified against a
freshly re-copied, untouched file from sourcedata/, which showed
the same missing-orientation header before any manual correction
was applied.

T1 header for this subject is normal (Right-to-Left, matches all
other subjects) - the issue is isolated to the PET file.

**Status:** Excluded from results/tables/suvr_centiloid_summary.csv
pending manual investigation (visual comparison against the
subject's own T1 to manually determine and apply the correct
orientation, e.g. via fslswapdim, rather than relying on
copying a non-existent qform/sform).

**Date flagged:** 2026-08-10


## sub-AD23

**Issue:** Same defect as sub-AD10 — PET header has no valid
orientation information at all.

**Root cause (confirmed):** qform_code = 0 (Unknown), sform_code = 0
(Unknown), found via the standard header sanity check now run
before manual origin correction (added to workflow after the
AD10 finding). Not yet visually confirmed via FSLeyes mirroring
check (unlike AD10, caught before any processing was attempted),
but the identical qform_code/sform_code pattern to AD10 is treated
as sufficient grounds to flag proactively rather than attempt
processing and discover the same failure mode after time invested.

**Status:** Excluded from processing pending the same
investigation approach planned for sub-AD10 (manual comparison
against own T1, correct orientation determined manually, fix
applied via fslswapdim or explicit qform/sform construction rather
than copying from a non-existent source).

**Significance:** Second subject with this exact defect pattern
(qform_code=0, sform_code=0) found in the dataset, out of 25 AD
subjects screened for it so far. Suggests this is a real, if
uncommon, systematic data-quality issue in a subset of the GAAIN
PET files, rather than a one-off anomaly — worth investigating
sub-AD10 and sub-AD23 together, and worth screening the remaining
unprocessed subjects (AD26 onward, all YC subjects) for the same
qform_code/sform_code pattern before attempting their manual
origin correction, to catch this earlier and avoid wasted effort.

**Date flagged:** 2026-08-11

## Full screening result (2026-08-11)

A targeted header screen (qform_code and sform_code, matching the
exact pattern found in sub-AD10 and sub-AD23) was run across all
subjects present in rawdata/ at this point. Result: 7 subjects
share the identical qform_code=0, sform_code=0 defect:

  sub-AD10
  sub-AD23
  sub-AD27
  sub-AD35
  sub-AD37
  sub-AD41
  sub-AD45

All 7 are in the AD group (no YC subjects screened this defect
pattern yet, as YC processing had not yet begun at time of
screening - a full YC screen is planned before YC processing
starts).

This confirms the defect is systematic rather than isolated -
occurring in multiple subjects across the AD-100 cohort, likely
originating from a specific source/reconstruction batch within
the original GAAIN data rather than random per-file corruption.
Worth investigating whether these 7 subject IDs share a common
origin (e.g. same scanner site, same reconstruction date) once
individually inspected.

All 7 are excluded from standard processing and flagged for the
same dedicated investigation approach (visual comparison against
own T1, manual orientation correction via fslswapdim rather than
qform/sform copying, since no valid source transform exists).

## YC group screening result (2026-08-12)

The same qform_code/sform_code defect screen was run across
all 34 YC subjects (sub-YC101 through sub-YC134). Result: zero
matches. All 34 YC subjects show qform_code=1, sform_code=2 -
the normal pattern.

This suggests the orientation-metadata defect (found in 7 of 25
AD-100 subjects: AD10, AD23, AD27, AD35, AD37, AD41, AD45) is
isolated to the AD-100 cohort specifically, rather than being a
dataset-wide GAAIN export issue. Possibly indicates a difference
in how the AD-100 and YC-0 collections were originally processed
or exported. Worth noting as an observation in the dissertation's
data-quality discussion, though the underlying cause (scanner,
reconstruction batch, export tool) cannot be determined from the
available metadata alone.

## sub-AD10 — RESOLVED (2026-08-12)

**Root cause confirmed:** The NIfTI file originally provided in
sourcedata/ (AD10_PiB_5070.nii) was produced by a conversion tool
that failed to write valid orientation metadata (qform_code=0,
sform_code=0), likely due to a missing DICOM PatientPosition tag
(0018,5100) - confirmed present as a warning during reconversion.

**Fix:** Reconverted directly from the original DICOM series
(sourcedata/AD-100_PET_5070/dicom/AD10/, 47 slices) using dcm2niix
(bundled with the Neurodesk FSL container). The resulting NIfTI
had valid qform_code=1/sform_code=1 and, on visual inspection, no
mirroring or flip - confirming the DICOM source data itself was
never corrupted, only the original NIfTI conversion.

The reconverted file still required standard origin correction
(Set Origin + Reorient), as its origin defaulted away from brain
center - same as every other subject in this dataset, and
unrelated to the orientation defect itself.

Processed successfully through Modules 1-4 after these two fixes.
Result: SUVR 2.1571, Centiloid 107.60 - consistent with the valid
AD-group range (56.60-127.64 CL).

**Recovery procedure (to be attempted on remaining flagged
subjects AD23, AD27, AD35, AD37, AD41, AD45):**
1. Locate the subject's DICOM series in sourcedata/AD-100_PET_5070/dicom/<ID>/
2. Run: dcm2niix -o <tmp_dir> -f <ID>_reconverted <dicom_dir>
3. Check the resulting file's qform_code/sform_code (expect valid,
   non-zero values if this defect matches AD10's pattern)
4. Visually confirm no mirroring/flip in FSLeyes
5. Copy into rawdata/, apply standard Set Origin + Reorient
6. Proceed through Modules 1-4 as normal
