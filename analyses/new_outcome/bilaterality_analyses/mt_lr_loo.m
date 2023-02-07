function mt_lr_loo(T,features)

% seed rng
rng(0)

%% Establish parameters
method = 'svm';
ncycles = 100; % for bagged ensemble only
response = 'soz_lats';
pca_perc = 90;
which_outcome = 'engel';
which_year = 1;
nfeatures = round(sqrt(length(features)));
rm_non_temporal = 1;
rm_bilateral = 0;
just_spikes = 0;
combine_br = 0;
outcome_soz = 0; % predict outcome using agreement between SOZ lat and surg lat
pred_bad_if_bilat = 0;

spike_features = features(cellfun(@(x) contains(x,'spikes'),features));
if just_spikes
    features = spike_features;
    nfeatures = length(features);
end

if strcmp(response,'outcome')
    % Parse actual outcome
    outcome_name = [which_outcome,'_yr',sprintf('%d',which_year)];
    
    % Remove patients with missing data
    no_outcome = cellfun(@isempty,T.(outcome_name));
    no_surg = ~strcmp(T.surgery,'Laser ablation') & ~strcmp(T.surgery,'Resection');
    
    remove = no_outcome | no_surg;
    T(remove,:) = [];
    
    
    outcome = cellfun(@(x) parse_outcome_new(x,which_outcome),T.(outcome_name),'UniformOutput',false);
    T.outcome = outcome;
end


%% Get file locs
locations = fc_toolbox_locs;
results_folder = [locations.main_folder,'results/'];
plot_folder = [results_folder,'analysis/new_outcome/plots/'];

%% Remove patients without response
empty_class = cellfun(@isempty,T.(response));
T(empty_class,:) = [];
npts = size(T,1);

%% Remove non temporal patients
if rm_non_temporal
    temporal = strcmp(T.soz_locs,'temporal');
    T(~temporal,:) = [];
    npts = size(T,1);
end

%% Combine right and bilateral
if combine_br
    T.soz_lats(strcmp(T.soz_lats,'right') | strcmp(T.soz_lats,'bilateral')) = {'br'};
    npts = size(T,1);
end

%% Remove bilateral
if rm_bilateral
    T(strcmp(T.soz_lats,'bilateral'),:) = [];
    npts = size(T,1);
end

% initialize confusion matrix
classes = unique(T.(response));
nclasses = length(classes);
C = zeros(nclasses,nclasses); % left, right, bilateral
all_pred = cell(npts,1);
all_best_pred = cell(npts,1);

%% Do leave-one-patient-out classifier to predict laterality
for i = 1:npts
    
    % split into training and testing
    Ttrain = T([1:i-1,i+1:end],:); % training all but current
    Ttest = T(i,:); % testing current

    % make sure they're distinct
    assert(isempty(intersect(Ttrain.names,Ttest.names)))

    % perform imputation of missing data
    for j = 1:size(Ttrain,2)
        a = Ttrain{:,j};
        if ~isnumeric(a), continue; end

        a(isnan(a)|abs(a)<1e-10) = nanmedian(a);
        Ttrain{:,j} = a;

        b = Ttest{:,j};
        b(isnan(b)|abs(b)<1e-10) = nanmedian(a); % impute with training data median
        Ttest{:,j} = b;
    end



    % train classifier
    %tc = ensemble_based_fs(Ttrain,features,response);
   % tc = fscmrmr_classifier(Ttrain,method,features,response,pca_perc,ncycles);
    %tc = nca_classifier(Ttrain,method,features,response,pca_perc,ncycles);
    %tc = class_feature_select(Ttrain,method,features,response,ncycles);

    %tc = pca_first_classifier(Ttrain,method,features,response,pca_perc,ncycles,nfeatures);
    tc = general_classifier(Ttrain,method,features,response,pca_perc,ncycles,nfeatures);
    all_best_pred{i} = tc.includedPredictorNames;

    % make prediction on left out
    pred = tc.predictFcn(Ttest);
    all_pred{i} = pred{1};
    
    % compare to true
    true = Ttest.(response);

    % which row to add to confusion matrix (the true value)
    which_row = find(strcmp(true,classes));

    % which column to add to confusion matrix (the predicted value)
    which_column = find(strcmp(pred,classes));

    C(which_row,which_column) = C(which_row,which_column) + 1;

