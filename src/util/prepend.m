function new_path = prepend(full_path, prepend_string)

    % Get fileparts
    [filepath, name, ext] = fileparts(full_path);

    % Prepend string
    new_path = fullfile(filepath, [prepend_string name ext]);

end