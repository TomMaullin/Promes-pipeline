function analyses_info = run_promes(data_dir,ses_nos,sub_nos,task_names,run_nos,run_task,run_rest,cleanup)
    
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

    % Check that ses_nos, sub_nos, task_names and run_nos are all the same
    % length
    if ~(numel(ses_nos) == numel(sub_nos) && ...
         numel(sub_nos) == numel(task_names) && ...
         numel(task_names) == numel(run_nos))
        error('ses_nos, sub_nos, task_names, and run_nos must all have the same length.');
    end

    % Create a struct to save analysis details
    analyses_info = {};

    % Get number of analyses
    n_analyses = length(ses_nos);
 
    % Loop through requested analyses
    for i = 1:n_analyses
    
        % Access ith analysis
        ses_no = ses_nos(i);
        sub_no = sub_nos(i);
        task_name = char(task_names(i));
        run_no = run_nos(i);
        
        % Get first session and subject
        ses_dir = fullfile(data_dir, sprintf('sub-%03d', sub_no), sprintf('ses-%02d', ses_no));
        sub_dir = fullfile(data_dir, sprintf('sub-%03d', sub_no));
        
        % Create a struct to house filenames
        analysis_info = {};
        analysis_info.run_task = run_task;
        analysis_info.run_rest = run_rest;
        analysis_info.cleanup = cleanup;
        analysis_info.data_dir = data_dir;
        analysis_info.sub_dir = sub_dir;
        analysis_info.ses_dir = ses_dir;
        analysis_info.ses_no = ses_no;
        analysis_info.sub_no = sub_no;
        analysis_info.task_name = task_name;
        analysis_info.run_no = run_no;
        
        % Events csv
        analysis_info.events = fullfile(char(ses_dir),'events.tsv');
        
        % Add functional data
        analysis_info.func_vol_orig = fullfile(char(ses_dir), 'func',...
            sprintf('sub-%03d_ses-%02d_task-%s_run-%d_bold.nii', sub_no, ses_no, task_name, run_no));
        analysis_info.func_vol_curr = analysis_info.func_vol_orig;
        
        % Add structural data
        analysis_info.anat_vol_orig = fullfile(char(ses_dir), 'anat', sprintf('sub-%03d_ses-%02d_T1w.nii', sub_no, ses_no));
        analysis_info.anat_vol_curr = analysis_info.anat_vol_orig;
        
        % Create fmap filenames
        phasediff_file = fullfile(char(ses_dir), 'fmap', sprintf('sub-%03d_ses-%02d_phasediff.nii', sub_no, ses_no));
        mag1_file = fullfile(char(ses_dir), 'fmap', sprintf('sub-%03d_ses-%02d_magnitude1.nii', sub_no, ses_no));
        
        % Add fmap data only if files exist
        if exist(phasediff_file, 'file') && exist(mag1_file, 'file')
            analysis_info.phasediff = phasediff_file;
            analysis_info.mag1 = mag1_file;
        end
    
        % Add jsons
        analysis_info.func_json =  fullfile(char(ses_dir), 'func',...
            sprintf('sub-%03d_ses-%02d_task-%s_run-%d_bold.json', sub_no, ses_no, task_name, run_no));
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

        % Save analysis info
        analyses_info{i} = analysis_info;

    end

    % Run connecivity analysis
    analyses_info = connectivity(analyses_info);

    % Tell user the analysis is complete.
    my_log("========================================================================")
    my_log('PROMES Analysis Complete!')
    my_log("------------------------------------------------------------------------")
    my_log("Analysis results can be found in the following locations:")
    my_log(" ")
    my_log("   Cleaned Anatomical: ")
    my_log(['   ', analyses_info{1}.anat_vol_curr])
    my_log(" ")
    if analyses_info{1}.run_rest
        for i = 1:n_analyses
            my_log("   Cleaned rest for subject " + string(analyses_info{i}.sub_no) + ...
             ", session " + string(analyses_info{i}.ses_no) + ...
             ", run " + string(analyses_info{i}.run_no) + ...
             ", for the " + string(analyses_info{i}.task_name) + " task:")
            my_log("   " + string(analyses_info{i}.func_vol_curr_rest))
            my_log(" ")
        end
        my_log("   Concatenated Rest: ")
        my_log("   " + string(analyses_info{1}.concat_file))
        my_log(" ")
        my_log("   Connectivity (IFG L Seed): ")
        my_log("   " + string(analyses_info{1}.connectivity.IFG.L))
        my_log(" ")
        my_log("   Connectivity (IFG R Seed): ")
        my_log("   " + string(analyses_info{1}.connectivity.IFG.R))
        my_log(" ")
        my_log("   Connectivity (pSTG L Seed): ")
        my_log("   " + string(analyses_info{1}.connectivity.pSTG.L))
        my_log(" ")
        my_log("   Connectivity (pSTG R Seed): ")
        my_log("   " + string(analyses_info{1}.connectivity.pSTG.R))
        my_log("------------------------------------------------------------------------")
        my_log("   Final rest LI scores have been appended to:")
        my_log("   " + string(fullfile(analyses_info{1}.data_dir, 'LI_results_rs.csv')))
    end
    if analyses_info{1}.run_task
        for i = 1:n_analyses
            my_log("   Contrast Image for subject " + string(analyses_info{i}.sub_no) + ...
             ", session " + string(analyses_info{i}.ses_no) + ...
             ", run " + string(analyses_info{i}.run_no) + ...
             ", for the " + string(analyses_info{i}.task_name) + " task:")
            my_log("   " + string(analyses_info{i}.contrast))
            my_log(" ")
            my_log("   T-Statistic Image for subject " + string(analyses_info{i}.sub_no) + ...
             ", session " + string(analyses_info{i}.ses_no) + ...
             ", run " + string(analyses_info{i}.run_no) + ...
             ", for the " + string(analyses_info{i}.task_name) + " task:")
            my_log("   " + string(analyses_info{i}.contrast))
        end
        my_log("------------------------------------------------------------------------")
        my_log("   Final task LI scores have been appended to:")
        my_log("   " + string(fullfile(analyses_info{1}.data_dir, 'LI_results_tb.csv')))
    end
    my_log("========================================================================")
   

end