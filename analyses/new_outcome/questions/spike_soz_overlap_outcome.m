function spike_soz_overlap_outcome

%{
Question: does a higher overlap between the highest spiking electrodes and
the SOZ portend a better outcome?

Different overlap metrics:
1) % of all spikes in the SOZ electrodes (seems easy)

But should I control for % of elecs in SOZ?

I would expect that if most of the spikes are in the SOZ, then this would
portend a good outcome, but if a lot of spikes are outside, then this would
portend a poor outcome. I agree I should control for the proportion of
elecs that are in SOZ, or potentially just the number of elecs in SOZ.

%}

which_outcome = 'ilae';


%% Get file locs
locations = fc_toolbox_locs;
results_folder = [locations.main_folder,'results/'];
inter_folder = [results_folder,'analysis/new_outcome/data/'];
data_folder = [locations.main_folder,'data/'];

% add script folder to path
scripts_folder = locations.script_folder;
addpath(genpath(scripts_folder));

%% Load data file
data = load([inter_folder,'main_out.mat']);
data = data.out;

 %% get variables of interest
ilae = data.all_two_year_ilae;
engel = data.all_two_year_engel;
surgery = data.all_surgery;
good_spikes = data.good_spikes;
spike_rates = data.all_spikes;
soz = data.all_soz_bin;

%% Get outcome
switch which_outcome
    case 'ilae'
        outcome = ilae;
    case 'engel'
        outcome = engel;
end

%% Find good and bad outcome
outcome_num = cellfun(@(x) parse_outcome(x,which_outcome),outcome);

%% Parse surgery
resection_or_ablation = cellfun(@(x) ...
    contains(x,'resection','ignorecase',true) | contains(x,'ablation','ignorecase',true),...
    surgery);

%% Find those with non-empty outcomes
non_empty = cellfun(@(x) ~isempty(x), outcome);

%% Find those with non empty outcomes, resection or ablation, and good spikes
complete = non_empty & resection_or_ablation & good_spikes;

%% Find percentage of spikes in soz
perc_spikes_soz = cellfun(@(X,Y) nansum(X(Y==1))/nansum(X)*100,spike_rates,soz);

if 0
    i = 31;
    table(data.all_labels{i},spike_rates{i},soz{i})
    table((1:length(outcome))',data.all_names,perc_spikes_soz,outcome)
end

%% Normalize
perc_elecs_soz = cellfun(@(X) sum(X==1)/length(X)*100,soz);
num_elecs_soz = cellfun(@(X) sum(X==1),soz);
perc_spikes_norm = perc_spikes_soz./num_elecs_soz;

%% Plot
stats = unpaired_plot(perc_spikes_norm(outcome_num==1 & complete),...
    perc_spikes_norm(outcome_num==0 & complete),{'Good outcome','bad outcome'},'Percent of spikes in SOZ');
set(gca,'fontsize',20)

end