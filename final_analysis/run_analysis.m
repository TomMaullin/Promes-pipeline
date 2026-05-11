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
    stats = contrast_ttest(y, X, L);
    
    % Print result
    fprintf('\n==========================================\n');
    fprintf('Contrast test: Effect of task LIs on VCI\n');
    fprintf('==========================================\n');
    
    fprintf('Contrast Estimate = %.4f\n',    stats.effect);
    fprintf('t                 = %.4f\n',  stats.t_effect);
    fprintf('p                 = %.4f\n',  stats.p_effect);
    fprintf('(computed using n = %d subjects)\n', stats.n);
        
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
    stats = contrast_ttest(y, X, L);
    
    % Print result
    fprintf('\n==========================================\n');
    fprintf('Contrast test: Effect of rest LIs on VCI\n');
    fprintf('==========================================\n');
    
    fprintf('Contrast Estimate = %.4f\n',    stats.effect);
    fprintf('t                 = %.4f\n',  stats.t_effect);
    fprintf('p                 = %.4f\n',  stats.p_effect);
    fprintf('(computed using n = %d subjects)\n', stats.n);

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
    
    fprintf('Contrast Estimate = %.4f\n',    stats.effect);
    fprintf('t                 = %.4f\n',  stats.t_effect);
    fprintf('p                 = %.4f\n',  stats.p_effect);
    fprintf('(computed using n = %d subjects)\n', stats.n);
    

    % ---------------------------------------------------------------------
    % Correlation coefficients and pair plots for IPS
    % ---------------------------------------------------------------------
    % Variables
    vars = [T_both.("IPS - RS"), ...
            T_both.("IPS - TB"), ...
            T_both.("Post - Pre VCI")];
    
    % Labels for output
    labels = {"IPS-RS", "IPS-TB", "VCI Change"};
    
    % Create pairplot
    R = correlation_pairplot(vars, labels, 'Pair plots for IPS vs VCI change');

    % ---------------------------------------------------------------------
    % Correlation coefficients and pair plots for LIs
    % ---------------------------------------------------------------------
    % Variables
    vars = [T_both.("LI - RS comb"), ...
            T_both.("LI - TB"), ...
            T_both.("Post - Pre VCI")];
    
    % Labels for output
    labels = {"LI-RS", "LI-TB", "VCI Change"};
    
    % Create pairplot
    R = correlation_pairplot(vars, labels, 'Pair plots for LI (without surgery side) vs VCI change');

end
