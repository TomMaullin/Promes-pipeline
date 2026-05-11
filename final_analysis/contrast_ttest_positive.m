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

    % Store outputs
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

end