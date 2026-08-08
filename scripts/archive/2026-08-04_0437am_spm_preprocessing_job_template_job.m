%-----------------------------------------------------------------------
% Job saved on 04-Aug-2026 03:38:00 by cfg_util (rev $Rev: 7345 $)
% spm SPM - Unknown
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.spatial.coreg.estimate.ref = {'/home/jovyan/Desktop/workspace/undergraduate_project/rawdata/sub-AD01/anat/sub-AD01_T1w.nii,1'};
matlabbatch{1}.spm.spatial.coreg.estimate.source = {'/home/jovyan/Desktop/workspace/undergraduate_project/rawdata/sub-AD01/pet/sub-AD01_trc-pib_pet.nii,1'};
matlabbatch{1}.spm.spatial.coreg.estimate.other = {''};
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
matlabbatch{2}.spm.spatial.normalise.write.subj.def = {'/home/jovyan/Desktop/workspace/undergraduate_project/rawdata/sub-AD01/anat/y_sub-AD01_T1w.nii'};
matlabbatch{2}.spm.spatial.normalise.write.subj.resample = {'/home/jovyan/Desktop/workspace/undergraduate_project/rawdata/sub-AD01/pet/sub-AD01_trc-pib_pet.nii,1'};
matlabbatch{2}.spm.spatial.normalise.write.woptions.bb = [-90 -126 -72
                                                          90 90 108];
matlabbatch{2}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
matlabbatch{2}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{2}.spm.spatial.normalise.write.woptions.prefix = 'w';
