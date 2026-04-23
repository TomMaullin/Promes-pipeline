function analysis_info = step5_segmentation(analysis_info)

    % Load in details
    ses_dir = analysis_info.ses_dir;
    sub_no = analysis_info.sub_no;
    ses_no = analysis_info.ses_no;
    
    % Write matlabbatch
    clear matlabbatch
    matlabbatch{1}.spm.spatial.preproc.channel.vols = {char(analysis_info.anat_vol_curr + ",1")}; 
    matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.0001;
    matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
    matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1];
    matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {fullfile(spm('Dir'), 'tpm', 'TPM.nii,1')};
    matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
    matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {fullfile(spm('Dir'), 'tpm', 'TPM.nii,2')};
    matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
    matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {fullfile(spm('Dir'), 'tpm', 'TPM.nii,3')};
    matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
    matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {fullfile(spm('Dir'), 'tpm', 'TPM.nii,4')};
    matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
    matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {fullfile(spm('Dir'), 'tpm', 'TPM.nii,5')};
    matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
    matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {fullfile(spm('Dir'), 'tpm', 'TPM.nii,6')};
    matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
    matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
    matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
    matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0 0.1 0.01 0.04];
    matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
    matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
    matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
    matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1];
    matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;
    matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN; NaN NaN NaN];

    % Run in SPM jobman
    my_log('Performing segmentation...')
    spm_jobman('run', matlabbatch);

    % Save files
    analysis_info.c1_file_curr = fullfile(char(ses_dir), 'anat', sprintf('c1sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no));
    analysis_info.c2_file_curr = fullfile(char(ses_dir), 'anat', sprintf('c2sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no));
    analysis_info.c3_file_curr = fullfile(char(ses_dir), 'anat', sprintf('c3sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no));
    analysis_info.deform = fullfile(char(ses_dir), 'anat', sprintf('y_sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no));
    analysis_info.anat_vol_curr = fullfile(char(ses_dir), 'anat', sprintf('msub-%03d_ses-%02d_T1w.nii', sub_no, ses_no)); 

end