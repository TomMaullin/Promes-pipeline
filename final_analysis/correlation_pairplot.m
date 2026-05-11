function R = correlation_pairplot(vars, labels, figtitle)

    % =========================================================
    % PEARSON CORRELATION MATRIX
    % =========================================================

    % Compute correlations
    R = corrcoef(vars);

    % Print correlations
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
    % PAIR PLOTS
    % =========================================================

    % Number of variables
    nvars = size(vars,2);

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

                % Correlation coefficient
                Rc = corrcoef(vars(:,j), vars(:,i));

                % Add title
                title(sprintf('r = %.2f', Rc(1,2)));

            end

        end

    end

end