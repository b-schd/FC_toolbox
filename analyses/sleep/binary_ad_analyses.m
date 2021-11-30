function out = binary_ad_analyses(disc)


%% Parameters
min_spikes = 0.1;

main_locs = {'mesial temporal','temporal neocortical','other cortex','white matter'};
main_lats = {'Left','Right'};
main_soz = {'SOZ','Not SOZ'};
main{1} = main_locs;
main{2} = main_lats;
main{3} = main_soz;

%% Get file locs
locations = fc_toolbox_locs;
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'analysis/sleep/'];
int_folder = [results_folder,'analysis/intermediate/'];
if ~exist(out_folder,'dir')
    mkdir(out_folder)
end

% add script folder to path
scripts_folder = locations.script_folder;
addpath(genpath(scripts_folder));


%% Listing of available files
listing = dir([int_folder,'*.mat']);
npts = length(listing);

%% Main analyses

r_ad_ana = cell(3,1);
for i = 1:length(r_ad_ana)
    r_ad_ana{i} = nan(length(main{i}),npts,2);
end

rate_strat_ana = cell(3,1);
for i = 1:length(rate_strat_ana)
    rate_strat_ana{i} = nan(length(main{i}),npts,2);
end



rl_strat_ana = cell(3,1);
for i = 1:length(rl_strat_ana)
    rl_strat_ana{i} = nan(length(main{i}),npts,2);
end

r_rl_ana = cell(3,1);
for i = 1:length(r_rl_ana)
    r_rl_ana{i} = nan(length(main{i}),npts,2);
end

rate_overall_ana = cell(3,1);
for i = 1:length(rate_overall_ana)
    rate_overall_ana{i} = nan(length(main{i}),npts);
end

rl_overall_ana = cell(3,1);
for i = 1:length(rl_overall_ana)
    rl_overall_ana{i} = nan(length(main{i}),npts);
end

%% Initialize other stuff
null_ps = nan(npts,1);
ns_sw = nan(npts,2);
all_rates = nan(npts,2);
all_coi = nan(npts,2);
missing_loc = zeros(npts,1);
n_sleep_wake = nan(npts,2);
names = cell(npts,1);
seq_sw = nan(npts,4);
soz_rank_sw = nan(npts,2);
soz_rank_sw_rl = nan(npts,2);
rl_sw_corr = nan(npts,1);
nspikey = nan(npts,2);

