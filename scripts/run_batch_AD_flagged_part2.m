base_dir = '/home/jovyan/Desktop/workspace/undergraduate_project';
subject_list = {'sub-AD27', 'sub-AD35', 'sub-AD37', 'sub-AD41', 'sub-AD45'};

spm('defaults', 'PET');
spm_jobman('initcfg');

for s = 1:numel(subject_list)
    subject_id = subject_list{s};

    fprintf('\n=== [%d/%d] Part 2: Normalise + Smooth for %s ===\n\n', s, numel(subject_list), subject_id);

    pet_raw = fullfile(base_dir, 'rawdata', subject_id, 'pet', [subject_id, '_trc-pib_pet.nii']);
    pet_file = [pet_raw ',1'];

    deformation_field = fullfile(base_dir, 'rawdata', subject_id, 'anat', ['y_' subject_id '_T1w.nii']);
    normalized_pet     = fullfile(base_dir, 'rawdata', subject_id, 'pet',  ['w' subject_id '_trc-pib_pet.nii']);
    smoothed_pet       = fullfile(base_dir, 'rawdata', subject_id, 'pet',  ['sw' subject_id '_trc-pib_pet.nii']);

    if ~isfile(deformation_field)
        fprintf('SKIPPING %s: deformation field missing.\n', subject_id);
        continue;
    end

    clear matlabbatch;

    matlabbatch{1}.spm.spatial.normalise.write.subj.def = {deformation_field};
    matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {pet_file};
    matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-90 -126 -72; 90 90 108];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
    matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';

    matlabbatch{2}.spm.spatial.smooth.data = {[normalized_pet ',1']};
    matlabbatch{2}.spm.spatial.smooth.fwhm = [8 8 8];
    matlabbatch{2}.spm.spatial.smooth.dtype = 0;
    matlabbatch{2}.spm.spatial.smooth.im = 0;
    matlabbatch{2}.spm.spatial.smooth.prefix = 's';

    try
        spm_jobman('run', matlabbatch);
        if isfile(normalized_pet) && isfile(smoothed_pet)
            fprintf('%s: Part 2 OK.\n', subject_id);
        else
            fprintf('%s: Part 2 ran but output files missing - CHECK.\n', subject_id);
        end
    catch ME
        fprintf('%s: Part 2 FAILED - %s\n', subject_id, ME.message);
    end
end

fprintf('\nBatch Part 2 complete.\n');
