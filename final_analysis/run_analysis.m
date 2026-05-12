function run_analysis(filename)
    
    % Import data
    opts = detectImportOptions(filename);
    opts.VariableNamingRule = "preserve";
    
    % Read data as a table
    T = readtable(filename, opts);

    % Read surgery zone
    zone = lower(strtrim(string(T.("Surgery Zone"))));

    % Encode surgery zone
    surg = zeros(height(T),1);
    surg(zone == "left")  =  1;
    surg(zone == "right") = -1; 
    
    % Create ipsilateral variables (Recall: LI=1 corresponds to left
    % brained, LI=-1 corresponds to right brained. Therefore +ve IPS
    % means surgery impacts dominant side, -ve IPS means surgery impacts
    % less dominant side)
    T.("IPS - RS") = surg .* T.("LI - RS comb");
    T.("IPS - TB") = surg .* T.("LI - TB");

    % Remove rows with missing values 
    T_rs = rmmissing(T, 'DataVariables', {'LI - RS comb'});
    T_tb = rmmissing(T, 'DataVariables', {'LI - TB'});
    T_both = rmmissing(T, 'DataVariables', {'LI - RS comb', 'LI - TB'});
    
    % ---------------------------------------------------------------------
    % Task LI test
    % ---------------------------------------------------------------------

    % Response
    y = T_tb.("Post - Pre VCI");
    
    % Design matrix
    X = [ones(height(T_tb),1), ...
         T_tb.("IPS - TB")];
    
    % Contrast: beta_tb - beta_rs
    L = [0 1]';
    
    % Run analysis
    stats = contrast_ttest_positive(y, X, L);
    
    % Print result
    fprintf('\n==========================================\n');
    fprintf('Contrast test: Effect of task IPS on VCI\n');
    fprintf('==========================================\n');
    
    fprintf('Contrast Estimate = %.4f\n', stats.effect);
    fprintf('t                 = %.4f\n', stats.t_effect);
    fprintf('p                 = %.4f\n', 1-stats.p_effect);
    fprintf('(computed using n = %d subjects)\n', stats.n);
    fprintf('(Test was one-sided)\n');
    
    fprintf('\nEffect Size Estimates\n');
    fprintf('------------------------------------------\n');
    fprintf('Partial r          = %.4f\n', stats.r_partial);
    fprintf('Cohen f^2          = %.4f\n', stats.f2);
    
    fprintf('\nSensitivity Analysis\n');
    fprintf('------------------------------------------\n');
    fprintf(['Approximate sample size required for\n' ...
         'significance at alpha = %.2f: N = %d\n'], ...
         stats.alpha, stats.N_needed_sig);
    fprintf(['Approximate sample size required for\n' ...
             '80%% power at alpha = %.2f: N = %d\n'], ...
             stats.alpha, ...
             stats.N_needed_80power);
    
    fprintf('\nAnalysis Summary\n');
    fprintf('------------------------------------------\n');
    
    if stats.p_effect >= 0.05
        fprintf(['The test did not reach statistical \n']);
        fprintf(['significance. However, the observed effect \n']);
        fprintf(['size was non-zero (partial r = %.3f).\n'], stats.r_partial);
        fprintf(['A rough sensitivity analysis suggests that \n']); 
        fprintf(['approximately N = %d subjects would be \n'], stats.N_needed_80power);
        fprintf(['needed in order to detect an effect of this\n']);
        fprintf(['magnitude with 80%% power at alpha = %.2f.\n'], stats.alpha);
    else
        fprintf(['The null was rejected at alpha = %.2f.\n'], stats.alpha);
    end
        
    % ---------------------------------------------------------------------
    % Rest LI test
    % ---------------------------------------------------------------------

    % Response
    y = T_rs.("Post - Pre VCI");
    
    % Design matrix
    X = [ones(height(T_rs),1), ...
         T_rs.("IPS - RS")];
    
    % Contrast: beta_tb - beta_rs
    L = [0 1]';
        
    % Run analysis
    stats = contrast_ttest_positive(y, X, L);
    
    % Print result
    fprintf('\n==========================================\n');
    fprintf('Contrast test: Effect of rest IPS on VCI\n');
    fprintf('==========================================\n');
    
    fprintf('Contrast Estimate = %.4f\n', stats.effect);
    fprintf('t                 = %.4f\n', stats.t_effect);
    fprintf('p                 = %.4f\n', 1-stats.p_effect);
    fprintf('(computed using n = %d subjects)\n', stats.n);
    fprintf('(Test was one-sided)\n');
    
    fprintf('\nEffect Size Estimates\n');
    fprintf('------------------------------------------\n');
    fprintf('Partial r          = %.4f\n', stats.r_partial);
    fprintf('Cohen f^2          = %.4f\n', stats.f2);
    
    fprintf('\nSensitivity Analysis\n');
    fprintf('------------------------------------------\n');
    fprintf(['Approximate sample size required for\n' ...
         'significance at alpha = %.2f: N = %d\n'], ...
         stats.alpha, stats.N_needed_sig);
    fprintf(['Approximate sample size required for\n' ...
             '80%% power at alpha = %.2f: N = %d\n'], ...
             stats.alpha, ...
             stats.N_needed_80power);
    
    fprintf('\nAnalysis Summary\n');
    fprintf('------------------------------------------\n');
    
    if stats.p_effect >= 0.05
        fprintf(['The test did not reach statistical \n']);
        fprintf(['significance. However, the observed effect \n']);
        fprintf(['size was non-zero (partial r = %.3f).\n'], stats.r_partial);
        fprintf(['A rough sensitivity analysis suggests that \n']); 
        fprintf(['approximately N = %d subjects would be \n'], stats.N_needed_80power);
        fprintf(['needed in order to detect an effect of this\n']);
        fprintf(['magnitude with 80%% power at alpha = %.2f.\n'], stats.alpha);
    else
        fprintf(['The null was rejected at alpha = %.2f.\n'], stats.alpha);
    end

    % ---------------------------------------------------------------------
    % Task vs rest comparison
    % ---------------------------------------------------------------------

    % Response
    y = T_both.("Post - Pre VCI");
    
    % Design matrix
    X = [ones(height(T_both),1), ...
         T_both.("IPS - RS"), ...
         T_both.("IPS - TB")];
    
    % Contrast: beta_tb - beta_rs
    L = [0 -1 1]';
    
    % Run analysis
    stats = contrast_ttest(y, X, L);
    
    % Print result
    fprintf('\n==========================================\n');
    fprintf('Contrast test: Task minus rest difference\n');
    fprintf('==========================================\n');

    fprintf('Contrast Estimate = %.4f\n', stats.effect);
    fprintf('t                 = %.4f\n', stats.t_effect);
    fprintf('p                 = %.4f\n', stats.p_effect);
    fprintf('(computed using n = %d subjects)\n', stats.n);
    fprintf('(Test was two-sided)\n');
    
    fprintf('\nEffect Size Estimates\n');
    fprintf('------------------------------------------\n');
    fprintf('Partial r          = %.4f\n', stats.r_partial);
    fprintf('Cohen f^2          = %.4f\n', stats.f2);
    
    fprintf('\nSensitivity Analysis\n');
    fprintf('------------------------------------------\n');
    fprintf(['Approximate sample size required for\n' ...
             'significance at alpha = %.2f: N = %d\n'], ...
             stats.alpha, stats.N_needed_sig);
    
    fprintf(['Approximate sample size required for\n' ...
             '%.0f%% power at alpha = %.2f: N = %d\n'], ...
             stats.target_power*100, ...
             stats.alpha, ...
             stats.N_needed_80power);
    
    fprintf('\nAnalysis Summary\n');
    fprintf('------------------------------------------\n');
    
    if stats.p_effect >= 0.05
        fprintf(['The test did not reach statistical \n']);
        fprintf(['significance. However, the observed effect \n']);
        fprintf(['size was non-zero (partial r = %.3f).\n'], stats.r_partial);
        fprintf(['A rough sensitivity analysis suggests that \n']); 
        fprintf(['approximately N = %d subjects would be \n'], stats.N_needed_80power);
        fprintf(['needed in order to detect an effect of this\n']);
        fprintf(['magnitude with 80%% power at alpha = %.2f.\n'], stats.alpha);
    else
        fprintf(['The null was rejected at alpha = %.2f.\n'], stats.alpha);
    end

    % ---------------------------------------------------------------------
    % Correlation coefficients and pair plots for IPS
    % ---------------------------------------------------------------------
    % Variables
    vars = [T_both.("IPS - RS"), ...
            T_both.("IPS - TB"), ...
            T_both.("Post - Pre VCI")];
    
    % Labels for output
    labels = {"IPS-RS", "IPS-TB", "VCI Change"};

    % The below matrix represents the test directions (+1 means we expect
    % +ve correlation, -1 means negative.
    directions = [
         0   +1   -1
        +1    0   -1
        -1   -1    0
    ];
    
    % Create pairplot
    R = correlation_pairplot(vars, labels, directions, 'Pair plots for IPS vs VCI change');

    % ---------------------------------------------------------------------
    % Correlation coefficients and pair plots for LIs
    % ---------------------------------------------------------------------
    % Variables
    vars = [T_both.("LI - RS comb"), ...
            T_both.("LI - TB"), ...
            T_both.("Post - Pre VCI")];
    
    % Labels for output
    labels = {"LI-RS", "LI-TB", "VCI Change"};
    

    % The below matrix represents the test directions (+1 means we expect
    % +ve correlation, -1 means negative.
    directions = [
         0   +1   -1
        +1    0   -1
        -1   -1    0
    ];
    
    % Create pairplot
    R = correlation_pairplot(vars, labels, directions, 'Pair plots for LI (without surgery side) vs VCI change');

end
