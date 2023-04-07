function make_table_1

%% Get file locs
locations = fc_toolbox_locs;
results_folder = [locations.main_folder,'results/'];
data_folder = [locations.main_folder,'data/'];
plot_folder = [results_folder,'analysis/new_outcome/plots/'];
if ~exist(plot_folder,'dir')
    mkdir(plot_folder)
end

% add script folder to path
scripts_folder = locations.script_folder;
addpath(genpath(scripts_folder));

%% Run the lr_mt to extract features
[T,features] =  lr_mt;
empty_class = cellfun(@isempty,T.soz_lats);
T(empty_class,:) = [];

%% Load the pt file
pt = load([data_folder,'pt.mat']);
pt = pt.pt;

%% Grab demographic variables from table
% Get the patient names
name = T.names;
npts = length(name);

% Get outcomes
engel_yr1 = T.engel_yr1;
engel_yr2 = T.engel_yr2;
ilae_yr1 = T.ilae_yr1;
ilae_yr2 = T.ilae_yr2;

% Get surgery and soz locs and lats
surg = T.surgery;
soz_loc = T.soz_locs;
soz_lat = T.soz_lats;

% ADD IN NUMBER OF SYMMETRIC MT ELECTRODES (need to add to mt_lr)

% ADD IN PERCENT OF TIMES CLASSIFIED AS ASLEEP



%% Get the other demographic variables from the pt.mat
% prep them
female = nan(npts,1);
age_onset = nan(npts,1);
age_implant = nan(npts,1);

%% Maybe get some preimplant data from the manual validation file
% MRI, scalp seizure laterality, scalp spike laterality, PET



end