base_dir = '/home/jovyan/Desktop/workspace/undergraduate_project';
subject_id = 'sub-AD01';

fprintf('\n');
fprintf('=============================================\n');
fprintf(' Validating %s\n', subject_id);
fprintf('=============================================\n');

mri_file = fullfile(base_dir, 'rawdata', subject_id, 'anat', [subject_id '_T1w.nii']);
pet_file = fullfile(base_dir, 'rawdata', subject_id, 'pet', [subject_id '_trc-pib_pet.nii']);

if ~isfile(mri_file)
    error('MRI not found:\n%s', mri_file);
end
fprintf('✓ MRI found\n');

if ~isfile(pet_file)
    error('PET not found:\n%s', pet_file);
end
fprintf('✓ PET found\n');

mri_hdr = spm_vol(mri_file);
pet_hdr = spm_vol(pet_file);
fprintf('✓ MRI header readable\n');
fprintf('✓ PET header readable\n');

fprintf('\nMRI dimensions:\n');
disp(mri_hdr.dim)
fprintf('PET dimensions:\n');
disp(pet_hdr.dim)

mri_vox = sqrt(sum(mri_hdr.mat(1:3,1:3).^2));
pet_vox = sqrt(sum(pet_hdr.mat(1:3,1:3).^2));
fprintf('\nMRI voxel size (mm):\n');
disp(mri_vox)
fprintf('PET voxel size (mm):\n');
disp(pet_vox)

fprintf('\n');
fprintf('✓ Validation PASSED\n');
fprintf('=============================================\n');
