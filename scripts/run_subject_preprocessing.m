function run_subject_preprocessing(base_dir, subject_id)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% INITIALIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN_SUBJECT_PREPROCESSING
% Automatically runs SPM12 Coregistration, Segmentation, and Normalization.
%
% Usage:
%   run_subject_preprocessing('/path/to/project', 'sub-AD01')

spm('defaults', 'PET');
spm_jobman('initcfg');

% Dynamic TPM Path (Portable across SPM installations)
tpm = fullfile(spm('Dir'), 'tpm', 'TPM.nii');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PATH CONSTRAINTS & FILE VALIDATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Raw File Paths
mri_raw = fullfile(base_dir, 'rawdata', subject_id, 'anat', [subject_id, '_T1w.nii']);
pet_raw = fullfile(base_dir, 'rawdata', subject_id, 'pet',  [subject_id, '_trc-pib_pet.nii']);

% Check raw input file existence before proceeding
if ~isfile(mri_raw)
    error('MRI file not found: %s', mri_raw);
end

if ~isfile(pet_raw)
    error('PET file not found: %s', pet_raw);
end

% SPM Volume Specifiers (attaching ',1' for single-volume selection)
mri_file = [mri_raw ',1'];
pet_file = [pet_raw ',1'];

% Clear, Descriptive Derived Output File Paths
deformation_field = fullfile(base_dir, 'rawdata', subject_id, 'anat', ['y_' subject_id '_T1w.nii']);
normalized_pet    = fullfile(base_dir, 'rawdata', subject_id, 'pet',  ['w' subject_id '_trc-pib_pet.nii']);

% Print Progress Header
fprintf('\n===================================================\n');
fprintf(' Processing Subject: %s\n', subject_id);
fprintf(' MRI: %s\n', mri_raw);
fprintf(' PET: %s\n', pet_raw);
fprintf('===================================================\n\n');

clear matlabbatch;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MODULE 1: PET -> MRI COREGISTRATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
matlabbatch{1}.spm.spatial.coreg.estimate.ref = {mri_file};
matlabbatch{1}.spm.spatial.coreg.estimate.source = {pet_file};
matlabbatch{1}.spm.spatial.coreg.estimate.other = {''};
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MODULE 2: MRI SEGMENTATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
matlabbatch{2}.spm.spatial.preproc.channel.vols = {mri_file};
matlabbatch{2}.spm.spatial.preproc.channel.biasreg = 0.001;
matlabbatch{2}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{2}.spm.spatial.preproc.channel.write = [1 1];

% Dynamic Tissue Probability Maps (1 to 6)
matlabbatch{2}.spm.spatial.preproc.tissue(1).tpm = {[tpm ',1']};
matlabbatch{2}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{2}.spm.spatial.preproc.tissue(1).native = [1 0];
matlabbatch{2}.spm.spatial.preproc.tissue(1).warped = [0 0];

matlabbatch{2}.spm.spatial.preproc.tissue(2).tpm = {[tpm ',2']};
matlabbatch{2}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{2}.spm.spatial.preproc.tissue(2).native = [1 0];
matlabbatch{2}.spm.spatial.preproc.tissue(2).warped = [0 0];

matlabbatch{2}.spm.spatial.preproc.tissue(3).tpm = {[tpm ',3']};
matlabbatch{2}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{2}.spm.spatial.preproc.tissue(3).native = [1 0];
matlabbatch{2}.spm.spatial.preproc.tissue(3).warped = [0 0];

matlabbatch{2}.spm.spatial.preproc.tissue(4).tpm = {[tpm ',4']};
matlabbatch{2}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{2}.spm.spatial.preproc.tissue(4).native = [1 0];
matlabbatch{2}.spm.spatial.preproc.tissue(4).warped = [0 0];

matlabbatch{2}.spm.spatial.preproc.tissue(5).tpm = {[tpm ',5']};
matlabbatch{2}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{2}.spm.spatial.preproc.tissue(5).native = [1 0];
matlabbatch{2}.spm.spatial.preproc.tissue(5).warped = [0 0];

matlabbatch{2}.spm.spatial.preproc.tissue(6).tpm = {[tpm ',6']};
matlabbatch{2}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{2}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{2}.spm.spatial.preproc.tissue(6).warped = [0 0];

% Deformation Settings & Forward Field Generation
matlabbatch{2}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{2}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{2}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{2}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{2}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{2}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{2}.spm.spatial.preproc.warp.write = [0 1]; % Generates y_*.nii
matlabbatch{2}.spm.spatial.preproc.warp.vox = NaN;
matlabbatch{2}.spm.spatial.preproc.warp.bb = [NaN NaN NaN; NaN NaN NaN];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MODULE 3: NORMALISE (WRITE PET TO MNI SPACE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
matlabbatch{3}.spm.spatial.normalise.write.subj.def = {[deformation_field ',1']};
matlabbatch{3}.spm.spatial.normalise.write.subj.resample = {pet_file};
matlabbatch{3}.spm.spatial.normalise.write.woptions.bb = [-90 -126 -72; 90 90 108];
matlabbatch{3}.spm.spatial.normalise.write.woptions.vox = [2 2 2]; % 2mm isotropic grid for Centiloid VOIs
matlabbatch{3}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{3}.spm.spatial.normalise.write.woptions.prefix = 'w';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXECUTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
spm_jobman('run', matlabbatch);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% POST-EXECUTION OUTPUT VALIDATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isfile(deformation_field)
    error('Module 2 Failure: Deformation field was not created: %s', deformation_field);
end

if ~isfile(normalized_pet)
    error('Module 3 Failure: MNI Normalized PET file was not created: %s', normalized_pet);
end

fprintf('Successfully completed Modules 1, 2, & 3 for %s.\n', subject_id);
fprintf(' Verified Forward Deformation Field: %s\n', deformation_field);
fprintf(' Verified Normalized MNI PET Volume: %s\n\n', normalized_pet);
end
