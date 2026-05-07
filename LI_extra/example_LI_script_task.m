% Inputs
bids_dir = % Enter the path to your bids directory here e.g. bids_dir = '\path\to\BIDS';
sub_nos = % Enter subject numbers here, e.g. sub_no = [2 2 5 12];
ses_nos = % Enter session numbers here, e.g. sub_no = [1 2 1 1];
run_nos = % Enter run numbers here, e.g. sub_no = [1 1 1 2];
task_names = % Enter task names here, e.g. ["covertverb","covertverb","covertverb","ADDT"];

% Run masked LI computation
compute_masked_task_LIs(bids_dir, sub_nos, ses_nos, run_nos, task_names);