function analysis_info = step4_structural_coregistration(analysis_info)

    % Create matlabbatch
    clear matlabbatch
    matlabbatch{1}.spm.spatial.coreg.estimate.ref = {char(analysis_info.func_mean_curr + ",1")};  
    matlabbatch{1}.spm.spatial.coreg.estimate.source = {char(analysis_info.anat_vol_curr + ",1")};  
    matlabbatch{1}.spm.spatial.coreg.estimate.other = {''};
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

    % Run in SPM jobman
    my_log('Coregistering structural to mean functional...')
    spm_jobman('run', matlabbatch);

end