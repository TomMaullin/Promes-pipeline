function Vmasked = mask_hemisphere(nifti_file, hemisphere, do_save)

    if nargin < 3
        do_save = false;
    end

    nifti_file = char(nifti_file);
    hemisphere = lower(char(hemisphere));

    if ~ismember(hemisphere, {'left', 'right'})
        error('hemisphere must be ''left'' or ''right''.');
    end

    V = spm_vol(nifti_file);
    Y = spm_read_vols(V);

    [i, j, k] = ndgrid(1:V.dim(1), 1:V.dim(2), 1:V.dim(3));
    xyz_vox = [i(:)'; j(:)'; k(:)'; ones(1, numel(i))];
    xyz_mm  = V.mat * xyz_vox;
    x_mm = reshape(xyz_mm(1, :), V.dim);

    Vmasked = Y;

    switch hemisphere
        case 'left'
            Vmasked(x_mm <= 0) = 0;
            postfix = '_left_masked';

        case 'right'
            Vmasked(x_mm >= 0) = 0;
            postfix = '_right_masked';
    end

    if do_save
        [pth, nam, ext] = fileparts(nifti_file);

        if strcmp(ext, '.gz')
            error('Please provide an uncompressed .nii file.');
        end

        outname = fullfile(pth, [nam postfix ext]);
        outname = char(outname);

        Vout = V;
        Vout.fname = outname;
        Vout.descrip = ['Hemisphere masked: ' hemisphere];

        spm_write_vol(Vout, Vmasked);
    end
end