end

%% Find best overall predictors
all_best_pred = horzcat(all_best_pred{:});
% Take the N with the most votes
a=unique(all_best_pred,'stable');
b=cellfun(@(x) sum(ismember(all_best_pred,x)),a,'un',0); % get counts for each
counts = cell2mat(b);

% Make sure counts are sorted
[sorted_counts,I] = sort(counts,'descend');
table(a(I)',sorted_counts')

%% Calculate accuracy and balanced accuracy
accuracy = sum(diag(C))/sum(C(:));

% Balanced accuracy is the average across all classes of the number of 
% data accurately predicted belonging to class m divided by the number of
% data belonging to class m
recall = nan(nclasses,1);
for i = 1:nclasses
    tp = C(i,i);
    fn = sum(C(i,~ismember(1:nclasses,i))); 
    recall(i) = tp/(tp+fn); % tp is number correctly predicted to be in class, tp + fn is everyone in the class
end
balanced_accuracy = mean(recall);

%% Double check accuracy another way
assert(sum(cellfun(@(x,y) strcmp(x,y),all_pred,T.(response)))/length(all_pred)==accuracy)
if 0
    table(T.(response),all_pred)
end

%% Do stats - is this significant???
% Chi2 test
[tbl,chi2,p] = crosstab(T.(response),all_pred);

% Can I do fisher exact? (Think about how to do this with mxn)

% Bootstrapping of expected N
nboot = 1e3;
chi2_boot = nan(nboot,1);
for ib = 1:nboot
    [~,chi2_boot(ib)] = generate_bootstrap_distribution(C);
end
p_boot = (sum(chi2_boot>chi2)+1)/(nboot+1);

if 0
    figure
    plot(sort(chi2_boot),'o')
    hold on
    plot(xlim,[chi2 chi2])
    title(sprintf('bootstrap p = %1.3f, chi2p = %1.3f',p_boot,p))
end

%% Plot
figure
set(gcf,'position',[10 10 600 500])


%% confusion matrix
% Map numbers onto 0 to 1
new_numbers = map_numbers_onto_range(C,[1 0]);
Ccolor = cat(3,ones(nclasses,nclasses,1),repmat(new_numbers,1,1,2));
D = diag(new_numbers);
Dcolor = [repmat(D,1,2),ones(length(D),1)];
Ccolor(logical(repmat(eye(nclasses,nclasses),1,1,3))) = Dcolor;
imagesc(Ccolor)

xticks(1:nclasses)
xticklabels((classes))
yticks(1:nclasses)
yticklabels((classes))
xlabel('Predicted')
ylabel('True')
hold on
for i = 1:nclasses
    for j = 1:nclasses
        text(i,j,sprintf('%d',C(j,i)),'horizontalalignment','center','fontsize',20)
    end
end

title(sprintf('Accuracy: %1.1f%%\nBalanced accuracy: %1.1f%%',...
    accuracy*100,balanced_accuracy*100))
set(gca,'fontsize',20)
print(gcf,[plot_folder,'model'],'-dpng')


%% Save data
T = addvars(T,all_pred,'NewVariableNames','pred_lat','After','surg_lat');
writetable(T,[plot_folder,'model_pred.csv'])


%% Now predict outcome

% Parse actual outcome
outcome_name = [which_outcome,'_yr',sprintf('%d',which_year)];

% Remove patients with missing data
no_outcome = cellfun(@isempty,T.(outcome_name));
no_surg = ~strcmp(T.surgery,'Laser ablation') & ~strcmp(T.surgery,'Resection');
not_temporal = ~strcmp(T.surg_loc,'temporal');

remove = no_outcome | no_surg | not_temporal;
oT = T;
oT(remove,:) = [];


outcome = cellfun(@(x) parse_outcome_new(x,which_outcome),oT.(outcome_name),'UniformOutput',false);

if 0
    table(oT.pred_lat,oT.soz_lats,oT.engel_yr1)
end


% OUTCOME RULE

