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
