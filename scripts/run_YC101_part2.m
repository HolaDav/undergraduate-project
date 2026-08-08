base_dir = '/home/jovyan/Desktop/workspace/undergraduate_project';
subject_id = 'sub-YC101';

spm('defaults', 'PET');
spm_jobman('initcfg');

pet_raw = fullfile(base_dir, 'rawdata', subject_id, 'pet', [subject_id, '_trc-pib_pet.nii']);
pet_file = [pet_raw ',1'];

deformation_field = fullfile(base_dir, 'rawdata', subject_id, 'anat', ['y_' subject_id '_T1w.nii']);
normalized_pet     = fullfile(base_dir, 'rawdata', subject_id, 'pet',  ['w' subject_id '_trc-pib_pet.nii']);
smoothed_pet       = fullfile(base_dir, 'rawdata', subject_id, 'pet',  ['sw' subject_id '_trc-pib_pet.nii']);

fprintf('\n=== Part 2: Normalise + Smooth for %s ===\n\n', subject_id);

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

fprintf('\nPart 2 complete for %s.\n', subject_id);
fprintf(' Verified Normalized MNI PET Volume: %s\n', normalized_pet);
fprintf(' Verified Smoothed PET Volume: %s\n\n', smoothed_pet);
