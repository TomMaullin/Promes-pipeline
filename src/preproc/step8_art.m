function analysis_info = step8_art(analysis_info)

    % ---------------------------------------------------------------------
    % Developer note: A good thread on the conn_module can be found here
    % https://www.nitrc.org/forum/forum.php?forum_id=1144&max_rows=75&offset=9900&style=flat&thread_id=
    % ---------------------------------------------------------------------

    % Get subject, session numbers and session dir
    sub_no = analysis_info.sub_no;
    ses_no = analysis_info.ses_no;
    ses_dir = analysis_info.ses_dir;

    % Files
    func_file = analysis_info.func_vol_curr;

    % Run ART from CONN
    my_log('Running ART...')
    conn_module('preprocessing', 'steps', 'functional_art', 'functionals', {{func_file}});

    % Save outputs
    analysis_info.art_outliers = fullfile(char(ses_dir), 'func', sprintf('art_regression_outliers_smwausub-%03d_ses-%02d_task-AudCat_run-1_bold.mat', sub_no, ses_no));

end