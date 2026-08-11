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
