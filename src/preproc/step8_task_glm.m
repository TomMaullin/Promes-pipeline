function analysis_info = step8_task_glm(analysis_info)

    if analysis_info.run_task

        % Load in details
        ses_dir = analysis_info.ses_dir;
        sub_no = analysis_info.sub_no;
        ses_no = analysis_info.ses_no;
        task_name = analysis_info.task_name;
        run_no = analysis_info.run_no;
        
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
        
        % Slice order
        % This gives the order in which slices were acquired
        [~, slice_order] = sort(slice_timing);
        
        % Reference slice (common choice = middle slice in acquisition order)
        refslice = slice_order(round(nslices/2));
    
        % Read the events TSV file
        events = readtable(analysis_info.events, 'FileType', ...
            'text', 'Delimiter', '\t');
    
        % Get number of volumes
        vols = spm_vol(analysis_info.func_vol_curr_task);
        n_vols = numel(vols);
        
        % Extract onset and duration columns
        onsets = events.onset;
        durations = events.duration;
    
        % Create model specification job
        matlabbatch{1}.spm.stats.fmri_spec.dir = {char(fullfile(analysis_info.ses_dir, 'func'))};
        matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
        matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = nslices;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = refslice;
        matlabbatch{1}.spm.stats.fmri_spec.sess.scans = reshape(arrayfun(@(v) [analysis_info.func_vol_curr_rest ',' num2str(v)], ...
                                                                1:n_vols, 'UniformOutput', false), [], 1);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).name = 'Task';
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).onset = onsets;
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = durations;
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).tmod = 0;
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).orth = 1;
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).name = 'Rest';
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).onset = [0, (onsets + durations)']';
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).duration = ([onsets' n_vols*TR]-[0, (onsets + durations)'])';
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).tmod = 0;
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).orth = 1;
        matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {analysis_info.realign_params};
        matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;
        matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
        matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
        matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
        matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
        matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    
        % Run in SPM jobman
        my_log('Setting up GLM...')
        spm_jobman('run', matlabbatch);
        clear matlabbatch;
    
        % Create job to setup stats
        matlabbatch{1}.spm.stats.fmri_est.spmmat(1) = {char(fullfile(analysis_info.ses_dir, 'func', 'SPM.mat'))};
        matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
        matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
    
        % Run in SPM jobman
        my_log('Running GLM...')
        spm_jobman('run', matlabbatch);
        clear matlabbatch;
        
        % Create job to setup contrast
        matlabbatch{1}.spm.stats.con.spmmat(1) = {char(fullfile(ses_dir, 'func', 'SPM.mat'))};
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'language';
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [1 -1 0 0 0 0 0 0 0];
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.delete = 0;
    
        % Run in SPM jobman
        my_log('Computing contrasts...')
        spm_jobman('run', matlabbatch);
        clear matlabbatch;
        
        % Create job to setup results
        matlabbatch{1}.spm.stats.results.spmmat(1) = {char(fullfile(ses_dir, 'func', 'SPM.mat'))};
        matlabbatch{1}.spm.stats.results.conspec.titlestr = '';
        matlabbatch{1}.spm.stats.results.conspec.contrasts = Inf;
        matlabbatch{1}.spm.stats.results.conspec.threshdesc = 'FWE';
        matlabbatch{1}.spm.stats.results.conspec.thresh = 0.05;
        matlabbatch{1}.spm.stats.results.conspec.extent = 0;
        matlabbatch{1}.spm.stats.results.conspec.conjunction = 1;
        matlabbatch{1}.spm.stats.results.conspec.mask.none = 1;
        matlabbatch{1}.spm.stats.results.units = 1;
        matlabbatch{1}.spm.stats.results.export{1}.pdf = true;
        matlabbatch{1}.spm.stats.results.export{2}.png = true;
        matlabbatch{1}.spm.stats.results.export{3}.xls = true;
    
        % Run in SPM jobman
        my_log('Thresholding Results...')
        spm_jobman('run', matlabbatch);
        clear matlabbatch;
    
        % Update analysis info 
        analysis_info.contrast = fullfile(analysis_info.ses_dir, 'func', ...
            sprintf('sub-%03d_ses-%02d_task-%s_run-%d_con_0001.nii', sub_no, ses_no, task_name, run_no));
        analysis_info.contrastT = fullfile(analysis_info.ses_dir, 'func', ...
            sprintf('sub-%03d_ses-%02d_task-%s_run-%d_spmT_0001.nii', sub_no, ses_no, task_name, run_no));
    
        % Move to the designated paths
        movefile(fullfile(analysis_info.ses_dir, 'func','con_0001.nii'), analysis_info.contrast, 'f')
        movefile(fullfile(analysis_info.ses_dir, 'func','spmT_0001.nii'), analysis_info.contrastT, 'f')

    end

end