function analyses_info = step15_LI_calculation(analyses_info)


    % Notes for install: 
    %  - Must download from here https://www.medizin.uni-tuebingen.de/de/das-klinikum/einrichtungen/kliniken/kinderklinik/forschung/forschung-iii/software/formular-li#
    %    (Note: may have to translate from german)
    %  - Must unzip folder and copy LI into SPM toolbox folder (this is
    %  fullfile(spm('Dir'), 'toolbox') on your machine
    %  - Must run LI_test

    % Subject number
    sub_no = analyses_info{1}.sub_no;

    % Get the number of analyses
    n_analyses = numel(analyses_info);

    % Check LI toolbox folder inside SPM
    li_dir = fullfile(fileparts(which('spm')), 'toolbox', 'LI');

    if ~exist(li_dir, 'dir')
        error('LI toolbox not found in SPM toolbox directory.');
    end

    % Path to LI output text file
    li_file = fullfile(analyses_info{1}.sub_dir, 'LI_output.txt');

    % If the file exists already remove it
    if exist(li_file, 'file')
        delete(li_file);
    end

    % % Check a key LI function is accessible
    % if isempty(which('spm_li'))
    %     error('LI toolbox is not on the MATLAB path.');
    % end
    

    % List of files for LI toolbox
    if analyses_info{1}.run_rest

        spmT_list = {
            [analyses_info{1}.connectivity.IFG.L, ',1']
            [analyses_info{1}.connectivity.IFG.R, ',1']
            [analyses_info{1}.connectivity.pSTG.L, ',1']
            [analyses_info{1}.connectivity.pSTG.R, ',1']
        };

    else
        spmT_list = {};
    end

    % Add task volumes
    if analyses_info{1}.run_task

        for i = 1:n_analyses
            spmT_list{end+1,1} = [char(analyses_info{i}.contrastT), ',1'];
        end

    end

    % Create matlab batch for LI computation
    matlabbatch{1}.spm.tools.LI_cfg.spmT = spmT_list;
    matlabbatch{1}.spm.tools.LI_cfg.inmask.im10 = 1;
    matlabbatch{1}.spm.tools.LI_cfg.exmask.em1 = 1;
    matlabbatch{1}.spm.tools.LI_cfg.method.thr7 = 1;
    matlabbatch{1}.spm.tools.LI_cfg.pre = 0;
    matlabbatch{1}.spm.tools.LI_cfg.op = 4;
    matlabbatch{1}.spm.tools.LI_cfg.vc = 0;
    matlabbatch{1}.spm.tools.LI_cfg.ni = 1;
    
    % We need to change directory because LI toolbox doesn't handle full
    % paths well
    old_dir = pwd;
    cd(analyses_info{1}.sub_dir)
    
    % Add relevant path
    matlabbatch{1}.spm.tools.LI_cfg.outfile = 'LI_output.txt';
    
    % Run in SPM jobman
    my_log('Running LI computation...')
    spm_jobman('run', matlabbatch);
    
    % Change back
    cd(old_dir)
    
    % Read tab-delimited text file
    opts = detectImportOptions(li_file, ...
        'FileType', 'text', ...
        'Delimiter', '\t');
    
    % Preserve original column names as much as possible
    opts.VariableNamingRule = 'preserve';
    
    % Read file
    LI = readtable(li_file, opts);
    
    % Display result
    my_log(LI)
    
    % Save LI scores
    LI_scores = LI.("LI (overall)");


    % Save rest results if we have them
    if analyses_info{1}.run_rest

        % Save results
        out_file_rs = fullfile(analyses_info{1}.data_dir, 'LI_results_rs.csv');

        % If the file doesn't exist, create it with headers
        if ~exist(out_file_rs, 'file')
            fid = fopen(out_file_rs, 'w');
            fprintf(fid, 'subject_number,LI_IFG_L,LI_IFG_R,LI_pSTG_L,LI_pSTG_R\n');
            fclose(fid);
        end

        % Store outputs
        for i = 1:n_analyses
    
            % Save results
            analyses_info{i}.LI_score.IFG.L = LI_scores(1);
            analyses_info{i}.LI_score.IFG.R = LI_scores(2);
            analyses_info{i}.LI_score.pSTG.L = LI_scores(3);
            analyses_info{i}.LI_score.pSTG.R = LI_scores(4);
  
            % Append new row
            fid = fopen(out_file_rs, 'a');
            fprintf(fid, 'sub-%03d,%.4f,%.4f,%.4f,%.4f\n', ...
                sub_no, LI_scores(1), LI_scores(2), LI_scores(3), LI_scores(4));
            fclose(fid);

        end
    

    end

    % Save task
    if analyses_info{1}.run_task

        % Check if we ran rest
        if analyses_info{1}.run_rest
            offset = 4;
        else
            offset = 0;
        end

        out_file_tb = fullfile(analyses_info{1}.data_dir, 'LI_results_tb.csv');
        % If the file doesn't exist, create it with headers
        if ~exist(out_file_tb, 'file')
            fid = fopen(out_file_tb, 'w');
            fprintf(fid, 'subject_number,session_number,task_name,run_number,LI\n');
            fclose(fid);
        end
    
        % Open file
        fid = fopen(out_file_tb, 'a');
        
        % write to file
        for i = 1:n_analyses
            
            % Get details
            sub_no = analyses_info{i}.sub_no;
            ses_no = analyses_info{i}.ses_no;
            task_name = analyses_info{i}.task_name;
            run_no = analyses_info{i}.run_no;
    
            % Save in struct
            analyses_info{i}.LI_task = LI_scores(i+offset);
    
            % Save LI
            fprintf(fid, 'sub-%03d,ses-%02d,%s,run-%02d,%.4f\n', ...
                sub_no, ses_no, task_name, run_no, LI_scores(i+offset));
    
        end
        
        % close file
        fclose(fid);

    end

end