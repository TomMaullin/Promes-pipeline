function analysis_info = step7_smooth(analysis_info)
    
    % Get subject, session numbers and session dir
    sub_no = analysis_info.sub_no;
    ses_no = analysis_info.ses_no;
    ses_dir = analysis_info.ses_dir;

    func_dir = fullfile(char(ses_dir), 'func');

    % Files
    wu_func_file = analysis_info.func_vol_curr;

    % wc files
    wc1_file = analysis_info.c1_file_curr;
    wc2_file = analysis_info.c2_file_curr;
    wc3_file = analysis_info.c3_file_curr;

    % Filename to output masked data to
    masked_file = fullfile(func_dir, ...
        sprintf('mwausub-%03d_ses-%02d_task-AudCat_run-1_bold.nii', sub_no, ses_no));

    % -----------------------------------------------------------------
    % Read data
    % -----------------------------------------------------------------
    Vf = spm_vol(wu_func_file);      % 1xN struct array for 4D BOLD
    Yf = spm_read_vols(Vf);          % X x Y x Z x T

    V1 = spm_vol(wc1_file);
    V2 = spm_vol(wc2_file);
    V3 = spm_vol(wc3_file);

    Y1 = spm_read_vols(V1);          % X x Y x Z
    Y2 = spm_read_vols(V2);
    Y3 = spm_read_vols(V3);

    if ~isequal(size(Yf,1), size(Y1,1)) || ~isequal(size(Yf,2), size(Y1,2)) || ~isequal(size(Yf,3), size(Y1,3))
        error('Functional and tissue map dimensions do not match.');
    end

    % -----------------------------------------------------------------
    % Create brain mask
    % -----------------------------------------------------------------
    mask = (Y1 + Y2 + Y3) > 0.2;     % logical 3D mask

    % Apply to all timepoints at once
    Ymasked = Yf .* mask;

    % -----------------------------------------------------------------
    % Write masked 4D file
    % -----------------------------------------------------------------
    Vo = Vf;  % copy headers from original functional

    for t = 1:numel(Vo)
        Vo(t).fname = masked_file;
        Vo(t).dt    = [spm_type('float32') spm_platform('bigend')];
        Vo(t).pinfo = [1; 0; 0];
        Vo(t).n     = [t 1];
    end

    % Output result
    Vo = spm_create_vol(Vo);

    for t = 1:numel(Vo)
        spm_write_vol(Vo(t), Ymasked(:,:,:,t));
    end

    % Get a cell of masked preprocessed functional bold timeseries volumes
    % to write
    nVols = numel(Vf);
    mwu_func_vols = reshape(arrayfun(@(v) sprintf('%s,%d', masked_file, v), ...
                            1:nVols, 'UniformOutput', false), [], 1);

    % Create matlabbatch for smoothing
    clear matlabbatch
    matlabbatch{1}.spm.spatial.smooth.data = mwu_func_vols;
    matlabbatch{1}.spm.spatial.smooth.fwhm = [8 8 8];
    matlabbatch{1}.spm.spatial.smooth.dtype = 0;
    matlabbatch{1}.spm.spatial.smooth.im = 1;
    matlabbatch{1}.spm.spatial.smooth.prefix = 's';

    % Run in SPM jobman
    my_log('Smoothing...')
    spm_jobman('run', matlabbatch);
    clear matlabbatch

    % Update files
    analysis_info.func_vol_curr = fullfile(char(ses_dir), 'func', sprintf('smwausub-%03d_ses-%02d_task-AudCat_run-1_bold.nii', sub_no, ses_no));

end