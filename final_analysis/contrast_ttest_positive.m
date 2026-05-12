function stats = contrast_ttest_positive(y, X, L)

    % Number of observations
    n = length(y);

    % Number of predictors
    p = size(X,2);

    % Degrees of freedom
    df = n - p;

    % Estimate coefficients
    beta = X \ y;

    % Predicted values
    yhat = X * beta;

    % Residuals
    res = y - yhat;

    % Residual variance
    sigma2 = (res' * res) / df;

    % Covariance matrix of beta
    CovB = sigma2 * inv(X' * X);

    % Standard errors of beta
    SE_beta = sqrt(diag(CovB));

    % t statistics for coefficients
    t_beta = beta ./ SE_beta;

    % Contrast effect
    effect = L' * beta;

    % Standard error of contrast
    SE_effect = sqrt(L' * CovB * L);

    % t statistic for contrast
    t_effect = effect / SE_effect;

    % One-sided positive p value
    p_effect = t_one_sided_positive_pvalue(t_effect, df);

    % =========================================================
    % Effect size + sensitivity analysis
    % =========================================================

    % Partial correlation effect size
    r_partial = sqrt(t_effect^2 / (t_effect^2 + df));

    % Cohen's f^2
    f2 = r_partial^2 / (1 - r_partial^2);

    % Sensitivity assumptions
    alpha = 0.05;
    target_power = 0.80;

    % Solve P(T > tcrit) = alpha
    tcrit = fzero( ...
        @(t) t_one_sided_positive_pvalue(t, df) - alpha, ...
        2);

    % Inverse standard normal CDF using base MATLAB
    zpow = -sqrt(2) * erfcinv(2 * target_power);

    % Approximate required N for significance only
    N_needed_sig = ceil(n * (tcrit / abs(t_effect))^2);

    % Approximate required N for 80% power
    N_needed_80power = ceil( ...
        n * ((tcrit + zpow) / abs(t_effect))^2 );

    % =========================================================
    % Store outputs
    % =========================================================

    stats.beta      = beta;
    stats.SE_beta   = SE_beta;
    stats.t_beta    = t_beta;

    stats.effect    = effect;
    stats.SE_effect = SE_effect;
    stats.t_effect  = t_effect;
    stats.p_effect  = p_effect;

    stats.n         = n;
    stats.df        = df;
    stats.residuals = res;
    stats.yhat      = yhat;

    % Effect size outputs
    stats.r_partial = r_partial;
    stats.f2        = f2;

    % Sensitivity outputs
    stats.alpha            = alpha;
    stats.target_power     = target_power;
    stats.N_needed_sig     = N_needed_sig;
    stats.N_needed_80power = N_needed_80power;

end