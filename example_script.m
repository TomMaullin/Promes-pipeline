% Set data directory
data_dir = % TO FILL: /path/to/BIDs/directory

% Session, subject and run number
ses_nos = % TO FILL: List of session numbers, e.g. [1, 1, 1, 1];
sub_nos = % TO FILL: List of subject numbers, e.g. [1, 1, 1, 1];
run_nos = % TO FILL: List of run numbers, e.g. [1, 2, 1, 2];

% Name of task
task_names = % TO FILL: List of task names, e.g. ["covertverb","covertverb","AudCat","AudCat"];

% Run promes for data directory
analyses_info = run_promes(data_dir,ses_nos,sub_nos,task_names,run_nos);