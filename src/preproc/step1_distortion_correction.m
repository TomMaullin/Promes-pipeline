
function analysis_info = step1_distortion_correction(analysis_info)

    % Load in details
    ses_dir = analysis_info.ses_dir;
    sub_no = analysis_info.sub_no;
    ses_no = analysis_info.ses_no;
    task_name = analysis_info.task_name;
    run_no = analysis_info.run_no;

    % Check if phasediff is present in analysis info
    if isfield(analysis_info, 'phasediff') && exist(analysis_info.phasediff, 'file')
        
        % Get json data for func and phase
        func_json = analysis_info.func_json;
        phas_json =  analysis_info.phas_json;
        
        % Read in json files
        func_txt = fileread(func_json);
        phas_txt = fileread(phas_json);
    
        % Convert to text
        func_data = jsondecode(func_txt);
        phas_data = jsondecode(phas_txt);
    
        % Get echo times
        et1 = phas_data.EchoTime1;
        et2 = phas_data.EchoTime2;
        
        % Convert if needed
        if ischar(et1) || isstring(et1)
            et1 = str2double(et1);
        end
        
        if ischar(et2) || isstring(et2)
            et2 = str2double(et2);
        end
    
        % Specify matlabbatch
        clear matlabbatch
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.phase = {char(analysis_info.phasediff + ",1")};    
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.magnitude = {char(analysis_info.mag1 + ",1")};    
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.et = [et1*1000 et2*1000];
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.maskbrain = 0;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.blipdir = 1 - 2*contains(func_data.PhaseEncodingDirection, '-');
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.tert = func_data.TotalReadoutTime*1000;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.epifm = 0;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.ajm = 0;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.method = 'Mark3D';
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.fwhm = 10;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.pad = 0;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.ws = 1;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.template = {fullfile(spm('Dir'), 'toolbox', 'FieldMap', 'T1.nii')};
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.fwhm = 5;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.nerode = 2;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.ndilate = 4;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.thresh = 0.5;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.reg = 0.02;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session.epi = {char(analysis_info.func_vol_curr + ",1")};
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = 1;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.sessname = 'session';
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = 1;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.anat = {char(analysis_info.anat_vol_curr + ",1")};
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 1;
    
    
        % Run in SPM jobman
        my_log('Running distortion correction...')
        spm_jobman('run', matlabbatch);
    
        % Update analysis info
        analysis_info.vdm5 = fullfile(ses_dir, 'fmap', sprintf('vdm5_scsub-%03d_ses-%02d_phasediff.nii', sub_no, ses_no));

    else 

        % Log result
        my_log("No fieldmap found. Distortion correction skipped for " + task_name + " for subject " + num2str(sub_no) + " session " + num2str(ses_no));

    end

end


