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
