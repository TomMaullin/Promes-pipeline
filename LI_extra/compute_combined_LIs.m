function compute_combined_LIs(bids_dir, sub_nos)

    % Check LI toolbox folder inside SPM
    li_dir = fullfile(fileparts(which('spm')), 'toolbox', 'LI');
    if ~exist(li_dir, 'dir')
        error('LI toolbox not found in SPM toolbox directory.');
    end

    % Results file lives one level above subject folders, i.e. BIDS dir
    out_file_rs = fullfile(bids_dir, 'LI_results_rs_combined.csv');

    if ~exist(out_file_rs, 'file')
        fid = fopen(out_file_rs, 'w');
        fprintf(fid, 'subject_number,LI\n');
        fclose(fid);
    end

    for s = 1:numel(sub_nos)

        sub_no = sub_nos(s);

        % Format subject folder
        sub_str = sprintf('sub-%03d', sub_no);
        sub_dir = fullfile(bids_dir, sub_str);

        % Input files
        IFG_L_file  = fullfile(sub_dir, 'conn_rs_IFG_L.nii');
        IFG_R_file  = fullfile(sub_dir, 'conn_rs_IFG_R.nii');
        pSTG_L_file = fullfile(sub_dir, 'conn_rs_pSTG_L.nii');
        pSTG_R_file = fullfile(sub_dir, 'conn_rs_pSTG_R.nii');

        my_log(['Processing ' sub_str '...']);

        %% Mask hemispheres

        IFG_L_masked = mask_hemisphere(IFG_L_file, 'right', false);
        IFG_R_masked = mask_hemisphere(IFG_R_file, 'left', false);
        IFG_combined = IFG_L_masked + IFG_R_masked;

        pSTG_L_masked = mask_hemisphere(pSTG_L_file, 'right', false);
        pSTG_R_masked = mask_hemisphere(pSTG_R_file, 'left', false);
        pSTG_combined = pSTG_L_masked + pSTG_R_masked;

        %% Combine IFG + pSTG into one image

        combined_all = IFG_combined + pSTG_combined;

        V_out = spm_vol(IFG_L_file);
        V_out.fname = char(fullfile(sub_dir, 'conn_rs_combined.nii'));
        V_out.descrip = 'Combined IFG + pSTG (L/R masked) connectivity map';

        spm_write_vol(V_out, combined_all);

        %% LI output setup

        li_file = fullfile(sub_dir, 'LI_output.txt');

        if exist(li_file, 'file')
            delete(li_file);
        end

        spmT_list = {
            'conn_rs_combined.nii,1'
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

        %% Append result

        fid = fopen(out_file_rs, 'a');
        fprintf(fid, 'sub-%03d,%.4f\n', sub_no, LI_scores(1));
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

end