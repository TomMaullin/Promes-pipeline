function analysis_info = rest_preprocessing(analysis_info)
    
    % Check if we need to run rest
    if analysis_info.run_rest

        % Run ART
        analysis_info = step9_art(analysis_info);
    
        % Run denoising
        analysis_info = step10_denoising(analysis_info);
    
        % Run concatenation
        analysis_info = step11_remove_task(analysis_info);

    end
    
    % Run cleanup
    analysis_info = step12_cleanup_preproc(analysis_info);

end