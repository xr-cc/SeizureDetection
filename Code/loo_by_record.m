% train & test try
clear;
clc;
patientID = '02';

%% read features and labels
filePath = ['../Feature/chb',patientID,'segfeature'];
featureFileName = ['SNchb',char(patientID),'seizure_features.mat'];
featureFile = load([filePath,'/',featureFileName]);
featureFName = fieldnames(featureFile);
seizure_features = featureFile.(featureFName{1});
featureFileName = ['SNchb',char(patientID),'nonseizure_features.mat'];
featureFile = load([filePath,'/',featureFileName]);
featureFName = fieldnames(featureFile);
nonseizure_features = featureFile.(featureFName{1});
labelFileName = ['SNchb',char(patientID),'seizure_labels.mat'];
labelFile = load([filePath,'/',labelFileName]);
labelFName = fieldnames(labelFile);
seizure_labels = labelFile.(labelFName{1});
labelFileName = ['SNchb',char(patientID),'nonseizure_labels.mat'];
labelFile = load([filePath,'/',labelFileName]);
labelFName = fieldnames(labelFile);
nonseizure_labels = labelFile.(labelFName{1});

test_feature = [];
test_label = 1;
nonseizure_features_reshaped = [];
nonseizure_labels_selected = [];

%% leave one seizure out
num_nonseizures = length(nonseizure_features);
for i = 1:num_nonseizures
    nonseizure = nonseizure_features(i);
    feature_size = size(nonseizure{1});
    feature_length = feature_size(1)*feature_size(2)*feature_size(3);
    data_num = feature_size(4);
    nonseizure_reshaped = reshape(nonseizure{1},[feature_length,data_num]); % (W*M*chN)*t
    nonseizure_reshaped = nonseizure_reshaped(:,1:20);
    
    nonseizure_features_reshaped = [nonseizure_features_reshaped,nonseizure_reshaped]; % (W*M*chN)*T
    nonseizure_labels_selected = [nonseizure_labels_selected,zeros(1,size(nonseizure_reshaped,2))]; % 1*T
end

labels_predicted = {};
labels_truth = {};
accrs = [];
dvs = {};

num_seizures = length(seizure_features);
num_seizures
for i = 1:num_seizures
    disp(i)
    seizure_features_reshaped = [];
    seizure_labels_selected = [];
    for j = 1:num_seizures
        seizure = seizure_features(j);
        label = seizure_labels{j};
        feature_size = size(seizure{1});
        feature_length = feature_size(1)*feature_size(2)*feature_size(3);
        data_num = feature_size(4);
        seizure_reshaped = reshape(seizure{1},[feature_length,data_num]); % (W*M*chN)*T
        if i==j % test data
            test_feature = seizure_reshaped;
            test_label = label;
        else
            seizure_features_reshaped = [seizure_features_reshaped,seizure_reshaped]; 
            seizure_labels_selected = [seizure_labels_selected,label];
        end      
        
    end
    features_reshaped = [seizure_features_reshaped,nonseizure_features_reshaped];
    labels = [seizure_labels_selected,nonseizure_labels_selected];
    
    %% normalize
    normalized = bsxfun (@rdivide, features_reshaped, max(abs(features_reshaped),[],2));  
    features_input = normalized'; % T*(W*M*chN)
    labels_input = labels'; % T*1
    test_feature = test_feature';
    test_label = test_label';
    
%     [r p] = corrcoef(features_input,labels_input);
    
    %randomize
    T = length(labels_input);
    rdm_indices = randperm(T);
    features_train = features_input(rdm_indices,:);
    labels_train = labels_input(rdm_indices);
    
    model = svmtrain(labels_input, features_input,'-b 0 -t 2 -g 0.1 -w1 1 -w0 0.05'); %-g 0.1
    [predicted_label, accuracy, decision_values] = svmpredict(test_label, test_feature, model);
    labels_truth = [labels_truth,test_label];
    labels_predicted = [labels_predicted,predicted_label];
    dvs = [dvs,decision_values];
    accrs = [accrs,accuracy(1)];
end

avg_accr = mean(accrs)
 
