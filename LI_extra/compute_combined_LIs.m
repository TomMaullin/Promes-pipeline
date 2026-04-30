function compute_combined_LIs(bids_dir, sub_no)

    % Format subject folder (zero-padded)
    sub_str = sprintf('sub-%03d', sub_no);
    
    % Subject directory
    sub_dir = fullfile(bids_dir, sub_str);
    
    % IFG files
    IFG_L_file = fullfile(sub_dir, 'conn_rs_IFG_L.nii');
    IFG_R_file = fullfile(sub_dir, 'conn_rs_IFG_R.nii');
    
    % pSTG files
    pSTG_L_file = fullfile(sub_dir, 'conn_rs_pSTG_L.nii');
    pSTG_R_file = fullfile(sub_dir, 'conn_rs_pSTG_R.nii');

    % IFG: mask, combine, save
    IFG_L_masked = mask_hemisphere(IFG_L_file, 'right', false);
    IFG_R_masked = mask_hemisphere(IFG_R_file, 'left', false);

    IFG_combined = IFG_L_masked + IFG_R_masked;

    V_IFG = spm_vol(IFG_L_file);
    V_IFG.fname = char(fullfile(fileparts(IFG_L_file), 'conn_rs_IFG_combined.nii'));
    V_IFG.descrip = 'Combined IFG L/R masked connectivity map';

    spm_write_vol(V_IFG, IFG_combined);


    % pSTG: mask, combine, save
    pSTG_L_masked = mask_hemisphere(pSTG_L_file, 'right', false);
    pSTG_R_masked = mask_hemisphere(pSTG_R_file, 'left', false);

    pSTG_combined = pSTG_L_masked + pSTG_R_masked;

    V_pSTG = spm_vol(pSTG_L_file);
    V_pSTG.fname = char(fullfile(fileparts(pSTG_L_file), 'conn_rs_pSTG_combined.nii'));
    V_pSTG.descrip = 'Combined pSTG L/R masked connectivity map';

    spm_write_vol(V_pSTG, pSTG_combined);


    % Extract subject number
    tokens = regexp(pSTG_R_file, 'sub-(\d+)', 'tokens');

    if isempty(tokens)
        error('No subject ID found in filename');
    end

    sub_no = str2double(tokens{1}{1});


    %% Check LI toolbox folder inside SPM

    li_dir = fullfile(fileparts(which('spm')), 'toolbox', 'LI');

    if ~exist(li_dir, 'dir')
        error('LI toolbox not found in SPM toolbox directory.');
    end


    %% Define directories

    sub_dir = fileparts(pSTG_R_file);
    data_dir = fileparts(sub_dir);


    %% Path to LI output text file

    li_file = fullfile(sub_dir, 'LI_output.txt');

    if exist(li_file, 'file')
        delete(li_file);
    end


    %% List of files for LI toolbox

    spmT_list = {
        'conn_rs_IFG_combined.nii,1'
        'conn_rs_pSTG_combined.nii,1'
    };


    %% Create MATLAB batch for LI computation

    matlabbatch = [];

    matlabbatch{1}.spm.tools.LI_cfg.spmT = spmT_list;
    matlabbatch{1}.spm.tools.LI_cfg.inmask.im10 = 1;
    matlabbatch{1}.spm.tools.LI_cfg.exmask.em1 = 1;
    matlabbatch{1}.spm.tools.LI_cfg.method.thr7 = 1;
    matlabbatch{1}.spm.tools.LI_cfg.pre = 0;
    matlabbatch{1}.spm.tools.LI_cfg.op = 4;
    matlabbatch{1}.spm.tools.LI_cfg.vc = 0;
    matlabbatch{1}.spm.tools.LI_cfg.ni = 1;
    matlabbatch{1}.spm.tools.LI_cfg.outfile = 'LI_output.txt';


    %% Run LI computation

    old_dir = pwd;
    cd(sub_dir);

    my_log('Running LI computation...');
    spm_jobman('run', matlabbatch);

    cd(old_dir);


    %% Read LI output

    opts = detectImportOptions(li_file, ...
        'FileType', 'text', ...
        'Delimiter', '\t');

    opts.VariableNamingRule = 'preserve';

    LI = readtable(li_file, opts);

    my_log(LI);

    LI_scores = LI.('LI (overall)');


    %% Save results

    out_file_rs = fullfile(data_dir, 'LI_results_rs_combined.csv');

    if ~exist(out_file_rs, 'file')
        fid = fopen(out_file_rs, 'w');
        fprintf(fid, 'subject_number,LI_IFG,LI_pSTG\n');
        fclose(fid);
    end

    fid = fopen(out_file_rs, 'a');
    fprintf(fid, 'sub-%03d,%.4f,%.4f\n', ...
        sub_no, LI_scores(1), LI_scores(2));
    fclose(fid);


    %% Delete redundant LI files

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