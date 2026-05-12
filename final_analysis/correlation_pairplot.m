function stats = correlation_pairplot(vars, labels, directions, figtitle)

    % =========================================================
    % PEARSON CORRELATION MATRIX
    % =========================================================

    % Number of variables
    nvars = size(vars,2);

    % Number of observations
    n = size(vars,1);

    % Correlation matrix
    R = corrcoef(vars);

    % Storage matrices
    P  = nan(nvars);
    T  = nan(nvars);
    N_required = nan(nvars);

    % Store test descriptions
    TestLabel = cell(nvars);

    % Sensitivity settings
    alpha = 0.05;
    target_power = 0.80;

    % =========================================================
    % Compute significance tests + sensitivity
    % =========================================================

    for i = 1:nvars

        for j = 1:nvars

            if i ~= j

                r = R(i,j);

                % Degrees of freedom
                df = n - 2;

                % -------------------------------------------------
                % t statistic for Pearson correlation
                % -------------------------------------------------

                t = r * sqrt(df / (1 - r^2));

                % -------------------------------------------------
                % Fisher z transform
                % -------------------------------------------------

                fisher_z = atanh(r);

                % -------------------------------------------------
                % Determine hypothesis direction
                %
                % directions(i,j):
                %   +1 = positive one-sided
                %   -1 = negative one-sided
                %    0 = two-sided
                % -------------------------------------------------

                direction = directions(i,j);

                if direction == -1

                    % ---------------------------------------------
                    % One-sided negative test
                    % H1: correlation < 0
                    % ---------------------------------------------

                    p = t_one_sided_positive_pvalue(-t, df);

                    % One-sided critical value
                    zcrit = -sqrt(2) * erfcinv(2 * (1 - alpha));

                    test_label = 'one-sided negative';

                elseif direction == +1

                    % ---------------------------------------------
                    % One-sided positive test
                    % H1: correlation > 0
                    % ---------------------------------------------

                    p = t_one_sided_positive_pvalue(t, df);

                    % One-sided critical value
                    zcrit = -sqrt(2) * erfcinv(2 * (1 - alpha));

                    test_label = 'one-sided positive';

                else

                    % ---------------------------------------------
                    % Two-sided test
                    % ---------------------------------------------

                    p = t_two_sided_pvalue(t, df);

                    % Two-sided critical value
                    zcrit = sqrt(2) * erfcinv(alpha);

                    test_label = 'two-sided';

                end

                % -------------------------------------------------
                % z value for target power
                % -------------------------------------------------

                zpow = -sqrt(2) * erfcinv(2 * target_power);

                % -------------------------------------------------
                % Required sample size
                % -------------------------------------------------

                Nreq = ceil(((zcrit + zpow) / abs(fisher_z))^2 + 3);

                % -------------------------------------------------
                % Store
                % -------------------------------------------------

                T(i,j) = t;
                P(i,j) = p;
                N_required(i,j) = Nreq;
                TestLabel{i,j} = test_label;

            end

        end

    end

    % =========================================================
    % Print correlations
    % =========================================================

    fprintf('\n==========================================\n');
    fprintf('Pearson correlation matrix\n');
    fprintf('==========================================\n\n');

    % Header row
    fprintf('%15s', '');

    for j = 1:length(labels)
        fprintf('%15s', labels{j});
    end

    fprintf('\n');

    % Matrix rows
    for i = 1:length(labels)

        fprintf('%15s', labels{i});

        for j = 1:length(labels)
            fprintf('%15.3f', R(i,j));
        end

        fprintf('\n');

    end

    % =========================================================
    % Print statistical tests
    % =========================================================

    fprintf('\n');
    fprintf('==========================================\n');
    fprintf('Correlation significance tests\n');
    fprintf('==========================================\n');

    for i = 1:nvars

        for j = i+1:nvars

            fprintf('\n%s vs %s\n', labels{i}, labels{j});
            fprintf('------------------------------------------\n');

            fprintf('r                  = %.4f\n', R(i,j));
            fprintf('t(%d)              = %.4f\n', n-2, T(i,j));
            fprintf('p                  = %.4f\n', P(i,j));

            fprintf('Test type          = %s\n', ...
                TestLabel{i,j});

            fprintf(['Approximate N required for\n' ...
                     '80%% power at alpha = %.2f: %d\n'], ...
                     alpha, ...
                     N_required(i,j));

            if P(i,j) >= alpha

                fprintf(['Interpret cautiously: the observed\n' ...
                         'correlation may be underpowered.\n']);

            end

        end

    end

    % =========================================================
    % PAIR PLOTS
    % =========================================================

    % Create figure
    figure;

    % White background
    set(gcf, 'Color', 'w');

    % Overall title
    sgtitle(figtitle);

    % Loop through all pairwise combinations
    for i = 1:nvars

        for j = 1:nvars

            % Subplot index
            subplot(nvars, nvars, (i-1)*nvars + j);

            % -------------------------------------------------
            % Histogram on diagonal
            % -------------------------------------------------

            if i == j

                histogram(vars(:,j), 'NumBins', 5);

                xlabel(labels{j});
                ylabel('Count');

                grid on;

            % -------------------------------------------------
            % Scatter plot off diagonal
            % -------------------------------------------------

            else

                % Scatter plot
                scatter(vars(:,j), vars(:,i), 'filled');

                xlabel(labels{j});
                ylabel(labels{i});

                grid on;

                % Linear fit
                pfit = polyfit(vars(:,j), vars(:,i), 1);

                % Prediction grid
                xx = linspace(min(vars(:,j)), ...
                              max(vars(:,j)), 100);

                % Predicted line
                yy = polyval(pfit, xx);

                % Overlay fit
                hold on;
                plot(xx, yy, 'r', 'LineWidth', 2);
                hold off;

                % Add title
                title(sprintf('r = %.2f, p = %.3f', ...
                    R(i,j), P(i,j)));

            end

        end

    end

    % =========================================================
    % Store outputs
    % =========================================================

    stats.R = R;
    stats.P = P;
    stats.T = T;
    stats.N_required = N_required;
    stats.TestLabel = TestLabel;
    stats.n = n;

end