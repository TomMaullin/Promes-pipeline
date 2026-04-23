function analysis_info = step6_normalise(analysis_info)

    % Load in details
    ses_dir = analysis_info.ses_dir;
    sub_no = analysis_info.sub_no;
    ses_no = analysis_info.ses_no;
    task_name = analysis_info.task_name;
    run_no = analysis_info.run_no;

    % Get the path for the aligned functional data
    au_func_file = analysis_info.func_vol_curr;
    
    % Read headers using SPM
    V = spm_vol(au_func_file);
    
    % Number of volumes
    nVols = numel(V);
    
    % Get a cell of preprocessed functional bold timeseries volumes
    au_func_vols = reshape(arrayfun(@(v) sprintf('%s,%d', au_func_file, v), ...
                            1:nVols, 'UniformOutput', false), [], 1);
    
    % Get the mean image
    mean_img = {analysis_info.func_mean_curr};
    
    % Get the bias corrected structural
    anat_img = {char(analysis_info.anat_vol_curr + ",1")};

    % Native-space tissue classes from segmentation
    c1_file = {analysis_info.c1_file_curr};
    c2_file = {analysis_info.c2_file_curr};
    c3_file = {analysis_info.c3_file_curr};

    % Write matlabbatch
    clear matlabbatch
    matlabbatch{1}.spm.spatial.normalise.write.subj.def = {analysis_info.deform};
    matlabbatch{1}.spm.spatial.normalise.write.subj.resample = [au_func_vols; mean_img; anat_img; c2_file; c1_file; c3_file];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70; 78 76 85];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
    matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';

    % Run in SPM jobman
    my_log('Normalising to MNI...')
    spm_jobman('run', matlabbatch);

    % Update analysis info
    analysis_info.func_vol_curr = prepend(analysis_info.func_vol_curr, 'w');
    analysis_info.anat_vol_curr = fullfile(char(ses_dir), 'anat', sprintf('wmsub-%03d_ses-%02d_T1w.nii', sub_no, ses_no));
    analysis_info.c1_file_curr = fullfile(char(ses_dir), 'anat', sprintf('wc1sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no));
    analysis_info.c2_file_curr = fullfile(char(ses_dir), 'anat', sprintf('wc2sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no));
    analysis_info.c3_file_curr = fullfile(char(ses_dir), 'anat', sprintf('wc3sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no));

end