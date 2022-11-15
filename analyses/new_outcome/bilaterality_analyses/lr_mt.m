function [T,feat_names_s] =  lr_mt

which_outcome = 1; % engel = 1, ilae = 2
which_outcome_year = 2;
which_sleep_stage = 3; % all = 1, wake =2, sleep = 3;


%% Get file locs
locations = fc_toolbox_locs;
results_folder = [locations.main_folder,'results/'];
inter_folder = [results_folder,'analysis/new_outcome/data/'];
plot_folder = [results_folder,'analysis/new_outcome/plots/'];

% add script folder to path
scripts_folder = locations.script_folder;
addpath(genpath(scripts_folder));

%% Load data file
data = load([inter_folder,'main_out.mat']);
data = data.out;

%% get variables of interest
all_outcome = data.outcome; outcome = all_outcome(:,which_outcome,which_outcome_year);
surgery = data.all_surgery;
soz_lats = data.all_soz_lats; 
soz_locs = data.all_soz_locs; 
names = data.all_names;
npts = length(names);
resection_lat = data.all_resec_lat;
ablation_lat = data.all_ablate_lat;
resection_loc = data.all_resec_loc;
ablation_loc = data.all_ablate_loc;

%% Clean SOZ localizations and lateralities
soz_lats(strcmp(soz_lats,'diffuse')) = {'bilateral'}; % make diffuse be the same as bilateral
soz_locs(contains(soz_locs,'temporal')) = {'temporal'};

%% Consensus ablation or resection lat
surg_lat = cell(npts,1);
for i = 1:npts
    if strcmp(resection_lat{i},'na') && strcmp(ablation_lat{i},'na')
    elseif strcmp(resection_lat{i},'na')
        surg_lat{i} = ablation_lat{i};
    elseif strcmp(ablation_lat{i},'na')
        surg_lat{i} = resection_lat{i};
    else
        if ~strcmp(resection_lat{i},ablation_lat{i})
            error('what');
        end
        surg_lat{i} = resection_lat{i};
    end

end

%% Consensus ablation or reseciton loc
surg_loc = cell(npts,1);
for i = 1:npts
    if strcmp(resection_loc{i},'na') && strcmp(ablation_loc{i},'NA')
    elseif strcmp(resection_loc{i},'ATL')
        surg_loc{i} = 'temporal';
    elseif contains(ablation_loc{i},'temporal')
        surg_loc{i} = 'temporal';
    else
        surg_loc{i} = 'other';
    end
end


%% Find good and bad outcome
if which_outcome == 1
    outcome_text = 'engel';
else
    outcome_text = 'ilae';
end
outcome_num = cellfun(@(x) parse_outcome(x,outcome_text),outcome);
outcome = outcome_num;

%% Parse surgery
resection_or_ablation = cellfun(@(x) ...
    contains(x,'resection','ignorecase',true) | contains(x,'ablation','ignorecase',true),...
    surgery);
outcome(~resection_or_ablation) = nan; % make non resection or ablation nan


%% Get features
Ts = table(names,outcome,surgery,surg_lat,surg_loc,soz_locs,soz_lats);
feat_names_s = {};