%% Loop over patients
for p = 1:npts
    
    fprintf('\nDoing patient %d of %d\n',p,npts);
    
     %% Load
    summ = load([int_folder,listing(p).name]);
    summ = summ.summ;
    
    %% Get main things
    loc = summ.ana_loc;
    lat = summ.ana_lat;
    spikes = summ.spikes;
    ad = summ.ad;
    rl = summ.rl;
    coi_global = summ.coi_global;
    labels = summ.labels;
    ns = summ.ns;
    name = summ.name;
    seq_info = summ.seq_info;
    
    names{p} = name;
    
    % Fix lat thing
    for i = 1:length(lat)
        if isempty(lat{i}), lat{i} = 'unspecified'; end
    end
    
    %% Get features for soz vs not
    soz = summ.soz.chs;
    chnums = 1:length(labels);
    is_soz = ismember(chnums,soz);
    
    %% Find and remove non-intracranial
    %{
    MUST REMEMBER TO ADD THIS FOR COA
    %}
    ekg = find_non_intracranial(labels);
    
    ad = ad(~ekg,:);
    ad = nanmean(ad,1);
    
    loc = loc(~ekg,:);
    lat = lat(~ekg);
    spikes = spikes(~ekg,:); % spike rate #spikes/elec/one minute block (spikes/elec/min)
    rl = rl(~ekg,:);
    
    % dont remove channels from ns because don't know mapping for bipolar
    % montage
    %ns = ns(~ekg,:);
    
    
    is_soz = is_soz(~ekg);
    soz_text = cell(sum(~ekg),1);
    soz_text(is_soz) = {'SOZ'};
    soz_text(~is_soz) = {'Not SOZ'};
       
    %% Determine "wake" and "sleep" times
    % normalized ad
    ad_norm = (ad - nanmedian(ad))./iqr(ad);
    wake = ad_norm > disc;
    sleep = ad_norm <= disc;
       
    n_sleep_wake(p,1) = sum(sleep);
    n_sleep_wake(p,2) = sum(wake);
    
    %% wake vs sleep spike rate
    % overall spike rate (averaged across electrodes)
    mean_spikes = nanmean(spikes,1); % still spikes/elec/min
    all_rates(p,:) = [nanmean(mean_spikes(wake)) nanmean(mean_spikes(sleep))];
    
    %% Wake vs sleep coi
    all_coi(p,:) = [nanmean(coi_global(wake)) nanmean(coi_global(sleep))];
    
    %% Wake vs sleep ns
    mean_ns = nanmean(ns,1); % node strength averaged across electrodes
    ns_sw(p,:) = [nanmean(mean_ns(wake)) nanmean(mean_ns(sleep))];
    
    %% Wake vs sleep seq info
    seq_sw(p,:) = [nanmedian(seq_info(1,wake)) nanmedian(seq_info(1,sleep)),...
        nanmedian(seq_info(2,wake)) nanmedian(seq_info(2,sleep))];

  
    %{
    %% SOZ analysis
    % average over all times, all soz (and separately for all non soz)
    rate_soz(p,:) = [nanmean(spikes(is_soz,:),'all') nanmean(spikes(~is_soz,:),'all')];
    rl_soz(p,:) = [nanmean(rl(is_soz,:),'all') nanmean(rl(~is_soz,:),'all')];
    
    % Now sleep vs wake
    for sz = 1:2
        % first SOZ
        if sz == 1
            rate_sw_soz(sz,p,:) = [nanmean(spikes(is_soz,wake),'all') nanmean(spikes(is_soz,sleep),'all')];
            rl_sw_soz(sz,p,:) = [nanmean(rl(is_soz,wake),'all') nanmean(rl(is_soz,sleep),'all')];
        else
            % not soz
            rate_sw_soz(sz,p,:) = [nanmean(spikes(~is_soz,wake),'all') nanmean(spikes(~is_soz,sleep),'all')];
            rl_sw_soz(sz,p,:) = [nanmean(rl(~is_soz,wake),'all') nanmean(rl(~is_soz,sleep),'all')];
        end
    end
    %}
    %
    
    %% Correlation between sleep and wake RL
    sleep_rl = nanmean(rl(:,sleep),2);
    wake_rl = nanmean(rl(:,wake),2);
    spikey = nanmean(spikes,2) > min_spikes;
    nspikey(p,1) = sum(spikey);
    nspikey(p,2) = length(spikey);
    rl_sw_corr(p) = corr(sleep_rl(spikey),wake_rl(spikey),'type','spearman','rows','pairwise');
    
    %% Rank for soz electrodes in sleep and wake
    spikes_for_rank = spikes;
    spikes_for_rank(isnan(spikes_for_rank)) = 0; % make nan - inf so not to screw up sort
    ranking = nan(size(spikes));
    % Loop over times
    for r = 1:size(spikes,2)
        [~,I] = sort(spikes_for_rank(:,r),'descend');
        curr_rank = 1:size(spikes,1);
        curr_rank(I) = curr_rank;
        ranking(:,r) = curr_rank;
    end
    soz_median_ranking = nanmedian(ranking(is_soz,:),1);
    soz_rank_sw(p,:) = [nanmean(soz_median_ranking(wake)),nanmean(soz_median_ranking(sleep))];
    
    %% Same ranking but RL
    rl_for_rank = rl;
    rl_for_rank(isnan(rl_for_rank)) = inf; % make nan inf so not to screw up sort
    ranking = nan(size(rl_for_rank));
    % Loop over times
    for r = 1:size(rl_for_rank,2)
        [~,I] = sort(rl_for_rank(:,r),'ascend');
        curr_rank = 1:size(rl_for_rank,1);
        curr_rank(I) = curr_rank;
        ranking(:,r) = curr_rank;
    end
    soz_median_ranking = nanmedian(ranking(is_soz,:),1);
    soz_rank_sw_rl(p,:) = [nanmean(soz_median_ranking(wake)),nanmean(soz_median_ranking(sleep))];
 
    %% Get spectral power for each group for locs and lats
    % Loop over loc vs lat
    for g = 1:3
        if g == 1
            group = loc;
            % Skip subsequent loc analyses if missing
            if sum(cellfun(@(x) isempty(x),loc)) == length(loc) 
                missing_loc(p) = 1;
                continue
            end
        elseif g == 2
            group = lat;
        elseif g == 3
            group = soz_text;
        end
        
        % Get the rates corresponding to the subgroups
        % (can probably do this without a for loop)
       
        for sg = 1:length(main{g})
            ic = ismember(group,main{g}(sg));
            
            %
            r_ad_ana{g}(sg,p,:) = [nanmean(spikes(ic,wake),'all') nanmean(spikes(ic,sleep),'all')];
            r_rl_ana{g}(sg,p,:) = [nanmean(rl(ic,wake),'all') nanmean(rl(ic,sleep),'all')];

            % ignoring sleep/wake diff
            rate_overall_ana{g}(sg,p) = nanmean(spikes(ic,:),'all');
            rl_overall_ana{g}(sg,p) = nanmean(rl(ic,:),'all');
            %}
            
            
            % Spike rate for soz vs not
            rate_strat_ana{g}(sg,p,:) = [nanmean(spikes(ic,is_soz),'all') nanmean(spikes(ic,~is_soz),'all')];
            rl_strat_ana{g}(sg,p,:) = [nanmean(rl(ic,is_soz),'all') nanmean(rl(ic,~is_soz),'all')];
            
        end
        

    end