if outcome_soz % predict good outcome if side of surgery agrees with side of soz
    agree = cellfun(@(x,y) strcmp(x,y),oT.surg_lat,oT.soz_lats);
    disagree = ~agree;
    unilateral_soz = strcmp(oT.soz_lats,'left') | strcmp(oT.soz_lats,'right');
    bilateral_soz = strcmp(oT.soz_lats,'bilateral');

    if pred_bad_if_bilat % also predict bad if bilateral
        pred_good = agree & unilateral_soz;
        pred_bad = disagree | bilateral_soz;
    else
        pred_good = agree;
        pred_bad = disagree;
    end
    assert(isequal(pred_good,~pred_bad))

else
    % Predict good outcome if predicted laterality agrees with side of
    % surgery
    unilateral_pred = strcmp(oT.pred_lat,'left') | strcmp(oT.pred_lat,'right');
    bilateral_pred = strcmp(oT.pred_lat,'bilateral');
    
    agree = cellfun(@(x,y) strcmp(x,y),oT.surg_lat,oT.pred_lat);
    disagree = ~agree;

    if pred_bad_if_bilat % also predict bad if bilateral
        pred_good = unilateral_pred & agree; 
        pred_bad = bilateral_pred | disagree;
    else
        pred_good = agree;
        pred_bad = disagree;
    end
   
    
    assert(isequal(pred_good,~pred_bad))
end

%% Confusion matrix for predicted and true outcome
% Make a confusion matrix for outcome
Cout(1,1) = sum(strcmp(outcome,'good') & pred_good  == 1);
Cout(1,2) = sum(strcmp(outcome,'good') & pred_good == 0);
Cout(2,1) = sum(strcmp(outcome,'bad') & pred_good  == 1);
Cout(2,2) = sum(strcmp(outcome,'bad') & pred_good == 0);
accuracy_out = sum(diag(Cout))/sum(Cout(:));




if 1
    figure
    set(gcf,'position',[10 10 1000 400])
    tiledlayout(1,2)

    %% confusion matrix
    nexttile
    % Map numbers onto 0 to 1
    new_numbers = map_numbers_onto_range(C,[1 0]);
    Ccolor = cat(3,ones(nclasses,nclasses,1),repmat(new_numbers,1,1,2));
    D = diag(new_numbers);
    Dcolor = [repmat(D,1,2),ones(length(D),1)];
    Ccolor(logical(repmat(eye(nclasses,nclasses),1,1,3))) = Dcolor;
    imagesc(Ccolor)
    
    xticks(1:nclasses)
    xticklabels((classes))
    yticks(1:nclasses)
    yticklabels((classes))
    xlabel('Predicted')
    ylabel('True')
    hold on
    for i = 1:nclasses
        for j = 1:nclasses
            text(i,j,sprintf('%d',C(j,i)),'horizontalalignment','center','fontsize',20)
        end
    end
    
    title(sprintf('Accuracy: %1.1f%%\nBalanced accuracy: %1.1f%%',...
        accuracy*100,balanced_accuracy*100))
    set(gca,'fontsize',20)

    %% outcome for those with agreement vs those without
    nexttile
    % Map numbers onto 0 to 1
    new_numbers = map_numbers_onto_range(Cout,[1 0]);
    nclasses = 2;
    classes = {'Good','Poor'};
    Ccolor = cat(3,ones(nclasses,nclasses,1),repmat(new_numbers,1,1,2));
    D = diag(new_numbers);
    Dcolor = [repmat(D,1,2),ones(length(D),1)];
    Ccolor(logical(repmat(eye(nclasses,nclasses),1,1,3))) = Dcolor;
    imagesc(Ccolor)
    
    xticks(1:nclasses)
    xticklabels((classes))
    yticks(1:nclasses)
    yticklabels((classes))
    xlabel('Predicted')
    ylabel('True')
    hold on
    for i = 1:nclasses
        for j = 1:nclasses
            text(i,j,sprintf('%d',Cout(j,i)),'horizontalalignment','center','fontsize',20)
        end
    end
    
    title(sprintf('Accuracy: %1.1f%%',accuracy_out*100))
    set(gca,'fontsize',20)

    %% Null accuracy

end
%}

end