function analyses_info = step12_concat(analyses_info)

    % Concatenate analyses_info{i}.func_vol_curr into one 4D NIfTI using SPM
    % Before concatenation, voxelwise demean and standardise each run across
    % time (within-run z-scoring).

    % Tell user
    my_log('Concatenating runs...')

    if isempty(analyses_info)
        error('analyses_info is empty.');
    end

    % Get the number of analyses
    n_analyses = numel(analyses_info);

    % Validate inputs
    for i = 1:n_analyses

        % Check the analysis has a final functional stored
        if ~isfield(analyses_info{i}, 'func_vol_curr')
            error('analyses_info{%d} missing func_vol_curr.', i);
        end

        % Get the final functional stored
        func_file = char(analyses_info{i}.func_vol_curr);

        % Check it exists
        if ~exist(func_file, 'file')
            error('File not found: %s', func_file);
        end
    end

    % Output path (subject dir)
    out_label = sprintf('sub-%03d', analyses_info{1}.sub_no);
    out_dir   = fullfile(char(analyses_info{1}.data_dir), out_label);
    out_file  = char(fullfile(out_dir, ...
                   [out_label '_cleaned_rest_only_bold.nii']));

    % First pass: check geometry + count volumes
    total_vols = 0;
    ref_dim = [];
    ref_mat = [];

    % Loop through analyses
    for i = 1:n_analyses

        % Load volumes
        V = spm_vol(char(analyses_info{i}.func_vol_curr));

        % Save one as a reference
        if isempty(ref_dim)

            % Save dimensions and transform
            ref_dim = V(1).dim;
            ref_mat = V(1).mat;

        else

            % Check if dimensions equal reference dimensions
            if ~isequal(V(1).dim, ref_dim)
                error('Dimension mismatch in entry %d.', i);
            end

            % Check if transform is reasonable
            if max(abs(V(1).mat(:) - ref_mat(:))) > 1e-6
                error('Affine mismatch in entry %d.', i);
            end
        end

        % Record total number of vols
        total_vols = total_vols + numel(V);

    end

    % Remove existing file if present
    if exist(out_file, 'file')
        delete(out_file);
    end

    % Second pass: concatenate with voxelwise demean + standardise per run
    out_idx = 1;
    eps_val = 1e-6;   % numerical stability threshold for near-zero std

    % Loop through analyses
    for i = 1:n_analyses

        % Load volume headers for this run
        Vin = spm_vol(char(analyses_info{i}.func_vol_curr));
        n_vols = numel(Vin);

        % Read entire run into memory as 4D array: [X Y Z T]
        data_4d = zeros([Vin(1).dim n_vols], 'double');
        for j = 1:n_vols
            data_4d(:,:,:,j) = spm_read_vols(Vin(j));
        end

        % Compute voxelwise mean and std across time (within run)
        mean_vol = mean(data_4d, 4);
        std_vol  = std(data_4d, 0, 4);

        % Clamp very small std values to avoid numerical issues
        std_vol(std_vol < eps_val) = 1;

        % Write standardised volumes into concatenated output
        for j = 1:n_vols

            % Voxelwise z-score for this volume
            func_curr = (data_4d(:,:,:,j) - mean_vol) ./ std_vol;

            % Save metadata for volume
            Vout       = Vin(j);
            Vout.fname = out_file;
            Vout.n     = [out_idx 1];

            % Reset scaling after z-scoring
            Vout.pinfo = [1; 0; 0];

            % Remove problematic field for writing
            if isfield(Vout, 'private')
                Vout = rmfield(Vout, 'private');
            end

            % Write volume to concatenated file
            spm_write_vol(Vout, func_curr);

            % Update index
            out_idx = out_idx + 1;

        end

    end

    % Store output path
    for i = 1:n_analyses
        analyses_info{i}.concat_file = out_file;
    end

end