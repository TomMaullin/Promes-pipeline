function analysis_info = task_preprocessing(analysis_info)
 
    % ---------------------------------------------------------------------
    % In this function, we run the following preprocessing stages;
    % 
    %  1: Distortion correction using VDM
    %  2: Realignment and Unwarping using VDM
    %  3: Slice-timing Correction
    %  4: Coregistration from the structural to the average functional
    %  5: Segmentation (to compute deformation fields)
    %  6: Normalisation (to deform to MNI)
    %  7: Spatial Smoothing (6mm FWHM)
    % 
    % ---------------------------------------------------------------------
    %
    % Developers note: Although the following pipeline stages concatenate
    % the data and treat it as though it is rest, the preprocessing stages
    % in this file need temporal continuity and thus *must* be performed
    % prior to concatenation. That is, we must treat the data as task here!
    %
    % ---------------------------------------------------------------------
    % Author: Tom Maullin
    % Last edited: 25/03/26
    % ---------------------------------------------------------------------

    % Run VDM calculation
    analysis_info = step1_distortion_correction(analysis_info);

    % Run realign and unwarp
    analysis_info = step2_realign_and_unwarp(analysis_info);

    % Run slice timing
    analysis_info = step3_slice_timing(analysis_info);

    % Run structural coregistration
    analysis_info = step4_structural_coregistration(analysis_info);

    % Run segmentation
    analysis_info = step5_segmentation(analysis_info);

    % Run normalise
    analysis_info = step6_normalise(analysis_info);

    % Run smoothing
    analysis_info = step7_smooth(analysis_info);

    % Run task glm
    analysis_info = step8_task_glm(analysis_info);

end