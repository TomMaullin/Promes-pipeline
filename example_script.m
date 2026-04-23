% Set data directory
data_dir = % TO FILL

% Session, subject and run number
ses_nos = % TO FILL
run_nos = % TO FILL
sub_nos = % TO FILL

% Name of task
task_names = % TO FILL

% Run task and rest pipelines? (fill in true to run and false to not run)
run_task = % TO FILL
run_rest = % TO FILL

% Run promes for data directory
analyses_info = run_promes(data_dir,ses_nos,sub_nos,task_names,run_nos,run_task,run_rest);