function analyses_info = step14_connectivity(analyses_info)

    % ---------------------------------------------------------------------
    %
    % Following concatenation, we need to set up conn from scratch as we
    % are now using the shortened timeseries. To do so, we essentially
    % re-do step_10 with slightly modified inputs.
    % 
    % Note: This time, we are not doing any denoising, we are only
    % rerunning these steps to ensure CONN has the correct files in the
    % correct places (the analysis and denoising steps should take very
    % little time as we are not performing much new computation)
    %
    % ---------------------------------------------------------------------

    % Get the first analysis_info for reference
    analysis_info = analyses_info{1};

    % Get the number of analyses
    n_analyses = numel(analyses_info);

    % Directories
    conn_dir = char(fileparts(which('conn')));

    % Load in details
    sub_no = analysis_info.sub_no;
    data_dir = analysis_info.data_dir;
    sub_dir = analysis_info.sub_dir;%fullfile(data_dir, sprintf('sub-%03d', sub_no)); %
    
    % Get json and nii data for functional
    func_json =  analysis_info.func_json;
    func_file =  analysis_info.concat_file;
    
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
    CONN_x.isready = [1 1 1 0]; % MARKER [1 1 1 1]
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
    folders.data = fullfile(sub_dir,'conn_concatenated','data');
    folders.bids = fullfile(sub_dir,'conn_concatenated','data','BIDS');
    folders.preprocessing = fullfile(sub_dir,'conn_concatenated','results','preprocessing');
    folders.qa = fullfile(sub_dir,'conn_concatenated','results','qa');
    folders.firstlevel = fullfile(sub_dir,'conn_concatenated','results','firstlevel');
    folders.firstlevel_vv = fullfile(sub_dir,'conn_concatenated','results','firstlevel');
    folders.firstlevel_dyn = fullfile(sub_dir,'conn_concatenated','results','firstlevel');
    folders.secondlevel = fullfile(sub_dir,'conn_concatenated','results','secondlevel');
    folders.methods = fullfile(sub_dir,'conn_concatenated','results','methods');
    folders.bookmarks = fullfile(sub_dir,'conn_concatenated','results','bookmarks');
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
    Setup.conditions.names = {'rest',  ' '};
    Setup.conditions.model = {[]};
    Setup.conditions.values{1}{1}{1} = {[0], [Inf]};

    % Read in condition
    Setup.conditions.param = [0];
    Setup.conditions.filter = {[]};
    Setup.conditions.allnames = {'rest'};
    Setup.conditions.missingdata = 0;

    % 1st level covariates
    Setup.l1covariates.names = {' '};
    Setup.l1covariates.files{1}{1}{1}{1} = [];
    Setup.l1covariates.files{1}{1}{1}{2} = [];
    Setup.l1covariates.files{1}{1}{1}{3} = [];

    % 2nd level covariates (default: might remove)
    Setup.l2covariates.names = {'AllSubjects', 'QC_GreyMatter_vol', 'QC_GreyMatter_eroded_vol',... 
        'QC_WhiteMatter_vol', 'QC_WhiteMatter_eroded_vol', 'QC_CSF_vol', 'QC_CSF_eroded_vol',...
        'QC_DOF_session1', 'QC_DOF', 'QC_BOLDstd_rest', 'QC_GCOR_rest', ' '};
    Setup.l2covariates.values{1} = { ...
                        1, 1200673, 1200673, 672361, 350649, 287721, ...
                        66585, 139, 139, 6.9584e+13, 0.0414};
    Setup.l2covariates.descrip{1} = '';
    Setup.l2covariates.descrip{2} = 'CONN Quality Assurance: # of voxels in GreyMatter';
    Setup.l2covariates.descrip{3} = 'CONN Quality Assurance: # of voxels in GreyMatter_eroded';
    Setup.l2covariates.descrip{4} = 'CONN Quality Assurance: # of voxels in WhiteMatter';
    Setup.l2covariates.descrip{5} = 'CONN Quality Assurance: # of voxels in WhiteMatter_eroded';
    Setup.l2covariates.descrip{6} = 'CONN Quality Assurance: # of voxels in CSF';
    Setup.l2covariates.descrip{7} = 'CONN Quality Assurance: # of voxels in CSF_eroded';
    Setup.l2covariates.descrip{8} = 'CONN Quality Assurance: Effective degrees of freedom (after denoising)';
    Setup.l2covariates.descrip{9} = 'CONN Quality Assurance: Effective degrees of freedom (after denoising)';
    Setup.l2covariates.descrip{10} = 'CONN Quality Assurance: BOLD signal standard deviation (after denoising)';
    Setup.l2covariates.descrip{11} = 'CONN Quality Assurance: Global Correlation @ rest';

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
    Preproc.variables.names = {char("Grey Matter"), char("White Matter"), char("CSF"), char("networks.DefaultMode.MPFC (1,55,-3)"), ...
        char("networks.DefaultMode.LP (L) (-39,-77,33)"), char("networks.DefaultMode.LP (R) (47,-67,29)"), char("networks.DefaultMode.PCC (1,-61,38)"),...
        char("networks.SensoriMotor.Lateral (L) (-55,-12,29)"), char("networks.SensoriMotor.Lateral (R) (56,-10,29)"),...
        char("networks.SensoriMotor.Superior  (0,-31,67)"), char("networks.Visual.Medial (2,-79,12)"), char("networks.Visual.Occipital (0,-93,-4)"),...
        char("networks.Visual.Lateral (L) (-37,-79,10)"), char("networks.Visual.Lateral (R) (38,-72,13)"), char("networks.Salience.ACC (0,22,35)"),...
        char("networks.Salience.AInsula (L) (-44,13,1)"), char("networks.Salience.AInsula (R) (47,14,0)"), char("networks.Salience.RPFC (L) (-32,45,27)"),...
        char("networks.Salience.RPFC (R) (32,46,27)"), char("networks.Salience.SMG (L) (-60,-39,31)"), char("networks.Salience.SMG (R) (62,-35,32)"),...
        char("networks.DorsalAttention.FEF (L)  (-27,-9,64)"), char("networks.DorsalAttention.FEF (R)  (30,-6,64)"), char("networks.DorsalAttention.IPS (L)  (-39,-43,52)"),...
        char("networks.DorsalAttention.IPS (R)  (39,-42,54)"), char("networks.FrontoParietal.LPFC (L)  (-43,33,28)"), char("networks.FrontoParietal.PPC (L)  (-46,-58,49)"),...
        char("networks.FrontoParietal.LPFC (R)  (41,38,30)"), char("networks.FrontoParietal.PPC (R)  (52,-52,45)"), char("networks.Language.IFG (L) (-51,26,2)"),...
        char("networks.Language.IFG (R) (54,28,1)"), char("networks.Language.pSTG (L) (-57,-47,15)"), char("networks.Language.pSTG (R) (59,-42,13)"),...
        char("networks.Cerebellar.Anterior (0,-63,-30)"), char("networks.Cerebellar.Posterior (0,-79,-32)"), char("atlas.FP r (Frontal Pole Right)"),...
        char("atlas.FP l (Frontal Pole Left)"), char("atlas.IC r (Insular Cortex Right)"), char("atlas.IC l (Insular Cortex Left)"),...
        char("atlas.SFG r (Superior Frontal Gyrus Right)"), char("atlas.SFG l (Superior Frontal Gyrus Left)"), char("atlas.MidFG r (Middle Frontal Gyrus Right)"),...
        char("atlas.MidFG l (Middle Frontal Gyrus Left)"), char("atlas.IFG tri r (Inferior Frontal Gyrus, pars triangularis Right)"),...
        char("atlas.IFG tri l (Inferior Frontal Gyrus, pars triangularis Left)"), char("atlas.IFG oper r (Inferior Frontal Gyrus, pars opercularis Right)"),...
        char("atlas.IFG oper l (Inferior Frontal Gyrus, pars opercularis Left)"), char("atlas.PreCG r (Precentral Gyrus Right)"), char("atlas.PreCG l (Precentral Gyrus Left)"),...
        char("atlas.TP r (Temporal Pole Right)"), char("atlas.TP l (Temporal Pole Left)"), char("atlas.aSTG r (Superior Temporal Gyrus, anterior division Right)"),...
        char("atlas.aSTG l (Superior Temporal Gyrus, anterior division Left)"), char("atlas.pSTG r (Superior Temporal Gyrus, posterior division Right)"),...
        char("atlas.pSTG l (Superior Temporal Gyrus, posterior division Left)"), char("atlas.aMTG r (Middle Temporal Gyrus, anterior division Right)"),...
        char("atlas.aMTG l (Middle Temporal Gyrus, anterior division Left)"), char("atlas.pMTG r (Middle Temporal Gyrus, posterior division Right)"),...
        char("atlas.pMTG l (Middle Temporal Gyrus, posterior division Left)"), char("atlas.toMTG r (Middle Temporal Gyrus, temporooccipital part Right)"),...
        char("atlas.toMTG l (Middle Temporal Gyrus, temporooccipital part Left)"), char("atlas.aITG r (Inferior Temporal Gyrus, anterior division Right)"),...
        char("atlas.aITG l (Inferior Temporal Gyrus, anterior division Left)"), char("atlas.pITG r (Inferior Temporal Gyrus, posterior division Right)"),...
        char("atlas.pITG l (Inferior Temporal Gyrus, posterior division Left)"), char("atlas.toITG r (Inferior Temporal Gyrus, temporooccipital part Right)"),...
        char("atlas.toITG l (Inferior Temporal Gyrus, temporooccipital part Left)"), char("atlas.PostCG r (Postcentral Gyrus Right)"),...
        char("atlas.PostCG l (Postcentral Gyrus Left)"), char("atlas.SPL r (Superior Parietal Lobule Right)"), char("atlas.SPL l (Superior Parietal Lobule Left)"),...
        char("atlas.aSMG r (Supramarginal Gyrus, anterior division Right)"), char("atlas.aSMG l (Supramarginal Gyrus, anterior division Left)"),...
        char("atlas.pSMG r (Supramarginal Gyrus, posterior division Right)"), char("atlas.pSMG l (Supramarginal Gyrus, posterior division Left)"),...
        char("atlas.AG r (Angular Gyrus Right)"), char("atlas.AG l (Angular Gyrus Left)"), char("atlas.sLOC r (Lateral Occipital Cortex, superior division Right)"),...
        char("atlas.sLOC l (Lateral Occipital Cortex, superior division Left)"), char("atlas.iLOC r (Lateral Occipital Cortex, inferior division Right)"),...
        char("atlas.iLOC l (Lateral Occipital Cortex, inferior division Left)"), char("atlas.ICC r (Intracalcarine Cortex Right)"), char("atlas.ICC l (Intracalcarine Cortex Left)"),...
        char("atlas.MedFC (Frontal Medial Cortex)"), char("atlas.SMA r (Juxtapositional Lobule Cortex -formerly Supplementary Motor Cortex- Right)"),...
        char("atlas.SMA L(Juxtapositional Lobule Cortex -formerly Supplementary Motor Cortex- Left)"), char("atlas.SubCalC (Subcallosal Cortex)"),...
        char("atlas.PaCiG r (Paracingulate Gyrus Right)"), char("atlas.PaCiG l (Paracingulate Gyrus Left)"), char("atlas.AC (Cingulate Gyrus, anterior division)"),...
        char("atlas.PC (Cingulate Gyrus, posterior division)"), char("atlas.Precuneous (Precuneous Cortex)"), char("atlas.Cuneal r (Cuneal Cortex Right)"),...
        char("atlas.Cuneal l (Cuneal Cortex Left)"), char("atlas.FOrb r (Frontal Orbital Cortex Right)"), char("atlas.FOrb l (Frontal Orbital Cortex Left)"),...
        char("atlas.aPaHC r (Parahippocampal Gyrus, anterior division Right)"), char("atlas.aPaHC l (Parahippocampal Gyrus, anterior division Left)"),...
        char("atlas.pPaHC r (Parahippocampal Gyrus, posterior division Right)"), char("atlas.pPaHC l (Parahippocampal Gyrus, posterior division Left)"),...
        char("atlas.LG r (Lingual Gyrus Right)"), char("atlas.LG l (Lingual Gyrus Left)"), char("atlas.aTFusC r (Temporal Fusiform Cortex, anterior division Right)"),...
        char("atlas.aTFusC l (Temporal Fusiform Cortex, anterior division Left)"), char("atlas.pTFusC r (Temporal Fusiform Cortex, posterior division Right)"),...
        char("atlas.pTFusC l (Temporal Fusiform Cortex, posterior division Left)"), char("atlas.TOFusC r (Temporal Occipital Fusiform Cortex Right)"),...
        char("atlas.TOFusC l (Temporal Occipital Fusiform Cortex Left)"), char("atlas.OFusG r (Occipital Fusiform Gyrus Right)"),...
        char("atlas.OFusG l (Occipital Fusiform Gyrus Left)"), char("atlas.FO r (Frontal Operculum Cortex Right)"), char("atlas.FO l (Frontal Operculum Cortex Left)"),...
        char("atlas.CO r (Central Opercular Cortex Right)"), char("atlas.CO l (Central Opercular Cortex Left)"), char("atlas.PO r (Parietal Operculum Cortex Right)"),...
        char("atlas.PO l (Parietal Operculum Cortex Left)"), char("atlas.PP r (Planum Polare Right)"), char("atlas.PP l (Planum Polare Left)"),...
        char("atlas.HG r (Heschl's Gyrus Right)"), char("atlas.HG l (Heschl's Gyrus Left)"), char("atlas.PT r (Planum Temporale Right)"),...
        char("atlas.PT l (Planum Temporale Left)"), char("atlas.SCC r (Supracalcarine Cortex Right)"), char("atlas.SCC l (Supracalcarine Cortex Left)"),...
        char("atlas.OP r (Occipital Pole Right)"), char("atlas.OP l (Occipital Pole Left)"), char("atlas.Thalamus r"), char("atlas.Thalamus l"),...
        char("atlas.Caudate r"), char("atlas.Caudate l"), char("atlas.Putamen r"), char("atlas.Putamen l"), char("atlas.Pallidum r"), char("atlas.Pallidum l"),...
        char("atlas.Hippocampus r"), char("atlas.Hippocampus l"), char("atlas.Amygdala r"), char("atlas.Amygdala l"), char("atlas.Accumbens r"), char("atlas.Accumbens l"),...
        char("atlas.Brain-Stem"), char("atlas.Cereb1 l (Cerebelum Crus1 Left)"), char("atlas.Cereb1 r (Cerebelum Crus1 Right)"), char("atlas.Cereb2 l (Cerebelum Crus2 Left)"),...
        char("atlas.Cereb2 r (Cerebelum Crus2 Right)"), char("atlas.Cereb3 l (Cerebelum 3 Left)"), char("atlas.Cereb3 r (Cerebelum 3 Right)"),...
        char("atlas.Cereb45 l (Cerebelum 4 5 Left)"), char("atlas.Cereb45 r (Cerebelum 4 5 Right)"), char("atlas.Cereb6 l (Cerebelum 6 Left)"),...
        char("atlas.Cereb6 r (Cerebelum 6 Right)"), char("atlas.Cereb7 l (Cerebelum 7b Left)"), char("atlas.Cereb7 r (Cerebelum 7b Right)"),...
        char("atlas.Cereb8 l (Cerebelum 8 Left)"), char("atlas.Cereb8 r (Cerebelum 8 Right)"), char("atlas.Cereb9 l (Cerebelum 9 Left)"),...
        char("atlas.Cereb9 r (Cerebelum 9 Right)"), char("atlas.Cereb10 l (Cerebelum 10 Left)"), char("atlas.Cereb10 r (Cerebelum 10 Right)"),...
        char("atlas.Ver12 (Vermis 1 2)"), char("atlas.Ver3 (Vermis 3)"), char("atlas.Ver45 (Vermis 4 5)"), char("atlas.Ver6 (Vermis 6)"), char("atlas.Ver7 (Vermis 7)"),...
        char("atlas.Ver8 (Vermis 8)"), char("atlas.Ver9 (Vermis 9)"), char("atlas.Ver10 (Vermis 10)"), char("Effect of rest")};
    Preproc.variables.types = [repmat({'roi'},1,167), {'cov'}];
    Preproc.variables.power = repmat({1},1,168);
    Preproc.variables.deriv = [repmat({0},1,167), {1}];
    Preproc.variables.dimensions = repmat({[1 1]},1,168);
    Preproc.confounds.names = {};
    Preproc.confounds.types = {};
    Preproc.confounds.power = {};
    Preproc.confounds.deriv = {};
    Preproc.confounds.dimensions = {};
    Preproc.confounds.filter = {};
    Preproc.despiking = 0;
    Preproc.regbp = 0;
    Preproc.detrending = 0;
    CONN_x.Preproc = Preproc;


    % Analyses
    Analyses.name = 'SBC_01';
    Analyses.sourcenames = {};
    %Analyses.sourcenames{1} = 'networks.Language.IFG (L) (-51,26,2)';
    %Analyses.sourcenames{2} = 'networks.Language.IFG (R) (54,28,1)';
    %Analyses.sourcenames{3} = 'networks.Language.pSTG (L) (-57,-47,15)';
    %Analyses.sourcenames{4} = 'networks.Language.pSTG (R) (59,-42,13)';
    Analyses.regressors.names{1} = 'networks.Language.IFG (L) (-51,26,2)';
    Analyses.regressors.names{2} = 'networks.Language.IFG (R) (54,28,1)';
    Analyses.regressors.names{3} = 'networks.Language.pSTG (L) (-57,-47,15)';
    Analyses.regressors.names{4} = 'networks.Language.pSTG (R) (59,-42,13)';
    Analyses.regressors.types = {'roi' 'roi' 'roi' 'roi'};
    Analyses.regressors.deriv = {0 0 0 0};
    Analyses.regressors.fbands = {1 1 1 1};
    Analyses.regressors.dimensions = {[1 1] [1 1] [1 1] [1 1]};
    Analyses.type = 3;
    Analyses.measure = 1;
    Analyses.modulation = 0;
    Analyses.conditions = [];
    Analyses.weight = 2;
    Analyses.sources = {};
    %Analyses.sources{1} = 'networks.Language.IFG (L) (-51,26,2)';
    %Analyses.sources{2} = 'networks.Language.IFG (R) (54,28,1)';
    %Analyses.sources{3} = 'networks.Language.pSTG (L) (-57,-47,15)';
    %Analyses.sources{4} = 'networks.Language.pSTG (R) (59,-42,13)';
    CONN_x.Analyses = Analyses;

    % Top-level variables
    CONN_x.Analysis = 1;
    CONN_x.Analysis_variables.names = Preproc.variables.names;
    CONN_x.Analysis_variables.types = repmat({'roi'},1,168); % Note: CONN itself treats the rest covariate in position 168 as a roi at this point
    CONN_x.Analysis_variables.deriv = repmat({0},1,168);
    CONN_x.Analysis_variables.fbands = repmat({1},1,168);
    CONN_x.Analysis_variables.dimensions = repmat({[1 1]},1,168);
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
    CONN_x.Results.xX.displayvoxels = 1;
    CONN_x.Results.xX.Analysis = 1;
    CONN_x.Results.xX.vvAnalysis = 1;
    CONN_x.Results.xX.dynAnalysis = 1;
    CONN_x.Results.xX.nsubjecteffects = 1;
    CONN_x.Results.xX.nsubjecteffectsbyname = {'AllSubjects'};
    CONN_x.Results.xX.nconditions = 1;
    CONN_x.Results.xX.nconditionsbyname = {'rest'};
    CONN_x.Results.xX.csubjecteffects = 1;
    CONN_x.Results.xX.nsources = 1;
    CONN_x.Results.xX.csources = 1;
    CONN_x.Results.xX.nsourcesbyname = {'networks.Language.IFG (L) (-51,26,2)'};
    CONN_x.Results.xX.cconditions = 1;
    CONN_x.Results.xX.modeltype = 1;
    CONN_x.Results.xX.X = 1;
    CONN_x.Results.saved.labels = {};
    CONN_x.Results.saved.nsubjecteffects = {};
    CONN_x.Results.saved.csubjecteffects = {};
    CONN_x.Results.saved.nconditions = {};
    CONN_x.Results.saved.cconditions = {};
    CONN_x.Results.saved.descrip = {};

    % Save the struct
    struct_fname = fullfile(char(sub_dir),'conn_concatenated.mat');
    CONN_x.filename = struct_fname;
    save(struct_fname, 'CONN_x');

    % Create batch for running
    batch.filename = struct_fname;
    batch.Setup.done=1;
    batch.Setup.overwrite='Yes';
    batch.Denoising.done=1;
    batch.Denoising.overwrite='Yes';
    batch.Denoising.confounds.names = {''};
    batch.Denoising.filter = [0 Inf]; % Equivalent to running no bandpass
    batch.Analysis.done=1;
    batch.Analysis.overwrite='Yes';
    batch.Analysis.sources{1} = 'networks.Language.IFG (L) (-51,26,2)';
    batch.Analysis.sources{2} = 'networks.Language.IFG (R) (54,28,1)';
    batch.Analysis.sources{3} = 'networks.Language.pSTG (L) (-57,-47,15)';
    batch.Analysis.sources{4} = 'networks.Language.pSTG (R) (59,-42,13)';

    % Run the batch
    my_log('Running rs-connectivity...')
    conn_batch(batch);

    % Store outputs
    for i = 1:n_analyses

        % Update files
        analyses_info{i}.connectivity.IFG.L = fullfile(char(sub_dir), 'conn_concatenated', ...
            'results', 'firstlevel', 'SBC_01', 'BETA_Subject001_Condition001_Source001.nii');
        analyses_info{i}.connectivity.IFG.R = fullfile(char(sub_dir), 'conn_concatenated', ...
            'results', 'firstlevel', 'SBC_01', 'BETA_Subject001_Condition001_Source002.nii');
        analyses_info{i}.connectivity.pSTG.L = fullfile(char(sub_dir), 'conn_concatenated', ...
            'results', 'firstlevel', 'SBC_01', 'BETA_Subject001_Condition001_Source003.nii');
        analyses_info{i}.connectivity.pSTG.R = fullfile(char(sub_dir), 'conn_concatenated', ...
            'results', 'firstlevel', 'SBC_01', 'BETA_Subject001_Condition001_Source004.nii');
        analyses_info{i}.connectivity.mat_file = fullfile(char(sub_dir), 'conn_concatenated.mat');
    
    end

end