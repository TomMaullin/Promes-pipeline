function analysis_info = rest_preprocessing(analysis_info)

    % Run ART
    analysis_info = step8_art(analysis_info);

    % Run denoising
    analysis_info = step9_denoising(analysis_info);

    % Run concatenation
    analysis_info = step10_remove_task(analysis_info);

    % Run cleanup
    analysis_info = step11_cleanup_preproc(analysis_info);

end