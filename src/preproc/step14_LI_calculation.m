function analyses_info = step14_LI_calculation(analyses_info)


    % Notes for install: 
    %  - Must download from here https://www.medizin.uni-tuebingen.de/de/das-klinikum/einrichtungen/kliniken/kinderklinik/forschung/forschung-iii/software/formular-li#
    %    (Note: may have to translate from german)
    %  - Must unzip folder and copy LI into SPM toolbox folder (this is
    %  fullfile(spm('Dir'), 'toolbox') on your machine
    %  - Must run LI_test

    % Subject number
    sub_no = analyses_info{1}.sub_no;

    % Get the number of analyses
    n_analyses = numel(analyses_info{1});

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
    
    % Create matlab batch for LI computation
    matlabbatch{1}.spm.tools.LI_cfg.spmT = {
        [analyses_info{1}.connectivity.IFG.L, ',1']
        [analyses_info{1}.connectivity.IFG.R, ',1']
        [analyses_info{1}.connectivity.pSTG.L, ',1']
        [analyses_info{1}.connectivity.pSTG.R, ',1']
    };
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

    % Store outputs
    for i = 1:n_analyses

        % Save results
        analyses_info{i}.LI_score.IFG.L = LI_scores(1);
        analyses_info{i}.LI_score.IFG.R = LI_scores(2);
        analyses_info{i}.LI_score.pSTG.L = LI_scores(3);
        analyses_info{i}.LI_score.pSTG.R = LI_scores(4);

    end

    % Save results
    out_file = fullfile(analyses_info{1}.data_dir, 'LI_results.csv');
    
    % If the file doesn't exist, create it with headers
    if ~exist(out_file, 'file')
        fid = fopen(out_file, 'w');
        fprintf(fid, 'subject_number,LI_IFG_L,LI_IFG_R,LI_pSTG_L,LI_pSTG_R\n');
        fclose(fid);
    end
    
    % Append new row
    fid = fopen(out_file, 'a');
    fprintf(fid, 'sub-%03d,%.4f,%.4f,%.4f,%.4f\n', ...
        sub_no, LI_scores(1), LI_scores(2), LI_scores(3), LI_scores(4));
    fclose(fid);
    
end