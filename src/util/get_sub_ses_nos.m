function [sub_no, ses_no] = get_sub_ses_nos(ses_dir)

    % Get subject and session number from directory.
    tokens = regexp(ses_dir, 'sub-(\d+).*ses-(\d+)', 'tokens', 'once');
    sub_no = str2double(tokens{1});
    ses_no = str2double(tokens{2});

end