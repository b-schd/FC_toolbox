function out = classifier_wrapper(T,features,pca_perc,combine_br,just_spikes,rm_non_temporal,response)

% Define response
if isempty(response)
    response = 'soz_lats';
end

% Restrict to spike features if desired
spike_features = features(cellfun(@(x) contains(x,'spikes'),features));
if just_spikes == 1 || just_spikes == 2
    features = spike_features;
end

% Remove patients without response
empty_class = cellfun(@isempty,T.(response));
assert(sum(empty_class)==0)
npts = size(T,1);

% Remove non temporal patients if desired
if rm_non_temporal == 1
    temporal = strcmp(T.soz_locs,'temporal');
    T(~temporal,:) = [];
    npts = size(T,1);
elseif rm_non_temporal == 2 % only include non-temporal (excludes diffuse and multifocal)
    extra = strcmp(T.soz_locs,'other cortex') | strcmp(T.soz_locs,'frontal');
    T(~extra,:) = [];
    npts = size(T,1);
end

% Combine right and bilateral or left and bilateral
if combine_br == 1
    T.soz_lats(strcmp(T.soz_lats,'right') | strcmp(T.soz_lats,'bilateral')) = {'br'};
elseif combine_br == 2
    T.soz_lats(strcmp(T.soz_lats,'left') | strcmp(T.soz_lats,'bilateral')) = {'bl'};
elseif combine_br == 3
    T.soz_lats(strcmp(T.soz_lats,'left') | strcmp(T.soz_lats,'right')) = {'lr'};
end

% if doing outcome model, take absolute value
if strcmp(response,'outcome')
    a = table2array(T(:,features));
    b = abs(a);
    T(:,features) = array2table(b);
end


% Initialize ROC parameters
classes = unique(T.(response));
all_scores = nan(npts,1);
nclasses = length(classes);
C = zeros(nclasses,nclasses); % left, right, bilateral
all_pred = cell(npts,1);
all_names = cell(npts,1);
nbest = 20; % see 20 best features;
all_best_features = cell(npts,nbest);

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

    
    

    % Dumb spikes - binarize spikes according to which side has more
    
    if just_spikes == 2
        binTtrain = Ttrain;
        binTtest = Ttest;
        for j = 1:size(Ttrain,2)
            if ~isnumeric(Ttrain{:,j}), continue; end
            binTtrain{Ttrain{:,j}>0,j} = 1; binTtrain{Ttrain{:,j}<0,j} = 0;
            binTtest{Ttest{:,j}>0,j} = 1; binTtest{Ttest{:,j}<0,j} = 0;
            binTtrain{:,j} = logical(binTtrain{:,j});
            binTtest{:,j} = logical(binTtest{:,j});
        end
        Ttrain = binTtrain;
        Ttest = binTtest;
    end
    

    %% Classifier
    if combine_br == 0 && ~strcmp(response,'outcome')
        % Do the general classifier
        
        tc = general_classifier(Ttrain,'svm',features,response,pca_perc,1e2,length(features));

    else
        % Do the lasso classifier
        tc = lasso_classifier(Ttrain,features,response,pca_perc,classes);
    
        % Get score
        all_scores(i) = tc.probabilityFcn(Ttest);
    end


    all_names{i} = Ttest.names{1};

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

    % find the winningest features
    if combine_br ~= 0
        a = tc.sorted_features(1:min([nbest,length(tc.sorted_features)]));
        if size(a,2) == 1
            a = a';
        end
    
        all_best_features(i,1:min([nbest,length(tc.sorted_features)])) = a;
    end
    

end

if combine_br ~= 0
    % Find the features that show up the most in the winning set
    comb_features = all_best_features(:); % transform to 1d cell array
    empty_comb = cellfun(@isempty,comb_features);
    comb_features(empty_comb) = [];
    [unique_features,ia,ic] = unique(comb_features); % get unique features
    a_counts = accumarray(ic,1); % get counts
    
    % test
    if 0
        [sorted_counts,I] = sort(a_counts,'descend');
        stem(a_counts(I(1:20)))
        xticks(1:20)
        xticklabels(unique_features(I(1:20)))
    end
end


% Prepare output structure
out.scores = all_scores;
out.class = T.(response);
out.pos_class = classes{2};
out.all_pred = all_pred;
out.C = C;
out.unique_classes = classes;
out.npts = npts;
out.names = all_names;

if combine_br ~= 0
    out.unique_features = unique_features;
    out.counts = a_counts;
end

end