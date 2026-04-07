function run_promes(data_dir, ses_no, sub_no)

    % Get path of this function
    promes_function = mfilename('fullpath');
    [promes_dir, ~, ~] = fileparts(promes_function);
    
    % Add the path to preprocessing scripts
    addpath(fullfile(promes_dir, 'src'));
    addpath(fullfile(promes_dir, 'src', 'util'));
    addpath(fullfile(promes_dir, 'src', 'preproc'));
    
    % Set version number
    ver = '0.01';
    
    % Make a header to let user know we are starting
    make_header(ver)
    
    % Check SPM is loaded
    if isempty(which('spm'))
        my_log('SPM not found. Halting execution.')
        error('SPM is not on the MATLAB path. Please add it before running this script.');
    else
        spm('Defaults','fMRI');
    end
    
    % Check CONN is loaded
    if isempty(which('conn'))
        my_log('SPM CONN not found. Halting execution.')
        error('SPM CONN is not on the MATLAB path. Please add it before running this script.');
    end
    
    % Get first session and subject
    ses_dir = fullfile(data_dir, sprintf('sub-%03d', sub_no), sprintf('ses-%02d', ses_no));
    
    % Create a struct to house filenames
    analysis_info = {};
    analysis_info.data_dir = data_dir;
    analysis_info.ses_dir = ses_dir;
    
    % Events csv
    analysis_info.events = fullfile(char(ses_dir),'events.tsv');
    
    % Add functional data
    analysis_info.func_vol_orig = fullfile(char(ses_dir), 'func', sprintf('sub-%03d_ses-%02d_task-AudCat_run-1_bold.nii', sub_no, ses_no));
    analysis_info.func_vol_curr = analysis_info.func_vol_orig;
    
    % Add structural data
    analysis_info.anat_vol_orig = fullfile(char(ses_dir), 'anat', sprintf('sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no));
    analysis_info.anat_vol_curr = analysis_info.anat_vol_orig;
    
    % Add fmap data
    analysis_info.phasediff = fullfile(char(ses_dir), 'fmap', sprintf('sub-%03d_ses-%02d_phasediff.nii', sub_no, ses_no));
    analysis_info.mag1 = fullfile(char(ses_dir), 'fmap', sprintf('sub-%03d_ses-%02d_magnitude1.nii', sub_no, ses_no));
    
    % Add jsons
    analysis_info.func_json =  fullfile(char(ses_dir), 'func', sprintf('sub-%03d_ses-%02d_task-AudCat_run-1_bold.json', sub_no, ses_no));
    analysis_info.phas_json =  fullfile(char(ses_dir), 'fmap', sprintf('sub-%03d_ses-%02d_phasediff.json', sub_no, ses_no));
    
    % Unzip the functional nii.gz files if needed
    func_files = dir(fullfile(ses_dir, 'func', '*.nii.gz'));
    if ~isempty(func_files)
        gunzip(fullfile(ses_dir, "func", "*.nii.gz"))
    end
    
    % Unzip the structural nii.gz files if needed
    anat_files = dir(fullfile(ses_dir, 'anat', '*.nii.gz'));
    if ~isempty(anat_files)
        gunzip(fullfile(ses_dir, "anat", "*.nii.gz"))
    end
    
    % Unzip the fieldmap nii.gz files if needed
    fmap_files = dir(fullfile(ses_dir, 'fmap', '*.nii.gz'));
    if ~isempty(fmap_files)
        gunzip(fullfile(ses_dir, "fmap", "*.nii.gz"))
    end
    
    % Load SPM defaults
    my_log("Initalising SPM...")
    spm('defaults', 'fmri'); 
    spm_jobman('initcfg');
    
    % Run task processing pipeline for session
    analysis_info = task_preprocessing(analysis_info);
    
    % Run rest processing pipeline for session
    analysis_info = rest_preprocessing(analysis_info);

end