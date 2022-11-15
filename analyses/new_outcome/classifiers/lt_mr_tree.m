function trainedClassifier = lt_mr_tree(trainingData,method,features)
% [trainedClassifier, validationAccuracy] = trainClassifier(trainingData)
% Returns a trained classifier and its accuracy. This code recreates the
% classification model trained in Classification Learner app. Use the
% generated code to automate training the same model with new data, or to
% learn how to programmatically train models.
%
%  Input:
%      trainingData: A table containing the same predictor and response
%       columns as those imported into the app.
%
%  Output:
%      trainedClassifier: A struct containing the trained classifier. The
%       struct contains various fields with information about the trained
%       classifier.
%
%      trainedClassifier.predictFcn: A function to make predictions on new
%       data.
%
%      validationAccuracy: A double containing the accuracy as a
%       percentage. In the app, the Models pane displays this overall
%       accuracy score for each model.
%
% Use the code to train the model with new data. To retrain your
% classifier, call the function from the command line with your original
% data or new data as the input argument trainingData.
%
% For example, to retrain a classifier trained with the original data set
% T, enter:
%   [trainedClassifier, validationAccuracy] = trainClassifier(T)
%
% To make predictions with the returned 'trainedClassifier' on new data T2,
% use
%   yfit = trainedClassifier.predictFcn(T2)
%
% T2 must be a table containing at least the same predictor columns as used
% during training. For details, enter:
%   trainedClassifier.HowToPredict

% Auto-generated by MATLAB on 11-Nov-2022 09:53:23


% Extract predictors and response
% This code processes the data into the right shape for training the
% model.
inputTable = trainingData;
%predictorNames = {'spikes_1_car'};
%predictorNames = {'spikes_1_car', 'bp_1_car', 'bp_2_car', 'bp_3_car', 'bp_4_car', 'bp_5_car', 'fc_1_car', 'coh_1_car', 'coh_2_car', 'coh_3_car', 'coh_4_car', 'coh_5_car', 'coh_6_car'};
%predictorNames = {'bp_1_bipolar', 'bp_2_bipolar', 'bp_3_bipolar', 'bp_4_bipolar', 'bp_5_bipolar', 'fc_1_bipolar', 'coh_1_bipolar', 'coh_2_bipolar', 'coh_3_bipolar', 'coh_4_bipolar', 'coh_5_bipolar', 'coh_6_bipolar', 'spikes_1_car', 'rl_1_car', 'bp_1_car', 'bp_2_car', 'bp_3_car', 'bp_4_car', 'bp_5_car', 'fc_1_car', 'coh_1_car', 'coh_2_car', 'coh_3_car', 'coh_4_car', 'coh_5_car', 'coh_6_car'};
predictorNames = features;


predictors = inputTable(:, predictorNames);
includedPredictorNames = predictorNames;
response = inputTable.soz_lats;
isCategoricalPredictor = repmat(false,1,length(predictorNames));


% Apply a PCA to the predictor matrix.
% Run PCA on numeric predictors only. Categorical predictors are passed through PCA untouched.
isCategoricalPredictorBeforePCA = isCategoricalPredictor;
numericPredictors = predictors(:, ~isCategoricalPredictor);
numericPredictors = table2array(varfun(@double, numericPredictors));
% 'inf' values have to be treated as missing data for PCA.
numericPredictors(isinf(numericPredictors)) = NaN;
[pcaCoefficients, pcaScores, ~, ~, explained, pcaCenters] = pca(...
    numericPredictors);
% Keep enough components to explain the desired amount of variance.
explainedVarianceToKeepAsFraction = 70/100;
numComponentsToKeep = find(cumsum(explained)/sum(explained) >= explainedVarianceToKeepAsFraction, 1);
pcaCoefficients = pcaCoefficients(:,1:numComponentsToKeep);
predictors = [array2table(pcaScores(:,1:numComponentsToKeep)), predictors(:, isCategoricalPredictor)];

% Train a classifier
% This code specifies all the classifier options and trains the classifier.
switch method
    case 'tree'
        classifier = fitctree(...
            predictors, ...
            response, ...
            'SplitCriterion', 'gdi', ...
            'MaxNumSplits', 100, ...
            'Surrogate', 'off', ...
            'ClassNames', {'bilateral'; 'left'; 'right'});
    case 'knn'
        classifier = fitcknn(...
            predictors, ...
            response, ...
            'Distance', 'Euclidean', ...
            'Exponent', [], ...
            'NumNeighbors', 10, ...
            'DistanceWeight', 'Equal', ...
            'Standardize', true, ...
            'ClassNames', {'bilateral'; 'left'; 'right'});
    case 'bag'
        template = templateTree(...
            'MaxNumSplits', 100, ...
            'NumVariablesToSample', 'all');
        
        classifier = fitcensemble(...
            predictors, ...
            response, ...
            'Method', 'Bag', ...
            'Learners', template, ...
            'ClassNames', {'bilateral'; 'left'; 'right'},...
            'NumLearningCycles',100);
       
end

% Create the result struct with predict function
predictorExtractionFcn = @(t) t(:, predictorNames);
featureSelectionFcn = @(x) x(:,includedPredictorNames);
pcaTransformationFcn = @(x) [ array2table((table2array(varfun(@double, x(:, ~isCategoricalPredictorBeforePCA))) - pcaCenters) * pcaCoefficients), x(:,isCategoricalPredictorBeforePCA) ];
predictFcn = @(x) predict(classifier, x);
trainedClassifier.predictFcn = @(x) predictFcn(pcaTransformationFcn(featureSelectionFcn(predictorExtractionFcn(x))));

% Add additional fields to the result struct
trainedClassifier.RequiredVariables = predictorNames;
trainedClassifier.PCACenters = pcaCenters;
trainedClassifier.PCACoefficients = pcaCoefficients;
trainedClassifier.classifier = classifier;
trainedClassifier.About = 'This struct is a trained model exported from Classification Learner R2022a.';
trainedClassifier.HowToPredict = sprintf('To make predictions on a new table, T, use: \n  yfit = c.predictFcn(T) \nreplacing ''c'' with the name of the variable that is this struct, e.g. ''trainedModel''. \n \nThe table, T, must contain the variables returned by: \n  c.RequiredVariables \nVariable formats (e.g. matrix/vector, datatype) must match the original training data. \nAdditional variables are ignored. \n \nFor more information, see <a href="matlab:helpview(fullfile(docroot, ''stats'', ''stats.map''), ''appclassification_exportmodeltoworkspace'')">How to predict using an exported model</a>.');



