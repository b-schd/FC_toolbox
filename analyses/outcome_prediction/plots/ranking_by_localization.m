function ranking_by_localization

%% Parameters
rl_min_spikes = 0;
plot_type = 'scatter';
nblocks = 6;
myColours = [0.1660, 0.540, 0.1880;...
0.4940, 0.1840, 0.5560;...    
0.8500, 0.4250, 0.0980;...
    0.9290 0.6940 0.1250];



locations = fc_toolbox_locs;
script_folder = locations.script_folder;
addpath(genpath(locations.script_folder))
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'analysis/outcome/data/'];

%% Load out file and get roc stuff
out = load([out_folder,'main_out.mat']);
out = out.out;

%% Get stuff
rate = out.all_spikes;
rl = out.all_rl;
soz = out.all_soz_bin;
loc = out.all_soz_locs;
npts = length(soz);

%% Turn soz to logical
soz = cellfun(@logical,soz,'uniformoutput',false);

%% For RL, set as nans those without enough spikes
rl = cellfun(@(x,y) make_non_spikey_nan(x,y,rl_min_spikes), rl, rate,'uniformoutput',false);

%% Separate patients by localization
mf = contains(loc,'multifocal') | contains(loc,'diffuse');
mt = strcmp(loc,'mesial temporal');
tn = strcmp(loc,'temporal neocortical');
oc = strcmp(loc,'other cortex');

figure
set(gcf,'position',[10 10 1100 600])
tiledlayout(2,2,'tilespacing','tight','padding','tight')

%% SOZ spike rate ranking
nexttile
do_plot(rate,soz,mt,'mesial temporal')

nexttile
do_plot(rate,soz,tn,'temporal neocortical')

nexttile
do_plot(rate,soz,oc,'other cortex')

nexttile
do_plot(rate,soz,mf,'multifocal')

figure
set(gcf,'position',[10 10 1100 600])
tiledlayout(2,2,'tilespacing','tight','padding','tight')

end

function do_plot(rate,soz,which_pts,pt_text)

stats_out = plot_orders(rate(which_pts),soz(which_pts));
hold on
xticklabels([])
xlabel('Patient')
ylabel('Electrode spike rate rank')
set(gca,'fontsize',15)
title(sprintf('SOZ spike rate ranking for %s onsets',pt_text))
xl = xlim;
yl=ylim;
text(mean(xl),yl(2),sprintf('median rank = %1.1f',stats_out.median_rank),...
    'horizontalalignment','center','verticalalignment','top','fontsize',15)

end

function x = make_non_spikey_nan(x,y,rl_min_spikes)

x(y<rl_min_spikes) = nan;

end