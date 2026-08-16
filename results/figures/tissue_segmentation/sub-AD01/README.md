# Tissue Segmentation Reference Figures

Visual record of the SPM12 automated tissue segmentation outputs, generated to demonstrate the successful performance of the multi-channel Bayesian classification algorithm on the project's pilot subject.

## Subjects included and why

- **sub-AD01** — pilot subject; first subject processed in this project. Used here as the baseline reference to visually validate Grey Matter (GM), White Matter (WM), and Cerebrospinal Fluid (CSF) tissue masks before group-level statistical processing.

## Files and Tissue Classes Shown

The figures in this folder correspond to a 4-panel multi-planar or side-by-side view capturing the identical anatomical slice coordinate across the primary SPM12 output files:

1. **`A_bias_corrected_structural.png`** (derived from `msub-AD01_T1w.nii`)  
   The T1-weighted reference structural scan after SPM12 intensity non-uniformity correction. Shading artifacts have been removed to ensure uniform tissue contrast across the field of view.
   
2. **`B_grey_matter_probability.png`** (derived from `c1sub-AD01_T1w.nii`)  
   The isolated Grey Matter (GM) tissue probability map, mapping the cortical ribbon, deep grey nuclei (thalamus, striatum), and cerebellar cortex.
   
3. **`C_white_matter_probability.png`** (derived from `c2sub-AD01_T1w.nii`)  
   The isolated White Matter (WM) tissue probability map, delineating subcortical myelinated axonal fiber tracts and internal capsule pathways.
   
4. **`D_cerebrospinal_fluid_probability.png`** (derived from `c3sub-AD01_T1w.nii`)  
   The isolated Cerebrospinal Fluid (CSF) tissue probability map, highlighting the lateral, third, and fourth ventricles, as well as external subarachnoid sulcal spaces.

## Quality Control & Visualization Settings

- **Software:** Generated using FSLeyes.
- **Display Mode:** Single-slice view set at a representative internal capsule/lateral ventricle axial or coronal coordinate to show all three major tissue types simultaneously.
- **Color Mapping:** 
  - Structural reference (`msub`) is displayed using the standard grayscale linear lookup table.
  - Tissue probability maps (`c1`, `c2`, `c3`) use a linear intensity mapping where voxel values correspond strictly to a continuous scale: **0.0 (Black; 0% probability)** to **1.0 (White; 100% probability)**.
- **Formatting:** Crosshairs, grid-lines, and coordinate orientation labels are hidden for publication-grade layout clarity.
