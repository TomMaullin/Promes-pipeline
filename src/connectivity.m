function analyses_info = connectivity(analyses_info)

    % Run concatenation
    analyses_info = step12_concat(analyses_info);
    
    % Run connectivity
    analyses_info = step13_connectivity(analyses_info);

    % Compute LIs
    analyses_info = step14_LI_calculation(analyses_info);

    % Compute LIs
    analyses_info = step15_cleanup_connectivity(analyses_info);

end