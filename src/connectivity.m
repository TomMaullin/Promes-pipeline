function analyses_info = connectivity(analyses_info)

    % Run rest
    if analyses_info{1}.run_rest
            
        % Run concatenation
        analyses_info = step13_concat(analyses_info);
        
        % Run connectivity
        analyses_info = step14_connectivity(analyses_info);

    end

    % Compute LIs
    analyses_info = step15_LI_calculation(analyses_info);


    % Check if we need to run cleanup
    if analyses_info{1}.cleanup

        % Compute LIs
        analyses_info = step16_cleanup_connectivity(analyses_info);

    end

end