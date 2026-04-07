
function analysis_info = step2_realign_and_unwarp(analysis_info)

    % Load in details
    ses_dir = analysis_info.ses_dir;
    sub_no = analysis_info.sub_no;
    ses_no = analysis_info.ses_no;
    task_name = analysis_info.task_name;
    run_no = analysis_info.run_no;

    % Get the path for the functional data
    func_file = analysis_info.func_vol_curr;
    
    % Read headers using SPM
    V = spm_vol(func_file);
    
    % Number of volumes
    nVols = numel(V);
    
    % Create matlabbatch
    clear matlabbatch
    matlabbatch{1}.spm.spatial.realignunwarp.data.scans = reshape(arrayfun(@(v) sprintf('%s,%d', func_file, v), 1:nVols, 'UniformOutput', false), [], 1);
    matlabbatch{1}.spm.spatial.realignunwarp.data.pmscan = {char(analysis_info.vdm5 + ",1")};    
    matlabbatch{1}.spm.spatial.realignunwarp.eoptions.quality = 0.95;
    matlabbatch{1}.spm.spatial.realignunwarp.eoptions.sep = 1.5;
    matlabbatch{1}.spm.spatial.realignunwarp.eoptions.fwhm = 1;
    matlabbatch{1}.spm.spatial.realignunwarp.eoptions.rtm = 1;
    matlabbatch{1}.spm.spatial.realignunwarp.eoptions.einterp = 2;
    matlabbatch{1}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
    matlabbatch{1}.spm.spatial.realignunwarp.eoptions.weight = '';
    matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
    matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
    matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
    matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
    matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.sot = [];
    matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 2;
    matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.rem = 1;
    matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.noi = 5;
    matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
    matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
    matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.jm = 1;
    matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;
    matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.mask = 1;

    % Run in SPM jobman
    my_log('Running realign and unwarp...')
    spm_jobman('run', matlabbatch);

    % Update analysis info
    analysis_info.func_vol_curr = fullfile(char(ses_dir), 'func', sprintf('usub-%03d_ses-%02d_task-%s_run-%d_bold.nii', sub_no, ses_no, task_name, run_no));
    analysis_info.func_mean_curr = fullfile(char(ses_dir), 'func', sprintf('meanusub-%03d_ses-%02d_task-%s_run-%d_bold.nii', sub_no, ses_no, task_name, run_no));
    analysis_info.realign_params = fullfile(char(ses_dir), 'func', sprintf('rp_sub-%03d_ses-%02d_task-%s_run-%d_bold.txt', sub_no, ses_no, task_name, run_no));

end