# PROMES Pipeline Code

This repository contains code to run the imaging analysis steps of the PROMES pipeline. Specifically, the code will:

 1. Preprocess BIDS formatted data using SPM and CONN,
 2. Extract rest volumes, concatenate volumes over multiple runs and tasks (if requested), 
 3. Perform seed-based rs-connectivity on the concatenated data using the four language regions for seeds, 
 4. Use the LI-toolbox extension to obtain bootstrap-based LIs for each connectivity map.

## Installation

To use the PROMES pipeline, you must install the following:

 - **MatLab:** You can install MatLab [here](https://www.mathworks.com/help/install/ug/install-products-with-internet-connection.html). **Note:** At time of writing, there are some [known issues](https://www.nitrc.org/forum/forum.php?thread_id=15952&forum_id=1144) with the SPM CONN interface in the latest installations of MatLab. For this reason, I recommend using `MatLab 2024a` or older if you wish to view results using CONN. (The PROMES code in this repository was written and tested in `MatLab 2024a`).

 - **SPM:** You can install SPM by following the installation instructions on [this github page](https://github.com/spm/spm/releases/tag/25.01.02).


 - **CONN:** You can install the SPM CONN package by following the instructions [here](https://web.conn-toolbox.org/installation).


 - **The LI toolbox:** To install the LI toolbox, you must download the package from [this link](https://www.medizin.uni-tuebingen.de/de/das-klinikum/einrichtungen/kliniken/kinderklinik/forschung/forschung-iii/software/formular-li#) (Note: you may have to set your browser to translate the page from German). Once you have filled out the form and downloaded the zip folder, you must unzip the folder and move it into the SPM toolbox folder on your computer (if you are unsure where this folder is on your computer, try running `fullfile(spm('Dir'), 'toolbox')` in MatLab). **Note:** Before using this tool, the authors of the LI toolbox recommend you run `LI_test` in MatLab to check that the left-right configuration of the toolbox matches your default settings in SPM.


 - **The PROMES code:** To download the code for this analysis, click [this link](https://github.com/TomMaullin/Promes-pipeline/archive/refs/heads/main.zip) (alternatively, press the green `Code` button on the [github page](https://github.com/TomMaullin/Promes-pipeline) and then press `Download ZIP`). Once the zip folder has downloaded, `unzip` it in a folder of your choosing.


## Usage

To run the PROMES pipeline, you must modify `example_script.m`. This file looks like:

```
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

% Change this to false if you don't want to run the cleanup step (this step
% removes all the files from preprocessing that we don't need anymore)
cleanup = true;

% Run promes for data directory
analyses_info = run_promes(data_dir,ses_nos,sub_nos,task_names,run_nos,run_task,run_rest,cleanup);
```

To run the pipeline, you must replace `TO FILL` with the appropriate analysis details and then run the script in MatLab. To explain what these details should look like, here are a few examples.

**Example 1:** Suppose you wish to generate connectivity maps for extracted rest from subject 3's second run of the `AudCat` task during their first session. You could fill in the details as follows.


```
% Set data directory
data_dir = 'C:/Documents/BIDS';

% Session, subject and run number
ses_nos = 1;
run_nos = 2;
sub_nos = 3;

% Name of task
task_names = "AudCat";

% Run task and rest pipelines? (fill in true to run and false to not run)
run_task = false;
run_rest = true;

% Change this to false if you don't want to run the cleanup step (this step
% removes all the files from preprocessing that we don't need anymore)
cleanup = true;

% Run promes for data directory
analyses_info = run_promes(data_dir,ses_nos,sub_nos,task_names,run_nos,run_task,run_rest);
```

Here, we have set `run_rest=true` - this means the code will generate LIs for concatenated rest. We have also set `run_task=false;` - this means we *will not* generate task-based LIs. If you were to change this to `run_task=true;`, task-based LIs *would* be generated. Setting `cleanup=true;` tells the code to delete any files which were created during preprocessing that we don't need to save for the final analysis. Unless we have good reason to look at those files (e.g. something has gone wrong and we need to work out what), it makes sense to leave this option set to `true`.

Note that `'C:/Documents/BIDS'` should be replaced with the path to the BIDS dataset on your computer. 

**Example 2:** Suppose instead you want to generate rest LIs by concatenating rest from both the first and second runs of subject 4's first session of the `AudCat` task. You could fill in the details as follows.

```
% Set data directory
data_dir = 'C:/Documents/BIDS';

% Session, subject and run number
ses_nos = [1 1];
run_nos = [1 2];
sub_nos = [4 4];

% Name of task
task_names = ["AudCat","AudCat"];

% Run task and rest pipelines? (fill in true to run and false to not run)
run_task = false;
run_rest = true;

% Change this to false if you don't want to run the cleanup step (this step
% removes all the files from preprocessing that we don't need anymore)
cleanup = true;

% Run promes for data directory
analyses_info = run_promes(data_dir,ses_nos,sub_nos,task_names,run_nos,run_task,run_rest);
```

The first entries of the lists tell us that we are first looking at session `1`, run `1` of subject `4` for `AudCat`. The second entries tell us we are then looking at session `1`, run `2` of subject `4`. Note that `ses_nos`, `run_nos`, `sub_nos`, and `task_names` must all have the same length.

Given these inputs, the PROMES pipeline will run preprocessing and extract the rest volumes for each run separately. It will then concatenate the resultant rest time-series across runs to obtain a single 4d image. Seed-based rs-connectivity and LI are computed from the the final 4d image.

If you change the `run_task` line to `run_task = true;`, then task based fMRI analyses will also be performed for each subject-session-run combination *seperately*. This means you will get a task-based LI per session (we can discuss whether you would like to combine these over sessions at a later date).


**Example 3:** If you want to generate connectivity maps by concatenating rest from both tasks (`covertverb` and `AudCat`) and runs of subject 2's first session, you could use

```
% Set data directory
data_dir = 'C:/Documents/BIDS';

% Session, subject and run number
ses_nos = [1, 1, 1, 1];
run_nos = [1, 2, 1, 2];
sub_nos = [2, 2, 2, 2];

% Name of task
task_names = ["covertverb","covertverb","AudCat","AudCat"];

% Run task and rest pipelines? (fill in true to run and false to not run)
run_task = false;
run_rest = true;

% Change this to false if you don't want to run the cleanup step (this step
% removes all the files from preprocessing that we don't need anymore)
cleanup = true;

% Run promes for data directory
analyses_info = run_promes(data_dir,ses_nos,sub_nos,task_names,run_nos,run_task,run_rest);
```

**Note:** The task names must match those used on the BIDS filenames.

## The Analysis

Once you fill the above and press run, the following analysis steps will be executed for each session-subject-run-task combination:

 - *Step 1: Distortion correction.* Note: this will only run if a magnitude and phase image are present, otherwise it will be skipped.
 - *Step 2: Realignment and unwarping.* Note: Unwarping will use the `vdm5` map from step 1 if given.
 - *Step 3: Slice timing.*
 - *Step 4: Coregistration.*
 - *Step 5: Segmentation.*
 - *Step 6: Normalise.*
 - *Step 7: Smooth.* Performed with 8MM FWHM.
 - *Step 8: Task-based analysis*. A T-statistic map from a GLM is constructed.
 - *Step 9: ART outlier detection.* Note, this only computes the outliers, they are regressed out of the task data in Step 10.
 - *Step 10: Denoising.* This step performs voxelwise despiking and then regresses out the following from the task data:
   1. Task condition, 
   2. Rest condition, 
   3. Realignment parameters (plus derivatives) from step 2,
   4. ART outliers from step 8,
   5. WM nuisance covariates,
   6. CSF nuisance covariates,
   7. Detrending covariates (long term drift) regressors,
   8. A Fourier basis representing a band pass filter.
 - *Step 11: Remove task.* This step removes all task volumes from the timeseries (accounting for up to 15s possible HRF delays), to leave only the volumes which can be reasonably treated as a proxy for resting-state data.
 - *Step 12: Clean-up.* This step removes all but those files which will be taken forward in the analysis.

After the above steps have been executed for each run separately, the following are run:

 - *Step 13: Concatenate.* The 4D rest timeseries from each run are concatenated together into a single 4D volume. Each run's timeseries is also independently standardised and demeaned during this step (this prevents the 'jumps' in signal between sessions from influencing the connectivity estimates).
 - *Step 14: Connectivity.* Seed-based connectivity maps are created in CONN using the 4D volumes from step 13. The seeds used are: `networks.Language.IFG (L) (-51,26,2)`, `networks.Language.IFG (R) (54,28,1)`, `networks.Language.pSTG (L) (-57,-47,15)` and `networks.Language.pSTG (R) (59,-42,13)`.
 - *Step 15: LI Computation.* Lateralisation indices are computed for each of the four seed-based connectivity maps from step 14, as well as any task-based T-statistic maps computed in Step 8.
 - *Step 16: Clean-up.* Redundant files are deleted to save memory.

## Outputs

After an analysis you will have the following files:

| Description | Filename | 
|----------|----------|
| Cleaned Anatomical  | `BIDS/sub-???/ses-??/anat/wmsub-???_ses-??_T1w.nii`  | 
| Cleaned Resting State Data (Single Run)  | `BIDS/sub-???/ses-??/func/sub-???_ses-??_task-???_run-?_cleaned_rest_only_bold.nii`  | 
| Concatenated Resting State Data (Across Runs)  | `BIDS/sub-???/sub-???_cleaned_rest_only_bold.nii`  |
| Connectivity Map (IFG L Seed)  | `BIDS/sub-???/conn_rs_IFG_L.nii`  |
| Connectivity Map (IFG R Seed)  | `BIDS/sub-???/conn_rs_IFG_R.nii`  |
| Connectivity Map (pSTG L Seed)  | `BIDS/sub-???/conn_rs_pSTG_L.nii`  |
| Connectivity Map (pSTG R Seed)  | `BIDS/sub-???/conn_rs_pSTG_R.nii`  |
| Contrast Map (for task based)  | `BIDS/sub-???/ses-??/func/sub-???_ses-??_task-???_run-?_con_0001.nii`  |
| T-statistic Map (for task based)  | `BIDS/sub-???/ses-??/func/sub-???_ses-??_task-???_run-?_spmT_0001.nii`  |

The final LI scores will be appended to `BIDS/LI_results.csv` (if the file does not already exist, it will be created). **Warning:** Every time you re-run the code the LI scores will be added to this file, so re-running the code may result in duplicate entries in the file.

> Note: If you set `cleanup` to `false`, many (many) more files will be output. Be wary of doing this as it will eat your computer's memory very quickly if you try and output all of these files for all of the subjects.


## LI_Extra

The `LI_Extra` code has been added to combine the resting state connectivity maps. It does this by masking the right side of the IFG-L connectivity map, the left side of the IGL-R connectivity map and then adding the resulting images together. It then repeates this process for the pSTG seeds as well. Once it has a single image for IFG and a single image for pSTG, it adds these images together and computes an LI from the resulting image.

### Usage: Examples

To run the LI_Extra code, open the `example_LI_script.m` file which can be found in the `LI_extra` folder. To run the code you need to fill out the BIDS directory and the subject numbers you want to compute the LIs for.

For instance, you can run the code for subjects 1 and 8 as follows:

```
% Inputs
bids_dir = 'C:\Documents\BIDS';
sub_nos = [1 8];

% Run combined LI computation
compute_combined_LIs(bids_dir, sub_nos);
```

where you must change the `bids_dir` to the correct directory on your machine. 

 > **Note:** You must have already run the preprocessing pipeline on the subjects for this code to work. If the files `BIDS/sub-???/conn_rs_IFG_L.nii`, `BIDS/sub-???/conn_rs_IFG_R.nii` , `BIDS/sub-???/conn_rs_pSTG_L.nii`  and `BIDS/sub-???/conn_rs_pSTG_R.nii`  do not already exist the code will error.

You can also run for just a single subject, say subject 1, like so:

```
% Inputs
bids_dir = 'C:\Documents\BIDS';
sub_nos = 1;

% Run combined LI computation
compute_combined_LIs(bids_dir, sub_nos);
```

 > **Note:** You may find that when you first run this code you get an error which says something to the effect of `a path is missing`. If so, within the error message there will be a hyperlink that says something along the lines of `add to path`. If this happens, click the `add to path` option and try running again.


### Outputs

For every subject, this code will output a file named `BIDS/sub-???/conn_rs_combined.nii`. This is the image the lateralisation index was computed from (e.g. the sum of the masked IFG and pSTG images). 

The final LIs will be saved to a file named `BIDS/LI_results_rs_combined.csv`. If the file does not exist, the code will create it. If the file does exist, it will add new results to the existing file. Please note that this means, as before, that you may get repeat entries if you run the code multiple times.


*Page Author: Tom Maullin. Last Updated 30/04/26.*
