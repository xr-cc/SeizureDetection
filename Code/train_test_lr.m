% train & test try
clear;
clc;
patientID = '05';

%% read feature and label
filePath = ['../Feature/chb',patientID,'feature'];
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
% M = max(A,[],2)
normalized = bsxfun (@rdivide, features_shaped, max(abs(features_shaped),[],2));
% normalized = features_shaped/max(abs(features_shaped(:)));
features_input = normalized'; % T*(W*M*chN)
labels_input = labels'; % T*1

%% unbalanced data
k1 = find(labels_input);
k0 = find(~labels_input);
num_isSeizure = length(k1)
num_notSeizure = length(k0)
ramdom_pick = datasample(k0,num_isSeizure*1);
features_use = features_input([k1' ramdom_pick'],:);
labels_use = labels_input([k1' ramdom_pick'],:);
labels_input = labels_use;

%% split data
train_test_split = 0.8;
T = length(labels_input);
rdm_indices = randperm(T);
% indices = 1:T;
idx_train = rdm_indices(1:train_test_split*T);
idx_test = rdm_indices((train_test_split*T+1):T);
features_train = features_input(idx_train,:);
labels_train = labels_input(idx_train);
features_test = features_input(idx_test,:);
labels_test = labels_input(idx_test);

%% train and test
% model = svmtrain(labels_train, features_train,'-b 0 -t 2 -w1 1 -w0 0.021');
% model = svmtrain(labels_train, features_train,'-b 0 -t 2');
% [B,dev,stats] = mnrfit(labels_train,features_train,'model','hierarchical');

mdl = glmfit(features_train,labels_train,'binomial','link','logit');
labels_predicted = glmval(mdl,features_test,'logit');
labels_predicted = double(int8(labels_predicted));
accuracy = sum(labels_predicted==labels_test)/length(labels_predicted);

% labels_train = labels_train+1;
% [B,dev,stats] = mnrfit(features_train,labels_train);

% [labels_predicted, accuracy, decision_values] = svmpredict(labels_test, features_test, model);
% 

%% seizures
test_seizures_idx = find(labels_test==1);
predicted_seizures_idx = find(labels_predicted==1);
correct_idx = intersect(test_seizures_idx,predicted_seizures_idx);
correct_rate = length(correct_idx)/length(test_seizures_idx);

%% performance measurements
confusion_matrix = confusionmat(labels_test,labels_predicted); % [TP,FN;FP,TN]
TP = confusion_matrix(1,1);
FN = confusion_matrix(1,2);
FP = confusion_matrix(2,1);
TN = confusion_matrix(2,2);
precision = TP/(TP+FP); % precision = TP/(TP+FP)
recall = TP/(TP+FN); % recall = TP/(TP+FN)
% F1score = 2*precision*recall/(precision+recall) = 2*TP/(2*TP+FP+FN)
F1_score =  2*precision*recall/(precision+recall);
