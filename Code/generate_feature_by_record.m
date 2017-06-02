function [seizure_features,seizure_labels, nonseizure_features,nonseizure_labels] ...
    = generate_feature_by_record(patientID,L,W,S,Fs)
% GENERATE_FEATURE_BY_RECORD  Generate features by record and save to file(seg).
% Not in use. This is a function version of "get_patient_feature_separately".
% Usage:    [seizure_features,seizure_labels,nonseizure_features,nonseizure_labels] = generate_feature_by_record(patientID,L,W,S,Fs)
%           [seizure_features,seizure_labels,nonseizure_features,nonseizure_labels]
%           = generate_feature_by_record(patientID)
% Inputs:   patientID           -char array of patient ID
%           L(opt)              -interval length (default:2)
%           W(opt)              -number of intervals (default:3)
%           S(opt)              -seconds into seizure of data taken (default:20)
%           Fs(opt)             -sample rate (default:256)
% Outputs:  seizure_features    -M*chN*W*T seizure feature matrix
%           seizure_labels      -1*T seizure label vector
%           nonseizure_features -M*chN*W*T nonseizure feature matrix
%           nonseizure_labels   -1*T nonseizure label vector
% Note:     used function: get_seg_feature(), time2sec()

%% default value for optinal arguments
if nargin < 5
    Fs = 256; % default sample rate
end
if nargin < 4
    S = 20;   % default seconds into seizure  
end
if nargin < 3
    W = 3;    % default number of intervals  
end
if nargin < 2
    L = 2;    % default interval length   
end

pre_seizure_divider = 2;

%%
seizure_features = {};
nonseizure_features = {};
nonseizure_labels = {};
seizure_labels = {}

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

time_nonseizure = 60*60*24; % 24 hours of non-seizure data
num_seizure = sum(seizureFlags);
num_nonseizure = nseg-num_seizure;
time_per_nonseizure = int8(time_nonseizure/num_nonseizure)

seizure_indices = find(seizureFlags==1);
nonseizure_indices = find(seizureFlags==0);

for segID = segIDs
    % index of specified segment
    idx = find(strcmp(segIDs,segID));
    % load data from file
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
        range = endT-time_per_nonseizure-W*L;
        if range<0
            range = 1;
        end
        T_rand = randi(range);        
        firstT = W*L+T_rand;
        timeMaxnons = firstT+double(time_per_nonseizure)+1;
        [segFeatureOutput,segLabelOutput]=get_seg_feature(eegData,firstT,timeMaxnons,0,L,W,Fs);
        nonseizure_features = [nonseizure_features,segFeatureOutput];
        nonseizure_labels = [nonseizure_labels,segLabelOutput];
     else
         disp('Seizure');
         sInfo = seizureInfos{idx};
         seizureI = fieldnames(sInfo);
         for j = 1:length(seizureI)
            seizurePeriod = sInfo.(seizureI{j});
            seizureStart = seizurePeriod{1};
            seizureEnd = seizurePeriod{2};
            % also take non-seizure data before onset
            before = max(seizureStart-S/pre_seizure_divider-1,W*L);
            endT = seizureStart;
%             timeMax = min(before+time_per_nonseizure,endT);                      
            [pre_segFeatureOutput,pre_segLabelOutput]=get_seg_feature(eegData,before,endT,0,L,W,Fs);
            
            % energy band
            timeMax = min(seizureEnd,seizureStart+S);
            firstT = seizureStart+L; % time idx for first X_T_tilt
            [segFeatureOutput,segLabelOutput]=get_seg_feature(eegData,firstT,timeMax,1,L,W,Fs);
            seizure_features = [seizure_features,cat(4, pre_segFeatureOutput, segFeatureOutput)];
        	seizure_labels = [seizure_labels,[pre_segLabelOutput,segLabelOutput]];
            
%              % after seizure end
%             after = seizureEnd+1;
%             timeMax = min(after+time_per_nonseizure,endT);          
%             [segFeatureOutput,segLabelOutput]=get_seg_feature(eegData,after,timeMax,0,L,W,Fs);
%             nonseizure_features = [nonseizure_features,segFeatureOutput]
%         	labels = [labels,segLabelOutput];
         end
        
     end
    

end
savePath = ['../Feature/chb',patientID,'segfeature'];
if ~exist(savePath, 'dir')
  mkdir(savePath);
end
featureFileName = ['SNchb',char(patientID),'seizure_features.mat'];
save([savePath,'/',featureFileName],'seizure_features');
featureFileName = ['SNchb',char(patientID),'nonseizure_features.mat'];
save([savePath,'/',featureFileName],'nonseizure_features');
labelFileName = ['SNchb',char(patientID),'seizure_labels.mat'];
save([savePath,'/',labelFileName],'seizure_labels');
labelFileName = ['SNchb',char(patientID),'nonseizure_labels.mat'];
save([savePath,'/',labelFileName],'nonseizure_labels');



