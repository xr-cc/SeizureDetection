% LORO-CV try
clear;
clc;
patientID = '01';

%% read feature and label
filePath = ['../../../Feature/chb',patientID,'feature'];
featureFileName = ['SNchb',char(patientID),'features.mat'];
featureFile = load([filePath,'/',featureFileName]);
featureFName = fieldnames(featureFile);
features = featureFile.(featureFName{1});
labelFileName = ['SNchb',char(patientID),'labels.mat'];
labelFile = load([filePath,'/',labelFileName]);
labelFName = fieldnames(labelFile);
labels = labelFile.(labelFName{1});
% label: 1*T
% feature: M*chN*W*T

%% reshape feature to 1-D
feature_size = size(features);
feature_length = feature_size(1)*feature_size(2)*feature_size(3);
feature_num = feature_size(4);
features_shaped = reshape(features,[feature_length,feature_num]); % (W*M*chN)*T

%% normalize and permute data
normalized = features_shaped/max(abs(features_shaped(:)));
features_input = features_shaped'; % T*(W*M*chN)
labels_input = labels'; % T*1

%% unbalanced data
k1 = find(labels_input);
k0 = find(~labels_input);
num_isSeizure = length(k1)
num_notSeizure = length(k0)
features_seizure = features_input(k1,:);
features_nonseizure = features_input(k0,:);
labels_seizure = labels_input(k1,:);
labels_nonseizure = labels_input(k0,:);
% ramdom_pick = datasample(k0,num_isSeizure*5);
% features_use = features_input([k1' ramdom_pick'],:);
% labels_use = labels([k1' ramdom_pick'],:);

% leave one seizure data out
correct_seizure = 0;
for i = 1:num_isSeizure
    % seizure data left out
    left_label = labels_seizure(i)
    left_feature = features_seizure(i);
    % others
    temp_features = features_seizure;
    temp_features(i,:) = [];
    temp_labels = labels_seizure;
    temp_labels(i) = [];
    features_train = [temp_features;features_nonseizure];
    labels_train = [temp_labels;labels_nonseizure];
    model = svmtrain(labels_train, features_train,'-b 0 -t 2 -w1 1 -w0 0.03');
    [label_predicted, accuracy, decision_values] = svmpredict(left_label, left_feature, model);
    label_predicted
    correct_seizure = correct_seizure+(label_predicted==left_label);
end
acc = correct_seizure/num_isSeizure;

