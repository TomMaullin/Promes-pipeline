% Inputs
bids_dir = % Enter the path to your bids directory here e.g. bids_dir = '\path\to\BIDS';
sub_nos = % Enter subject numbers here, e.g. sub_no = [2 5 12];

% Run combined LI computation
compute_combined_LIs(bids_dir, sub_nos);