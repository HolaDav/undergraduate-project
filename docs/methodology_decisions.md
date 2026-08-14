# Methodology Decisions

## Decision 1

Original CONNExIN workflow included PET frame extraction
and motion correction.

Reason for modification:

The available GAAIN PET data consisted of static
50–70 minute summed PiB images (dim4=1).

Therefore motion correction and frame averaging
were not applicable.

Impact:

Reduced computational burden and processing time.
No effect on Centiloid quantification because
static summed images are the intended input.


## Decision: Hybrid BIDS Workflow

Original source data were preserved unchanged in sourcedata/.

A BIDS-inspired naming convention was implemented within rawdata/
to improve reproducibility and facilitate automated processing.

This approach preserves traceability to the original dataset while
maintaining compatibility with modern neuroimaging workflows.



## Decision: Retain SPM12 Normalization Workflow

The original CONNExIN preprocessing workflow utilized SPM12 for MRI segmentation, spatial normalization, and transformation of PET images into MNI space.

Inspection of the Neurodesk environment confirmed availability of MATLAB, SPM12, FSL, and FSLeyes.

Therefore the original normalization workflow was retained to preserve methodological consistency with Centiloid processing standards.

Only dynamic PET-specific preprocessing steps were removed because the available PET images were already static summed acquisitions.



## Resource tracking limitation
Resource usage (max RAM, CPU%, disk space) was not measured for
the first 9 subjects processed (sub-AD01 through sub-AD08,
sub-YC101). This was identified as a gap on 2026-08-10 and
resource tracking begins from sub-AD09 onward, captured via `top`/
`free -h`/`df -h` snapshots during each subject's Segment step
(the most resource-intensive module). Earlier subjects are recorded
as "not_recorded" in logs/resource_tracking.csv rather than
estimated or omitted, to keep the record honest about what was and
wasn't measured.


## Centiloid VOI mask location
Masks (voi_ctx_2mm.nii, voi_WhlCbl_2mm.nii) originally referenced
directly from sourcedata/Centiloid_Std_VOI/nifti/2mm/ for
sub-AD01 through sub-AD08 and sub-YC101. From sub-AD09 onward,
masks are referenced from masks/ (a working copy) for clearer
path semantics; sourcedata/ retains the original, untouched copy.
Both paths reference identical files - this is a path/organization
change only, not a data change.

## Decision: Scope of origin-precision re-QC following sub-AD01 finding

After discovering that sub-AD01's imprecise initial T1 origin
click produced a 21 CL difference from a refined re-click (see
docs/processing_journal.md, 2026-08-13), the question arose of
whether sub-AD02 and sub-AD03 - also processed relatively early,
before the current two-stage QC standard was fully established -
warranted the same re-QC treatment.

Decision: not performed as a blanket policy. Two reasons:
1. Both sub-AD02 and sub-AD03 passed visual QC without any
   concern raised at the time of original processing, unlike
   sub-AD01, which was specifically flagged as showing a slight
   misalignment before any investigation began.
2. Coregister: Estimate convergence time is a strong indirect
   signal of origin-click precision (a poorly-placed origin gives
   the optimiser a harder starting point, observed directly on
   sub-AD01's original ~20-minute uncorrected attempt). Both
   sub-AD02 (28 seconds) and sub-AD03 (14 seconds) converged
   quickly on their very first origin-corrected attempt, unlike
   sub-AD01's rough first attempt - suggesting technique was
   already reasonably precise by that point.

Caveat acknowledged: this signal reflects PET origin precision
specifically, while sub-AD01's actual issue was in the T1 origin
(affecting Segment/Normalise, not Coregister) - an imperfect proxy,
not direct proof. This is documented as a reasoned scope decision
based on available evidence, not as a claim that no imprecision
exists elsewhere in the dataset. A full systematic re-QC of all
subjects against this specific failure mode was judged out of
scope for this feasibility study, given time constraints and the
absence of any positive evidence prompting it beyond sub-AD01
itself.

## Decision: diagnostic-subject-first approach for the YC wild-origin-value issue

Rather than immediately batch-processing all 23 affected YC
subjects, 3 subjects spanning the apparent sub-patterns in the
origin coordinate values were selected for individual header
inspection first (sub-YC103, sub-YC109, sub-YC116), followed by
full individual processing of the most extreme case (sub-YC103)
before committing to a batch of the remaining 22.

Reason: this issue was initially unexplained, unlike the by-then
well-understood corner-origin pattern. Given the AD-group
orientation-metadata defect had previously required a genuinely
different fix (DICOM reconversion, not just origin correction),
it was not safe to assume the standard fix would apply here without
verification. This mirrors the approach taken for sub-AD10 before
the other 6 flagged AD subjects were batched.

Outcome: confirmed the standard fix applied directly (valid headers
throughout), justifying full-batch processing of the remaining 22
with confidence, rather than processing them individually.