end

%% Remove empty pts for loc analyses
missing_loc = logical(missing_loc);
r_ad_ana{1}(:,missing_loc,:) = [];
rate_overall_ana{1}(:,missing_loc) = [];
npts = npts - sum(missing_loc);


%% Prep out structure
out.rate_overall_ana = rate_overall_ana;
out.main = main;
out.rate_strat_ana = rate_strat_ana;
out.rl_overall_ana = rl_overall_ana;
out.rl_strat_ana = rl_strat_ana;
out.all_rates = all_rates;
out.all_coi = all_coi;
out.ns_sw = ns_sw;
out.r_ad_ana = r_ad_ana;
out.r_rl_ana = r_rl_ana;
out.n_sleep_wake = n_sleep_wake;
out.names = names;
out.seq_sw = seq_sw;
out.soz_rank_sw = soz_rank_sw;
out.soz_rank_sw_rl = soz_rank_sw_rl;
out.rl_sw_corr = rl_sw_corr;
out.nspikey = nspikey;

%% (No sleep) How does spike rate and timing vary across locations
%{
f1 = figure;
set(gcf,'position',[10 271 1260 526])
tiledlayout(2,3)

% spike rate by location
nexttile
curr_rate = rate_overall_ana{1}; % location
plot_paired_data(curr_rate,main_locs,'Spike/elec/min','paired')

% spike rate by soz vs not
nexttile
plot_paired_data(rate_soz',main_soz,'Spike/elec/min','paired')

% Is spike rate higher in SOZ within each anatomical region
nexttile
curr_rate = rate_strat_ana{1};
interaction_plot_and_stats(curr_rate*1e3,main_locs,...
    'Spikes/elec/min',{'SOZ','Not SOZ'},1);

% Spike rl by location
nexttile
curr_rl = rl_overall_ana{1}; % location
plot_paired_data(curr_rl*1e3,main_locs,'Spike latency (ms)','paired')

% spike rl by SOZ
nexttile
plot_paired_data(rl_soz'*1e3,main_soz,'Spike latency (ms)','paired')


% Is rl lower in SOZ within each anatomical region
nexttile
curr_rl = rl_strat_ana{1};
interaction_plot_and_stats(curr_rl*1e3,main_locs,...
    'Spike latency (ms)',{'SOZ','Not SOZ'},1);
print(f1,[out_folder,'no_sleep'],'-dpng')

%% How do spikes vary with sleep
f2 = figure;
set(gcf,'position',[10 10 800 1000])
tiledlayout(3,2,'tilespacing','tight','padding','tight')

% ROC
nexttile
plot(roc(:,1),roc(:,2),'k','linewidth',2)
hold on
plot([0 1],[0 1],'k--')
xlabel('False positive rate')
ylabel('True positive rate')
legend(sprintf('AUC %1.2f',auc),'location','northwest')
set(gca,'fontsize',15)

% Overall spike rate sleep vs wake
nexttile
plot_paired_data(all_rates',{'Wake','Sleep'},'Spike/elec/min','paired')

% COI sleep vs wake
nexttile
plot_paired_data(all_coi',{'Wake','Sleep'},'Spike COI','paired')

% spike rate consistency wake vs sleep
nexttile
plot_paired_data(all_src',{'Wake','Sleep'},'Spike rate consistency','paired')

% spike timing consistency wake vs sleep
nexttile
plot_paired_data(all_stc',{'Wake','Sleep'},'Spike timing consistency','paired')

% average ns wake vs sleep
nexttile
plot_paired_data(ns_sw',{'Wake','Sleep'},'Average node strength','paired')
print(f2,[out_folder,'sleep_fig'],'-dpng')



%% Interaction between sleep and location
f3=figure;
set(gcf,'position',[10 10 600 500])
tiledlayout(2,2,'tilespacing','tight','padding','tight')

% Is sleep-related increase in spike rate higher for SOZ?
nexttile
interaction_plot_and_stats(rate_sw_soz,main_soz,'Spike/elec/min',{'Wake','Sleep'},0);

nexttile
plot_and_stats_change(rate_sw_soz,main_soz,{'Spike rate change','in sleep'},'paired')

% Is sleep-related increase in spike rate higher for different anatomical
% locations?
nexttile
interaction_plot_and_stats(r_ad_ana{1},main_locs,'Spike/elec/min',{'Wake','Sleep'},0);

nexttile
plot_and_stats_change(r_ad_ana{1},main_locs,{'Spike rate change','in sleep'},'paired')
print(f3,[out_folder,'sleep_loc_interaction'],'-dpng')
%}

end