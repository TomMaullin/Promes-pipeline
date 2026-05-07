function compute_masked_task_LIs(data_dir, sub_nos, ses_nos, run_nos, task_names)

    % Check LI toolbox folder inside SPM
    li_dir = fullfile(fileparts(which('spm')), 'toolbox', 'LI');
    if ~exist(li_dir, 'dir')
        error('LI toolbox not found in SPM toolbox directory.');
    end

    % Results file lives one level above subject folders, i.e. BIDS dir
    out_file_tb = fullfile(data_dir, 'LI_results_tb_masked.csv'); 

    if ~exist(out_file_tb, 'file')
        fid = fopen(out_file_tb, 'w');
        fprintf(fid, 'subject_number,session_number,task_name,run_number,LI\n');
        fclose(fid);
    end


    for s = 1:numel(sub_nos)

        % Get subject no, session no, run no, task name
        sub_no = sub_nos(s);
        ses_no = ses_nos(s);
        run_no = run_nos(s);
        task_name = task_names(s);

        % Get session directory
        sub_dir = fullfile(data_dir, sprintf('sub-%03d', sub_no));
        ses_dir = fullfile(data_dir, sprintf('sub-%03d', sub_no), sprintf('ses-%02d', ses_no));
        fname = sprintf('sub-%03d_ses-%02d_task-%s_run-%d_con_0001.nii', sub_no, ses_no, task_name, run_no);


        % Input files
        contrast_file = fullfile(ses_dir, 'func', fname);

        % Update log
        my_log(sprintf('Processing sub-%03d | ses-%02d | task-%s | run-%d...', sub_no, ses_no, task_name, run_no));

        % LI output setup
        li_file = fullfile(sub_dir, 'LI_output.txt');

        if exist(li_file, 'file')
            delete(li_file);
        end

        % Files to compute for
        spmT_list = {
            [contrast_file, ',1']
        };

        % Get mask directory
        script_dir = fileparts(mfilename('fullpath'));
        mask_file = fullfile(script_dir, 'language_mask.nii');
        mask_string = [mask_file ',1'];

        % Create MATLAB batch for LI computation
        matlabbatch = [];

        matlabbatch{1}.spm.tools.LI_cfg.spmT = spmT_list;
        matlabbatch{1}.spm.tools.LI_cfg.inmask.im11 = {mask_string};
        matlabbatch{1}.spm.tools.LI_cfg.exmask.em1 = 1;
        matlabbatch{1}.spm.tools.LI_cfg.method.thr7 = 1;
        matlabbatch{1}.spm.tools.LI_cfg.pre = 0;
        matlabbatch{1}.spm.tools.LI_cfg.op = 4;
        matlabbatch{1}.spm.tools.LI_cfg.vc = 0;
        matlabbatch{1}.spm.tools.LI_cfg.ni = 1;
        matlabbatch{1}.spm.tools.LI_cfg.outfile = 'LI_output.txt';

        % Run LI computation
        old_dir = pwd;
        cd(sub_dir);

        my_log('Running LI computation...');
        spm_jobman('run', matlabbatch);

        cd(old_dir);

        % Read LI output
        opts = detectImportOptions(li_file, ...
            'FileType', 'text', ...
            'Delimiter', '\t');

        opts.VariableNamingRule = 'preserve';

        LI = readtable(li_file, opts);
        my_log(LI);

        LI_scores = LI.('LI (overall)');

        % Append result

        fid = fopen(out_file_tb, 'a');
        % Save LI
        fprintf(fid, 'sub-%03d,ses-%02d,%s,run-%02d,%.4f\n', ...
            sub_no, ses_no, task_name, run_no, LI_scores(1));
        fclose(fid);

        % Delete redundant LI files

        cleanup_files = {
            fullfile(sub_dir, 'LI_boot.ps')
            fullfile(sub_dir, 'LI_output.txt')
            fullfile(sub_dir, 'LI_masking.ps')
        };

        for i = 1:numel(cleanup_files)
            if exist(cleanup_files{i}, 'file')
                delete(cleanup_files{i});
            end
        end

    end

end