% Same as function get_patient_feature()
patientID = '01'

H = 1;    % default hours of non-seizure data % currently not used
S = 20;   % default seconds into seizure
W = 3;    % default number of intervals
L = 2;    % default interval length 
Fs = 256; % default sample rate
pre_seizure = 10; % time before seizure onset

%%
features = [];
labels = [];

%% load data
filePath = ['../Data/chb',patientID,'mat'];
seizureFlags = [];
segIDs = {};
startTs = {};
endTs = {};
seizureInfos = {};
% summary
summaryFile = [filePath,'/','SNchb',patientID,'summary']
summary = load(summaryFile);
[nseg,ninfo] = size(summary.info);

for i = 1:nseg
    segIDs = [segIDs,summary.info{i,2}];
    startTs = [startTs,summary.info{i,3}];
    endTs = [endTs,summary.info{i,4}];
    seizureFlags = [seizureFlags,summary.info{i,5}];
    seizureInfos = [seizureInfos,summary.info{i,6}];
end

time_nonseizure = H*3600;
num_nonseizure = nseg-sum(seizureFlags);
time_per_nonseizure = int8(time_nonseizure/num_nonseizure);

cut = [];
for segID = segIDs
try
    % index of specified segment
    idx = find(strcmp(segIDs,segID));
    %% load data from file
    segID = char(segID);
    display(segID);    
    fileName = ['SNchb',patientID,'_',segID,'.mat'];
    file = load([filePath,'/',fileName]);
    fName = fieldnames(file);
    channels = (file.(fName{1}){1})';
    eegData = file.(fName{1}){2};

    %% seizure or non-seizure
     if seizureFlags(idx)==0 % non-seizure    
        disp('Non-Seizure');
        baseT = time2sec(startTs{idx});
        startT = 0;
        endT = time2sec(endTs{idx})-baseT;
        if endT<startT % one day more
            endT = endT+time2sec('24:00:00');
        end   
        % random
        range = endT-startT-double(time_per_nonseizure)-W*L;
        if range<0
            range = 1;
        end
        T_rand = double(randi(range));
        firstT = W*L+T_rand;
        timeMax = min(firstT+double(time_per_nonseizure),endT);
        if timeMax<0
            timeMax = firstT+double(time_per_nonseizure);
        end
        [segFeatureOutput,segLabelOutput]=get_seg_feature(eegData,firstT,timeMax,0,L,W,Fs);
        features = cat(4, features, segFeatureOutput);
        labels = [labels,segLabelOutput];

     else % seizure            
         disp('Seizure');
         sInfo = seizureInfos{idx};
         seizureI = fieldnames(sInfo);
         for j = 1:length(seizureI)
            seizurePeriod = sInfo.(seizureI{j});
            seizureStart = seizurePeriod{1};
            seizureEnd = seizurePeriod{2};
            % also take 10s non-seizure data
            % before seizure start
            before = max(seizureStart-pre_seizure-1,W*L);
            endT = seizureStart;
%             timeMax = min(before+time_per_nonseizure,endT);       
            [segFeatureOutput,segLabelOutput]=get_seg_feature(eegData,before,endT,0,L,W,Fs);
            features = cat(4, features, segFeatureOutput);
            labels = [labels,segLabelOutput];
            % energy band
            timeMax = min(seizureEnd,seizureStart+S+L+1);
            firstT = seizureStart+L; % time idx for first X_T_tilt
            [segFeatureOutput,segLabelOutput]=get_seg_feature(eegData,firstT,timeMax,1,L,W,Fs);
            features = cat(4, features, segFeatureOutput);
            labels = [labels,segLabelOutput];                      
         end        
     end

catch ME
    disp([segID,'ERROR'])
end
end
% labels: 1*T
% features: M*chN*W*T

%% save feature and label
savePath = ['../Feature/chb',patientID,'feature'];
if ~exist(savePath, 'dir')
  mkdir(savePath);
end
featureFileName = ['SNchb',char(patientID),'features2.mat'];
save([savePath,'/',featureFileName],'features');
labelFileName = ['SNchb',char(patientID),'labels2.mat'];
save([savePath,'/',labelFileName],'labels');
