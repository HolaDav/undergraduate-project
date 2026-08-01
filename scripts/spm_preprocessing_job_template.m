%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% spm_preprocessing_job_template.m
%
% Undergraduate Radiography Project
%
% Project:
% Evaluation of a Cloud-Based Quantitative Amyloid PET Imaging Workflow
% for Resource-Constrained Nigerian Settings
%
% Purpose:
% Performs SPM12 preprocessing of a static PiB PET image using a
% corresponding T1-weighted MRI.
%
% Inputs (provided by 04_preprocess_subject.sh):
%
%   mri_file
%   pet_file
%   output_directory
%
% Processing Steps:
%
%   1. Coregister PET to MRI
%   2. Segment MRI
%   3. Estimate deformation field
%   4. Normalize PET to MNI space
%   5. Smooth PET (8 mm FWHM)
%
% Outputs:
%
%   wPET.nii
%   swPET.nii
%   deformation field
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

spm('defaults','PET');
spm_jobman('initcfg');

matlabbatch = {};

% -------------------------------------------------------------------------
% Module 1
% PET -> MRI Coregistration
% -------------------------------------------------------------------------

% Reference image (MRI)
matlabbatch{1}.spm.spatial.coreg.estimate.ref = {
    [mri_file ',1']
};

% Source image (PET)
matlabbatch{1}.spm.spatial.coreg.estimate.source = {
    [pet_file ',1']
};

% Other images
matlabbatch{1}.spm.spatial.coreg.estimate.other = {
    ''
};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cost Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Separation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Tolerances
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = ...
[0.02 0.02 0.02 ...
 0.001 0.001 0.001 ...
 0.01 0.01 0.01 ...
 0.001 0.001 0.001];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Smoothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

% -------------------------------------------------------------------------
% Module 2
% MRI Segmentation
% -------------------------------------------------------------------------

% (To be added)

% -------------------------------------------------------------------------
% Module 3
% Apply deformation field to PET
% -------------------------------------------------------------------------

% (To be added)

% -------------------------------------------------------------------------
% Module 4
% Smooth normalized PET
% -------------------------------------------------------------------------

% (To be added)

% -------------------------------------------------------------------------
% Execute Batch
% -------------------------------------------------------------------------

% spm_jobman('run',matlabbatch);
