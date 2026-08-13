base_dir = '/home/jovyan/Desktop/workspace/undergraduate_project';
subject_id = 'sub-AD01';

spm('defaults', 'PET');
spm_jobman('initcfg');

tpm = fullfile(spm('Dir'), 'tpm', 'TPM.nii');

mri_raw = fullfile(base_dir, 'rawdata', subject_id, 'anat', [subject_id, '_T1w.nii']);
pet_raw = fullfile(base_dir, 'rawdata', subject_id, 'pet',  [subject_id, '_trc-pib_pet.nii']);

mri_file = [mri_raw ',1'];
pet_file = [pet_raw ',1'];

deformation_field = fullfile(base_dir, 'rawdata', subject_id, 'anat', ['y_' subject_id '_T1w.nii']);
normalized_pet     = fullfile(base_dir, 'rawdata', subject_id, 'pet',  ['w' subject_id '_trc-pib_pet.nii']);
smoothed_pet       = fullfile(base_dir, 'rawdata', subject_id, 'pet',  ['sw' subject_id '_trc-pib_pet.nii']);

fprintf('\n=== Refining T1 origin: Segment for %s (Coregister NOT repeated - already valid) ===\n\n', subject_id);

clear matlabbatch;

%% MODULE 2: SEGMENTATION
matlabbatch{1}.spm.spatial.preproc.channel.vols = {mri_file};
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.channel.write = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {[tpm ',1']};
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {[tpm ',2']};
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {[tpm ',3']};
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {[tpm ',4']};
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {[tpm ',5']};
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {[tpm ',6']};
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1];
matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;
matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN; NaN NaN NaN];

spm_jobman('run', matlabbatch);

fprintf('\nSegment complete. Proceeding to Normalise + Smooth...\n\n');

clear matlabbatch;

%% MODULE 3: NORMALISE
matlabbatch{1}.spm.spatial.normalise.write.subj.def = {deformation_field};
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {pet_file};
matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-90 -126 -72; 90 90 108];
matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';

%% MODULE 4: SMOOTHING
matlabbatch{2}.spm.spatial.smooth.data = {[normalized_pet ',1']};
matlabbatch{2}.spm.spatial.smooth.fwhm = [8 8 8];
matlabbatch{2}.spm.spatial.smooth.dtype = 0;
matlabbatch{2}.spm.spatial.smooth.im = 0;
matlabbatch{2}.spm.spatial.smooth.prefix = 's';

spm_jobman('run', matlabbatch);

if ~isfile(normalized_pet)
    error('Module 3 Failure: MNI Normalized PET file was not created: %s', normalized_pet);
end
if ~isfile(smoothed_pet)
    error('Module 4 Failure: Smoothed PET image was not created: %s', smoothed_pet);
end

fprintf('\nRefinement complete for %s.\n', subject_id);
fprintf(' Verified Normalized MNI PET Volume: %s\n', normalized_pet);
fprintf(' Verified Smoothed PET Volume: %s\n\n', smoothed_pet);
