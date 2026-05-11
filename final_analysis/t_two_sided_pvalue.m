function p = t_two_sided_pvalue(t, df)

    % Convert to form to put in beta fn
    x = df ./ (df + t.^2);

    % Get two sided p value
    p = betainc(x, df/2, 0.5);

end
