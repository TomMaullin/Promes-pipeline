function analysis_info = step12_cleanup_preproc(analysis_info)

    % Load in details
    data_dir = analysis_info.data_dir;
    sub_dir = analysis_info.sub_dir;
    ses_dir = analysis_info.ses_dir;
    sub_no = analysis_info.sub_no;
    ses_no = analysis_info.ses_no;
    task_name = analysis_info.task_name;
    run_no = analysis_info.run_no;

    % Inform user
    my_log('Cleaning up files...')

    % Remove denoising files
    delete(fullfile(char(ses_dir),sprintf('step9_denoise_task-%s_run-%d.mat', task_name, run_no)));
    denoise_dir = fullfile(char(ses_dir), sprintf('step9_denoise_task-%s_run-%d', task_name, run_no));
    if exist(denoise_dir, 'dir')
        rmdir(denoise_dir, 's');
    end

    % Remove redundant top level files
    delete(fullfile(char(data_dir), 'spm_*.ps'));
    delete(fullfile(char(sub_dir), 'SPM.mat'));
    delete(fullfile(char(sub_dir), sprintf('LI_r_sub-%03d_ses-%02d*%s_run-%d*_spmT_0001.nii', sub_no, ses_no, task_name, run_no)));

    % Delete redundant functional files
    delete(fullfile(char(ses_dir), 'func', 'SPM.mat'));
    delete(fullfile(char(ses_dir), 'func', 'spm_*.ps'));
    delete(fullfile(char(ses_dir), 'func', 'spm_*.pdf'));
    delete(fullfile(char(ses_dir), 'func', 'spm_*.png'));
    delete(fullfile(char(ses_dir), 'func', 'spm_*.xls'));
    delete(fullfile(char(ses_dir), 'func', 'ResMS.nii'));
    delete(fullfile(char(ses_dir), 'func', 'beta_*.nii'));
    delete(fullfile(char(ses_dir), 'func', 'mask.nii'));
    delete(fullfile(char(ses_dir), 'func', 'RPV.nii'));
    delete(fullfile(char(ses_dir), 'func', 'art_*'));
    delete(fullfile(char(ses_dir), 'func', sprintf('LI_r_sub-%03d_ses-%02d*%s_run-%d*_spmT_0001.nii', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('sub-%03d_ses-%02d*%s_run-%d*_con_001.nii', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('ds*mwausub-%03d_ses-%02d*%s_run-%d*.nii', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('s*mwausub-%03d_ses-%02d*%s_run-%d*.nii', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('mwausub-%03d_ses-%02d*%s_run-%d*.nii', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('wausub-%03d_ses-%02d*%s_run-%d*.nii', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('ausub-%03d_ses-%02d*%s_run-%d*.nii', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('usub-%03d_ses-%02d*%s_run-%d*.nii', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('wfmag_sub-%03d_ses-%02d*%s_run-%d*.nii', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('wmeanusub-%03d_ses-%02d*%s_run-%d*.nii', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('meanusub-%03d_ses-%02d*%s_run-%d*.nii', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('rp_sub-%03d_ses-%02d*%s_run-%d*.txt', sub_no, ses_no, task_name, run_no)));
    delete(fullfile(char(ses_dir), 'func', sprintf('sub-%03d_ses-%02d*%s_run-%d*.mat', sub_no, ses_no, task_name, run_no)));

    % Delete redundant structural files
    delete(fullfile(char(ses_dir), 'anat', sprintf('c*sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no)));
    % delete(fullfile(char(ses_dir), 'anat', sprintf('wc*sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no)));
    delete(fullfile(char(ses_dir), 'anat', sprintf('ewc*sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no)));
    delete(fullfile(char(ses_dir), 'anat', sprintf('msub-%03d_ses-%02d_T1w.nii', sub_no, ses_no)));
    delete(fullfile(char(ses_dir), 'anat', sprintf('y_sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no)));
    delete(fullfile(char(ses_dir), 'anat', sprintf('sub-%03d_ses-%02d_T1w_seg8.mat', sub_no, ses_no)));

    % Delete redundant fmap files
    delete(fullfile(char(ses_dir), 'fmap', sprintf('fpm_scsub-%03d_ses-%02d_phasediff.nii', sub_no, ses_no)))
    delete(fullfile(char(ses_dir), 'fmap', sprintf('vdm5_scsub-%03d_ses-%02d_phasediff.nii', sub_no, ses_no)))
    delete(fullfile(char(ses_dir), 'fmap', sprintf('scsub-%03d_ses-%02d_phasediff.nii', sub_no, ses_no)))

end