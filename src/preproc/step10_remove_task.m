function analysis_info = step10_remove_task(analysis_info)

    % Load in details
    ses_dir = analysis_info.ses_dir;
    sub_no = analysis_info.sub_no;
    ses_no = analysis_info.ses_no;
    task_name = analysis_info.task_name;
    run_no = analysis_info.run_no;
    
    % Read in func_file
    func_file =  analysis_info.func_vol_curr;
    V_func = spm_vol(func_file);

    % Number of volumes
    nVols = numel(V_func);

    % Read the events TSV file
    events = readtable(analysis_info.events, 'FileType', ...
        'text', 'Delimiter', '\t');

    % Get json data
    func_json = analysis_info.func_json;
    
    % Read in json files
    func_txt = fileread(func_json);
    
    % Convert to text
    func_data = jsondecode(func_txt);
    
    % TR (seconds)
    TR = func_data.RepetitionTime;
    
    % HRF tail window: 15s default for canonical HRF tail.
    hrf_tail_sec = 15;
    
    % -----------------------------------------
    % Volume timing: each volume spans one TR
    % -----------------------------------------
    % Volume k covers:
    %   [vol_start(k), vol_end(k))
    %
    % Example:
    %   vol 1 = [0, 3)
    %   vol 2 = [3, 6)
    % etc.
    vol_start = (0:nVols-1)' * TR;
    vol_end   = vol_start + TR;
    
    % Logical masks
    is_task_vol      = false(nVols,1);
    is_hrf_tail_vol  = false(nVols,1);
    
    % Read task rows
    task_rows = strcmp(string(events.trial_type), "stim_on");
    
    task_onsets    = events.onset(task_rows);
    task_durations = events.duration(task_rows);
    task_offsets   = task_onsets + task_durations;
    
    % -------------------------------------------------------
    % Mark volumes overlapping task itself, and HRF tail only
    % -------------------------------------------------------
    for i = 1:numel(task_onsets)
        task_interval_start = task_onsets(i);
        task_interval_end   = task_offsets(i);
    
        % Any overlap between volume interval and task interval:
        % [vol_start, vol_end) overlaps [task_start, task_end) if
        % vol_start < task_end AND vol_end > task_start
        overlaps_task = (vol_start < task_interval_end) & (vol_end > task_interval_start);
        is_task_vol = is_task_vol | overlaps_task;
    
        % HRF tail interval after task offset
        hrf_interval_start = task_interval_end;
        hrf_interval_end   = task_interval_end + hrf_tail_sec;
    
        overlaps_hrf_tail = (vol_start < hrf_interval_end) & (vol_end > hrf_interval_start);
        is_hrf_tail_vol = is_hrf_tail_vol | overlaps_hrf_tail;
    end
    
    % Remove task volumes from the "tail-only" mask so categories are distinct
    is_hrf_tail_vol = is_hrf_tail_vol & ~is_task_vol;
    
    % Volumes that can reasonably be treated as rest
    is_rest_vol = ~(is_task_vol | is_hrf_tail_vol);
    
    % Indices
    % task_vol_idx     = find(is_task_vol);
    % hrf_tail_vol_idx = find(is_hrf_tail_vol);
    rest_vol_idx     = find(is_rest_vol);
    
    % Save rest volumes    
    my_log('Removing task volumes...')
    V_rest = V_func(rest_vol_idx);
    out_file = fullfile(char(ses_dir), 'func', ...
        sprintf('sub-%03d_ses-%02d_task-%s_run-%d_cleaned_rest_only_bold.nii', ...
        sub_no, ses_no, task_name, run_no));

    % Merge selected volumes into new 4D NIfTI
    spm_file_merge(V_rest, out_file);

    % Update files
    analysis_info.func_vol_curr = out_file;

end