for which_montage = 1 % car, bipolar
    
    if which_montage == 1
        montage_text = 'car';
    else
        montage_text = 'bipolar';
    end

    coh = data.all_coh(:,which_montage,which_sleep_stage);
    pearson = data.all_pearson(:,which_montage,which_sleep_stage);
    bp = data.all_bp(:,which_montage,which_sleep_stage);
    labels = data.all_labels(:,which_montage);
    rl = data.all_rl(:,1,which_sleep_stage);
    spikes = data.all_spikes(:,1,which_sleep_stage);

    for which_thing = {'spikes','pearson','bp','rl','coh'}
        % Decide thing
        switch which_thing{1}
            case {'pearson','inter_pearson','near_pearson'}
                thing = pearson;
                uni = 0;
                last_dim = 1;
            case {'coh','near_coh','inter_coh'}
                thing = coh;
                uni = 0;
                last_dim = size(coh{1},3);
            case 'bp'
                thing = bp;
                uni = 1;
                last_dim = size(bp{1},2);
            case 'spikes'
                thing = spikes;
                uni = 1;
                last_dim = 1;
                labels = data.all_labels(:,1); % spikes only car
                if which_montage == 2
                    continue
                end
            case 'nelecs'
                thing = cellfun(@(x) ones(length(x),1),spikes,'uniformoutput',false);
                last_dim = 1;
                uni = nan;
            case {'rl','inter_rl'}
                thing = rl;
                uni = 1;
                last_dim = 1;
                labels = data.all_labels(:,1); % spikes only car
                if which_montage == 2
                    continue
                end
        end
    
        %% Get intra
        %[ai,signed] = cellfun(@(x,y) intra_mt_electrode_thing(x,y,uni,last_dim),labels,thing,'uniformoutput',false);
        %ai = cell2mat(ai);
        [ai,match] = cellfun(@(x,y) alt_intra_mt_electrode_thing(x,y,uni,last_dim,which_thing),labels,thing,'uniformoutput',false);
    
        ai = cell2mat(ai);
    
    
        
        %% Signed table
        tnames_s = cell(last_dim,1);
        for i = 1:last_dim
            tnames_s{i} = [which_thing{1},'_',num2str(i),'_',montage_text];
        end
        feat_names_s = [feat_names_s;tnames_s];
    
    
        Ts = addvars(Ts,ai);
        Ts = splitvars(Ts,'ai','newVariableNames',tnames_s);
    end

end

%% Remove redudnant features
if sum(ismember(Ts.Properties.VariableNames,'spikes_1_bipolar'))>0
    Ts = removevars(Ts,'spikes_1_bipolar');
    feat_names_s(strcmp(feat_names_s,'spikes_1_bipolar')) = [];
end
if sum(ismember(Ts.Properties.VariableNames,'rl_1_bipolar'))>0
    Ts = removevars(Ts,'rl_1_bipolar');
    feat_names_s(strcmp(feat_names_s,'rl_1_bipolar')) = [];
end

%% Pairwise correlations of all features
nfeatures = length(feat_names_s); % -2 to remove outcome and bilaterality
all_feat = table2array(Ts(:,size(Ts,2)-nfeatures+1:end));
feat_corr = corr(all_feat,'rows','pairwise','type','spearman');
if 1
    figure
    turn_nans_gray(feat_corr)
    xticks(1:nfeatures)
    xticklabels(feat_names_s)
    yticks(1:nfeatures)
    yticklabels(feat_names_s)
    colorbar
    title('Correlation between L-R asymmetry indices')
    set(gca,'fontsize',15)
    %print(gcf,[plot_folder,'feature_correlation'],'-dpng')
end

%% restrict to temporal locs???
%Ts(~strcmp(Ts.soz_locs,'temporal'),:) = [];

if 1
    figure
    %set(gcf,'position',[15 78 1400 350])
    %tiledlayout(2,7,'tilespacing','tight','Padding','tight')
    for f = 1:length(feat_names_s)
        nexttile
        %{
        unpaired_plot(Ts.(feat_names_s{f})(strcmp(Ts.soz_lats,'bilateral')),...
            Ts.(feat_names_s{f})(strcmp(Ts.soz_lats,'right')),{'left','right'},feat_names_s{f});
        %}
        %
        boxplot(Ts.(feat_names_s{f}),Ts.soz_lats)
        hold on
        ylabel(feat_names_s{f})
        p = kruskalwallis(Ts.(feat_names_s{f}),Ts.soz_lats,'off');
        yl = ylim;
        ybar = yl(1) + 1.05*(yl(2)-yl(1));
        ytext = yl(1) + 1.1*(yl(2)-yl(1));
        new_y = [yl(1) yl(1) + 1.2*(yl(2)-yl(1))];
        plot([1 3],[ybar ybar],'k-','linewidth',2)
        text(2,ytext,sprintf('p = %1.3f',p),'horizontalalignment','center','fontsize',15)
        ylim(new_y)
        %}
        set(gca,'fontsize',15)
    end

end



%% Outcome prediction rule
% I would expect patients who had higher abs AI to have better outcomes,
% assuming surgery done on "correct" side. Perhaps I should take signed AI
% and change the sign to be the opposite if it's the wrong side?


%no_nan  = ~isnan(Ts.fc_1 )& ~isnan(Ts.spikes_1) & ~isnan(Ts.bp_1);
%T = Ts(no_nan,:);
T = Ts(:,[1,7:end]);
T = Ts(~any(ismissing(T),2),:);


end