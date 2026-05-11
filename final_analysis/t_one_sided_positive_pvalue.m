function p = t_one_sided_positive_pvalue(t, df)

    % Transform variable
    x = df ./ (df + t.^2);

    % Two-sided probability
    p_two = betainc(x, df/2, 0.5);

    % Convert to one-sided positive-tail p-value
    if t >= 0
        p = 0.5 * p_two;
    else
        p = 1 - 0.5 * p_two;
    end

end