function analysis_info = rest_preprocessing(analysis_info)


    % Unpack ses_dir
    ses_dir = analysis_info.ses_dir;

    % Run ART
    analysis_info = step8_art(analysis_info);

    % Run denoising
    analysis_info = step9_denoising(analysis_info);

    % Run concatenation
    analysis_info = step10_concatenation(analysis_info);

    % Run cleanup
    analysis_info = step11_cleanup(analysis_info);

end