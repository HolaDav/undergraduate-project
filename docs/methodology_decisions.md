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
