    
function analysis_info = step3_slice_timing(analysis_info)

    % Get subject, session numbers and session dir
    sub_no = analysis_info.sub_no;
    ses_no = analysis_info.ses_no;
    ses_dir = analysis_info.ses_dir;
    
    % Get json data for func
    func_json =  analysis_info.func_json;
    
    % Read in json files
    func_txt = fileread(func_json);
    
    % Convert to text
    func_data = jsondecode(func_txt);
    
    % Get slice timing from JSON
    slice_timing = func_data.SliceTiming;
    
    % Make sure it is numeric
    if iscell(slice_timing)
        slice_timing = cellfun(@double, slice_timing);
    end
    
    % Number of slices
    nslices = numel(slice_timing);
    
    % TR (seconds)
    TR = func_data.RepetitionTime;
    
    % TA (seconds)
    TA = TR - (TR / nslices);
    
    % Slice order
    % This gives the order in which slices were acquired
    [~, slice_order] = sort(slice_timing);
    
    % Reference slice (common choice = middle slice in acquisition order)
    refslice = slice_order(round(nslices/2));
    
    % Get the path for the aligned functional data
    func_file = analysis_info.func_vol_curr;
    
    % Read headers using SPM
    V = spm_vol(func_file);
    
    % Number of volumes
    nVols = numel(V);
    
    % Create matlabbatch
    clear matlabbatch
    matlabbatch{1}.spm.temporal.st.scans = {reshape(arrayfun(@(v) sprintf('%s,%d', func_file, v), 1:nVols, 'UniformOutput', false), [], 1)}';
    matlabbatch{1}.spm.temporal.st.nslices = nslices;
    matlabbatch{1}.spm.temporal.st.tr = TR;
    matlabbatch{1}.spm.temporal.st.ta = TA;
    matlabbatch{1}.spm.temporal.st.so = slice_order;
    matlabbatch{1}.spm.temporal.st.refslice = refslice;
    matlabbatch{1}.spm.temporal.st.prefix = 'a';

    % Run in SPM jobman
    my_log('Running slice timing...')
    spm_jobman('run', matlabbatch);

    % Update analysis info
    analysis_info.func_vol_curr = fullfile(char(ses_dir), 'func', sprintf('ausub-%03d_ses-%02d_task-AudCat_run-1_bold.nii', sub_no, ses_no));

end