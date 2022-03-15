function show_corrs



%% Get file locs
locations = fc_toolbox_locs;
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'analysis/outcome/plots/'];
data_folder = [results_folder,'analysis/outcome/data/'];
if ~exist(out_folder,'dir')
    mkdir(out_folder)
end

% add script folder to path
scripts_folder = locations.script_folder;
addpath(genpath(scripts_folder));

%% Load the file
out = load([data_folder,'corr_out.mat']);
out = out.out;
avg_corr_sp = out.avg_corr_sp;
avg_corr_pear = out.avg_corr_pear;

%% Initialize figure
figure
set(gcf,'position',[10 10 900 350])
tiledlayout(1,2,'tilespacing','tight','padding','tight')

%% Show pearson
nexttile
ind_corr_plot(avg_corr_pear)
title('Pearson correlation')


%% Show spearman
nexttile
ind_corr_plot(avg_corr_sp)
title('Spearman correlation')


end

function ind_corr_plot(corr_thing)

%% parameters
colors = [0, 0.4470, 0.7410;...
    0.8500, 0.3250, 0.0980];

plot(corr_thing,'o','linewidth',2,'color',colors(1,:))
hold on
plot(xlim,[nanmedian(corr_thing) nanmedian(corr_thing)],'linewidth',2,'color',colors(1,:))
plot(xlim,[0 0],'k--','linewidth',2)
ylim([-1 1])

% one sample ttest
[~,p,~,stats] = ttest(corr_thing);
xl = xlim;
yl = ylim;
text(xl(1),yl(2),sprintf('%s',get_p_text(p)),'verticalalignment','top','fontsize',15)
set(gca,'fontsize',15)
ylabel('Correlation coefficient')
xlabel('Patient')
xticklabels([])

end