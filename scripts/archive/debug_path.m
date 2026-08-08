base_dir = '/home/jovyan/Desktop/workspace/undergraduate_project';
subject_id = 'sub-AD02';
deformation_field = fullfile(base_dir, 'rawdata', subject_id, 'anat', ['y_' subject_id '_T1w.nii']);
fprintf('Path being checked: [%s]\n', deformation_field);
fprintf('isfile result: %d\n', isfile(deformation_field));
