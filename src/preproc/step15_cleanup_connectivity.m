function analyses_info = step15_cleanup_connectivity(analyses_info)

    % Load in details
    sub_dir = analyses_info{1}.sub_dir;
    ses_dir = analyses_info{1}.ses_dir;
    sub_no = analyses_info{1}.sub_no;
    ses_no = analyses_info{1}.ses_no;

    % Get the number of analyses
    n_analyses = numel(analyses_info);
    
    % Inform user
    my_log('Cleaning up files...')

    % Directory containing connectivity maps
    src_dir = fullfile(char(sub_dir), 'conn_concatenated', 'results', 'firstlevel', 'SBC_01');
    
    % Move files
    % movefile(fullfile(src_dir, 'BETA_Subject001_Condition001_Source001.nii'), fullfile(char(sub_dir), 'conn_LI_IFG_L.nii'));
    % movefile(fullfile(src_dir, 'BETA_Subject001_Condition001_Source002.nii'), fullfile(char(sub_dir), 'conn_LI_IFG_R.nii'));
    % movefile(fullfile(src_dir, 'BETA_Subject001_Condition001_Source003.nii'), fullfile(char(sub_dir), 'conn_LI_pSTG_L.nii'));
    % movefile(fullfile(src_dir, 'BETA_Subject001_Condition001_Source004.nii'), fullfile(char(sub_dir), 'conn_LI_pSTG_R.nii'));

    % Remove denoising files
    delete(fullfile(char(sub_dir),'conn_concatenated.mat'));
    conn_dir = fullfile(char(sub_dir), 'conn_concatenated');
    if exist(conn_dir, 'dir')
        rmdir(conn_dir, 's');
    end

    % Delete redundant functional files
    delete(fullfile(char(sub_dir),'dsub-001_cleaned_rest_only_bold.nii'));

    % Delete redundant LI files
    delete(fullfile(char(sub_dir),'LI_boot.ps'));
    delete(fullfile(char(sub_dir),'LI_output.txt'));
    delete(fullfile(char(sub_dir),'LI_masking.ps'));

    % Delete redundant structural files
    delete(fullfile(char(ses_dir), 'anat', sprintf('wc*sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no)));
    delete(fullfile(char(ses_dir), 'anat', sprintf('ewc*sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no)));

    % Clean up analysis info
    for i = 1:n_analyses

        % Get analysis info struct
        analysis_info = analyses_info{i};

        % Remove dead fields
        analysis_info = rmfield(analysis_info, 'vdm5');
        analysis_info = rmfield(analysis_info, 'func_mean_curr');
        analysis_info = rmfield(analysis_info, 'realign_params');
        analysis_info = rmfield(analysis_info, 'c1_file_curr');
        analysis_info = rmfield(analysis_info, 'c2_file_curr');
        analysis_info = rmfield(analysis_info, 'c3_file_curr');
        analysis_info = rmfield(analysis_info, 'deform');
        analysis_info = rmfield(analysis_info, 'art_outliers');


        % Update connectivity 
        connectivity.IFG.L = fullfile(char(sub_dir), 'conn_LI_IFG_L.nii');
        connectivity.IFG.R = fullfile(char(sub_dir), 'conn_LI_IFG_R.nii');
        connectivity.pSTG.L = fullfile(char(sub_dir), 'conn_LI_pSTG_L.nii');
        connectivity.pSTG.R = fullfile(char(sub_dir), 'conn_LI_pSTG_R.nii');
        analysis_info.connectivity = connectivity;

        % Output analysis info
        analyses_info{i} = analysis_info;

    end

end