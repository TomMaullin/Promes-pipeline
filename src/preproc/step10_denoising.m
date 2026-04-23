function analysis_info = step11_denoising(analysis_info)

    % ---------------------------------------------------------------------
    % This function performs quite a few steps in one. It does this by
    % using SPM CONN to perform a regression explicitly containing the 
    % following:
    %
    % 1 - Task condition (this includes the on off stimuli for the task)
    % 2 - Rest condition 
    % 3 - Realignment parameters (+ derivatives) from step 2 of the
    %     pipeline
    % 4 - Outliers from step 8 (ART)
    % 5 - WM nuiscance covariates
    % 6 - CSF nuiscance covariates
    %
    % It also implicitly includes in the regression:
    % 
    % 7 - Detrending (long term drift regressors)
    % 8 - Band pass filter (Fourier basis).
    %
    % Voxelwise despiking is also performed at this stage.
    %
    % ---------------------------------------------------------------------

    % Directories
    conn_dir = char(fileparts(which('conn')));

    % Load in details
    ses_dir = analysis_info.ses_dir;
    sub_no = analysis_info.sub_no;
    ses_no = analysis_info.ses_no;
    task_name = analysis_info.task_name;
    run_no = analysis_info.run_no;
    
    % Get json and nii data for functional
    func_json =  analysis_info.func_json;
    func_file =  analysis_info.func_vol_curr_rest;
    
    % Get nii for structural
    struct_file = analysis_info.anat_vol_curr;

    % Read in json files
    func_txt = fileread(func_json);
    
    % Convert to text
    func_data = jsondecode(func_txt);
    
    % TR (seconds)
    TR = func_data.RepetitionTime;
    
    % Read headers using SPM
    V_func = spm_vol(func_file);
    V_struct = spm_vol(struct_file);
    
    % Number of volumes
    nVols = numel(V_func);

    % Create CONN_x struct
    CONN_x = {};
    CONN_x.name = [];
    CONN_x.gui = 1;
    CONN_x.state = 0;
    CONN_x.ver = '22.v2407';
    CONN_x.lastver = '22.v2407';
    CONN_x.isready = [1 0 0 0];
    CONN_x.ispending = 0;
    CONN_x.opt = struct('fmt1', '%03d');

    % pobj struct
    pobj = {};
    pobj.isextended = 0;
    pobj.id = '';
    pobj.holdsdata = 1;
    pobj.readonly = 0;
    pobj.importedfiles = {};
    pobj.cache = '';
    CONN_x.pobj = pobj;

    % Folders struct
    folders = {};
    folders.rois = fullfile(conn_dir,'rois');
    folders.data = fullfile(ses_dir,'conn_workspace','data');
    folders.bids = fullfile(ses_dir,'conn_workspace','data','BIDS');
    folders.preprocessing = fullfile(ses_dir,'conn_workspace','results','preprocessing');
    folders.qa = fullfile(ses_dir,'conn_workspace','results','qa');
    folders.firstlevel = fullfile(ses_dir,'conn_workspace','results','firstlevel');
    folders.firstlevel_vv = fullfile(ses_dir,'conn_workspace','results','firstlevel');
    folders.firstlevel_dyn = fullfile(ses_dir,'conn_workspace','results','firstlevel');
    folders.secondlevel = fullfile(ses_dir,'conn_workspace','results','secondlevel');
    folders.methods = fullfile(ses_dir,'conn_workspace','results','methods');
    folders.bookmarks = fullfile(ses_dir,'conn_workspace','results','bookmarks');
    CONN_x.folders = folders;

    % Setup
    Setup = {};
    Setup.RT = TR;
    Setup.nsubjects = 1;
    Setup.nsessions = 1;
    Setup.reorient = eye(4);
    Setup.normalized = 1;

    % Functional data
    Setup.functional{1}{1}{1} = func_file;
    % Setup.functional{1}{1}{2} =... MARKER pass for now
    Setup.functional{1}{1}{3}(1) = V_func(1);
    Setup.functional{1}{1}{3}(2) = V_func(nVols);
    Setup.functional{1}{1}{3}(1).private = [];
    Setup.functional{1}{1}{3}(2).private = [];
    
    % Functional data
    Setup.structural{1}{1}{1} = struct_file;
    % Setup.structural{1}{1}{2} =... MARKER pass for now
    Setup.structural{1}{1}{3} = V_struct(1);
    Setup.structural{1}{1}{3}.private = [];

    % Simple inputs
    Setup.structural_sessionspecific = 0;
    Setup.spm{1}{1} = [];
    Setup.spm{1}{2} = [];
    Setup.spm{1}{3} = [];
    Setup.dicom{1}{1} = [];
    Setup.dicom{1}{2} = [];
    Setup.dicom{1}{3} = [];
    Setup.bids = {[]  []  []};
    Setup.nscans{1}{1} = nVols;

    % Save ROIs
    Setup.rois.names = {'Grey Matter'  'White Matter'  'CSF'  'networks'  'atlas'  ' '};
    
    
    % GM ROI
    gm_fname = analysis_info.c1_file_curr;
    gm_vol = spm_vol(gm_fname);
    gm_vol.private = [];
    Setup.rois.files{1}{1}{1}{1} = gm_fname;
    %Setup.rois.files{1}{1}{1}{2} = skipping for now...
    Setup.rois.files{1}{1}{1}{3} = gm_vol;
    
    % WM ROI
    wm_fname = analysis_info.c2_file_curr;
    wm_vol = spm_vol(wm_fname);
    wm_vol.private = [];
    Setup.rois.files{1}{2}{1}{1} = wm_fname;
    %Setup.rois.files{1}{2}{1}{2} = skipping for now...
    Setup.rois.files{1}{2}{1}{3} = wm_vol;

    % CSF ROI
    csf_fname = analysis_info.c3_file_curr;
    csf_vol = spm_vol(csf_fname);
    csf_vol.private = [];
    Setup.rois.files{1}{3}{1}{1} = csf_fname;
    %Setup.rois.files{1}{3}{1}{2} = skipping for now...
    Setup.rois.files{1}{3}{1}{3} = csf_vol;

    % Remaining rois
    Setup.rois.files{1}{4}{1}{1} = fullfile(conn_dir,'rois','networks.nii');
    Setup.rois.files{1}{5}{1}{1} = fullfile(conn_dir,'rois','atlas.nii');
    % Setup.rois.files{1}{4}{1}{2} = Skipped... same as with the functional ones
    
    % Load in networks and atlas nii
    nw = spm_vol(fullfile(conn_dir,'rois','networks.nii'));
    at = spm_vol(fullfile(conn_dir,'rois','atlas.nii'));

    % Get nvols
    nVols_nw = numel(nw);
    nVols_at = numel(at);

    % Continue with setup
    Setup.rois.files{1}{4}{1}{3}(1) = nw(1);
    Setup.rois.files{1}{4}{1}{3}(2) = nw(nVols_nw);
    Setup.rois.files{1}{4}{1}{3}(1).private = [];
    Setup.rois.files{1}{4}{1}{3}(2).private = [];
    Setup.rois.files{1}{5}{1}{3}(1) = at(1);
    Setup.rois.files{1}{5}{1}{3}(2) = at(nVols_at);
    Setup.rois.files{1}{5}{1}{3}(1).private = [];
    Setup.rois.files{1}{5}{1}{3}(2).private = [];
    Setup.rois.dimensions = {1 16 16 1 1};
    Setup.rois.mask = [0 0 0 0 0];
    Setup.rois.subjectspecific = [1 1 1 0 0];
    Setup.rois.sessionspecific = [0 0 0 0 0];
    Setup.rois.multiplelabels = [0 0 0 1 1];
    Setup.rois.regresscovariates = [0 1 1 0 0];
    Setup.rois.unsmoothedvolumes = [1 1 1 1 1];
    Setup.rois.weighted = [0 0 0 0 0];

    % Conditions
    Setup.conditions.names = {'rest',  'stim_on',  ' '};
    Setup.conditions.model = {[], []};
    Setup.conditions.values{1}{1}{1} = {[0], [Inf]};

    % Read the events TSV file
    events = readtable(analysis_info.events, 'FileType', ...
        'text', 'Delimiter', '\t');
    
    % Extract onset and duration columns
    onsets = events.onset';
    durations = events.duration';

    % Read in condition
    Setup.conditions.values{1}{2}{1} = {onsets, durations};
    Setup.conditions.param = [0 0];
    Setup.conditions.filter = {[]  []};
    Setup.conditions.allnames = {};
    Setup.conditions.missingdata = 0;

    % 1st level covariates
    Setup.l1covariates.names = {'scrubbing'  'realignment'  ' '};
    Setup.l1covariates.files{1}{1}{1}{1} = analysis_info.art_outliers;
    %Setup.l1covariates.files{1}{1}{1}{1} =  skipped...
    Setup.l1covariates.files{1}{1}{1}{3} = [];
    Setup.l1covariates.files{1}{2}{1}{1} = analysis_info.realign_params;
    %Setup.l1covariates.files{1}{1}{1}{1} =  skipped...
    Setup.l1covariates.files{1}{2}{1}{3} = [];

    % 2nd level covariates (default: might remove)
    Setup.l2covariates.names = {'AllSubjects', 'QC_ValidScans', 'QC_InvalidScans', ...
        'QC_ProportionValidScans', 'QC_MaxMotion', 'QC_MeanMotion', 'QC_MaxGSchange', ... 
        'QC_MeanGSchange', 'QC_GreyMatter_vol', 'QC_GreyMatter_eroded_vol',... 
        'QC_WhiteMatter_vol', 'QC_WhiteMatter_eroded_vol', 'QC_CSF_vol',...
        'QC_CSF_eroded_vol', ' '};
    Setup.l2covariates.values{1} = { ...
                        1, 110, 0, 1, 0.5078, 0.0611, 4.2009, 0.8871, ...
                        128054, 128054, 72664, 21039, 32038, 1452 };
    Setup.l2covariates.descrip{1} = '';
    Setup.l2covariates.descrip{2} = 'CONN Quality Assurance: Number of valid (non-outlier) scans';
    Setup.l2covariates.descrip{3} = 'CONN Quality Assurance: Number of outlier scans';
    Setup.l2covariates.descrip{4} = 'CONN Quality Assurance: Proportion of valid (non-outlier) scans';
    Setup.l2covariates.descrip{5} = 'CONN Quality Assurance: Largest motion observed (outliers threshold = 0.9)';
    Setup.l2covariates.descrip{6} = 'CONN Quality Assurance: Average motion observed (disregarding outlier scans) (outliers threshold = 0.9)';
    Setup.l2covariates.descrip{7} = 'CONN Quality Assurance: Largest global BOLD signal changes observed (outliers threshold = 5)';
    Setup.l2covariates.descrip{8} = 'CONN Quality Assurance: Average global BOLD signal changes observed (disregarding outlier scans) (outliers threshold = 5)';
    Setup.l2covariates.descrip{9} = 'CONN Quality Assurance: # of voxels in GreyMatter';
    Setup.l2covariates.descrip{10} = 'CONN Quality Assurance: # of voxels in GreyMatter_eroded';
    Setup.l2covariates.descrip{11} = 'CONN Quality Assurance: # of voxels in WhiteMatter';
    Setup.l2covariates.descrip{12} = 'CONN Quality Assurance: # of voxels in WhiteMatter_eroded';
    Setup.l2covariates.descrip{13} = 'CONN Quality Assurance: # of voxels in CSF';
    Setup.l2covariates.descrip{14} = 'CONN Quality Assurance: # of voxels in CSF_eroded';

    % Parameters
    Setup.acquisitiontype = 1;
    Setup.steps = [1 1 1 1];
    Setup.spatialresolution = 1;
    Setup.analysismask = 1;
    Setup.analysisunits = 1;
    Setup.secondlevelanalyses = 1;

    % Mask
    Setup.explicitmask{1} = fullfile(char(conn_dir),'utils','surf','mask.volume.brainmask.nii');
    % Setup.explicitmask{2} = skipping for now

    % Read mask
    m = spm_vol(Setup.explicitmask{1});
    m.private = [];

    % Save mask 
    Setup.explicitmask{3} = m; 

    % Secondary dataset options
    Setup.secondarydataset(1).functionals_type = 2;
    Setup.secondarydataset(1).functionals_explicit = {};
    Setup.secondarydataset(1).functionals_rule = {};
    Setup.secondarydataset(1).label = 'unsmoothed functional data';
    Setup.secondarydataset(2).functionals_type = 4;
    Setup.secondarydataset(2).functionals_explicit{1}{1} = {[] [] []};
    Setup.secondarydataset(2).functionals_rule = {};
    Setup.secondarydataset(2).label = 'FMAP';
    Setup.secondarydataset(3).functionals_type = 4;
    Setup.secondarydataset(3).functionals_explicit{1}{1} = {[] [] []};
    Setup.secondarydataset(3).functionals_rule = {};
    Setup.secondarydataset(3).label = 'VDM';
    Setup.secondarydataset(4).functionals_type = 4;
    Setup.secondarydataset(4).functionals_explicit{1}{1} = {[] [] []};
    Setup.secondarydataset(4).functionals_rule = {};
    Setup.secondarydataset(4).label = 'TPM';

    % More setup options
    Setup.unwarp_functional = {};
    Setup.coregsource_functional = {};
    Setup.erosion.binary_threshold = [0.5000 0.5000 0.5000];
    Setup.erosion.erosion_steps = [0 1 1];
    Setup.erosion.erosion_neighb = [1 1 1];
    Setup.erosion.binary_threshold_type = [1 1 1];
    Setup.erosion.exclude_grey_matter = [NaN NaN NaN];
    Setup.outputfiles = [0 1 0 0 0 0];
    Setup.spatialresolutionvolume{1} = spm_vol(fullfile(char(conn_dir),'utils','surf','mask.volume.brainmask.nii'));

    % Save setup
    CONN_x.Setup = Setup;

    % Preproc
    % Preproc.variables.names = skipping for now
    % Preproc.variables.types = skipping for now
    % Preproc.variables.power = skipping for now
    % Preproc.variables.deriv = skipping for now
    % Preproc.variables.dimensions = skipping for now
    Preproc.confounds.names = {'White Matter' 'CSF' 'realignment' 'scrubbing' ...
                                'Effect of rest' 'Effect of stim_on'};
    Preproc.confounds.types = {'roi'  'roi'  'cov'  'cov'  'cov'  'cov'};
    Preproc.confounds.power = {[1]  [1]  [1]  [1]  [1]  [1]};
    Preproc.confounds.deriv = {[0]  [0]  [0]  [0]  [1]  [1]};

    % We don't know how many columns ART will give us for outliers so we
    % need to check
    outliers_data = load(Setup.l1covariates.files{1}{1}{1}{1});
    outliers_dim = size(outliers_data.R);

    Preproc.confounds.dimensions = {[5 16]  [5 16]  [Inf 6] [Inf outliers_dim(2)] [Inf 1] [Inf 1]}; 
    Preproc.confounds.filter = {[0]  [0]  [0]  [0]  [0]  [0]};
    Preproc.filter = [0.0080 0.0900];
    Preproc.despiking = 1;
    Preproc.regbp = 2;
    Preproc.detrending = 1;
    CONN_x.Preproc = Preproc;

    % Analyses
    Analyses.name = 'SBC_01';
    Analyses.sourcenames = {};
    Analyses.regressors.names = {};
    Analyses.regressors.types = {};
    Analyses.regressors.deriv = {};
    Analyses.regressors.fbands = {};
    Analyses.regressors.dimensions = {};
    Analyses.type = 3;
    Analyses.measure = 1;
    Analyses.modulation = 0;
    Analyses.conditions = [];
    Analyses.weight = 2;
    Analyses.sources = {};
    CONN_x.Analyses = Analyses;

    % Top-level variables
    CONN_x.Analysis = 1;
    CONN_x.Analysis_variables.names = {};
    CONN_x.Analysis_variables.types = {};
    CONN_x.Analysis_variables.deriv = {};
    CONN_x.Analysis_variables.fbands = {};
    CONN_x.Analysis_variables.dimensions = {};
    CONN_x.dynAnalyses = struct('name',        cell(1,0), ...
                                'regressors',  cell(1,0), ...
                                'variables',   cell(1,0), ...
                                'Ncomponents', cell(1,0), ...
                                'condition',   cell(1,0), ...
                                'window',      cell(1,0), ...
                                'output',      cell(1,0), ...
                                'sources',     cell(1,0) );
    CONN_x.dynAnalysis = 1;
    CONN_x.vvAnalyses = struct('name',          cell(1,0), ...
                               'measurements',  cell(1,0), ...
                               'variables',     cell(1,0), ...
                               'regressors',    cell(1,0), ...
                               'measures',      cell(1,0), ...
                               'options',       cell(1,0), ...
                               'mask',          cell(1,0));
    CONN_x.vvAnalysis = 1;
    CONN_x.Results.foldername = '';
    CONN_x.Results.xX = [];
    CONN_x.Results.saved.names = {};
    CONN_x.Results.saved.labels = {};
    CONN_x.Results.saved.nsubjecteffects = {};
    CONN_x.Results.saved.csubjecteffects = {};
    CONN_x.Results.saved.nconditions = {};
    CONN_x.Results.saved.cconditions = {};
    CONN_x.Results.saved.descrip = {};
    CONN_x.SetupPreproc.steps{1} = 'functional_art';
    CONN_x.SetupPreproc.coregtomean = 1;
    %CONN_x.SetupPreproc.log{1} skipped for now...

    % Save the struct
    struct_fname = fullfile(char(ses_dir),sprintf('step9_denoise_task-%s_run-%d.mat', task_name, run_no));
    CONN_x.filename = struct_fname;
    save(struct_fname, 'CONN_x');

    % Create batch for running
    batch.filename = struct_fname;
    batch.Setup.done=1;
    batch.Setup.overwrite='Yes';
    batch.Denoising.done=1;
    batch.Denoising.overwrite='Yes';

    % Run the batch
    my_log('Running denoising...')
    conn_batch(batch);

    % Update files
    analysis_info.func_vol_curr_rest = prepend(analysis_info.func_vol_curr_rest, 'd');

end