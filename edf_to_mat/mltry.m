patientID = '01';

%% read feature and label
filePath = ['../Feature/chb',patientID,'feature'];

featureFileName = ['SNchb',char(patientID),'feature.mat'];
featureFile = load([filePath,'/',featureFileName]);
featureFName = fieldnames(featureFile);
feature = featureFile.(featureFName{1});
labelFileName = ['SNchb',char(patientID),'label.mat'];
labelFile = load([filePath,'/',labelFileName]);
labelFName = fieldnames(labelFile);
label = labelFile.(labelFName{1});
% label: 1*T
% feature: M*chN*W*T

%% temp
% pick part of data
feature0 = feature(:,:,:,1:10000);
label0 = label(1:10000);

%% normalize data
normalized = feature0/max(abs(feature0(:)));

%% permute feature vector
feature1 = permute(feature0,[4 3 1 2]); % T*W*M*chN


